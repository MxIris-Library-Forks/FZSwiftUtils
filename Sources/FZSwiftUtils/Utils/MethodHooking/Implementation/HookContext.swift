//
//  HookContext.swift
//
//
//  Created by Yanni Wang on 27/4/20.
//  Copyright © 2020 Yanni. All rights reserved.
//

#if os(macOS) || os(iOS)
import Foundation
import _Libffi
#if SWIFT_PACKAGE
import _OCSources
#endif

class HookContext {
    fileprivate static var pool: [Key: HookContext] = [:]

    fileprivate struct Key: Hashable {
        let classID: ObjectIdentifier
        let selector: Selector
        
        init(_ class_: AnyClass, _ selector: Selector) {
            self.classID = ObjectIdentifier(class_)
            self.selector = selector
        }
    }
    
    // basic
    let targetClass: AnyClass
    let selector: Selector
    let method: Method
    let isSpecifiedInstance: Bool
    let isHookingDealloc: Bool
    
    // hook closure pools
    fileprivate var beforeHookClosures: [ObjectIdentifier: AnyObject] = [:]
    fileprivate var insteadHookClosures: [ObjectIdentifier: AnyObject] = [:]
    fileprivate var afterHookClosures: [ObjectIdentifier: AnyObject] = [:]
    
    // original
    fileprivate let methodCifContext: FFICIFContext
    var methodClosureContext: FFIClosureContext!
    fileprivate let methodOriginalIMP: IMP
    
    // Before & after
    fileprivate let beforeAfterCifContext: FFICIFContext

    // Instead
    fileprivate let insteadCifContext: FFICIFContext
    fileprivate let insteadClosureCifContext: FFICIFContext
    fileprivate var insteadClosureContext: FFIClosureContext!

    init(targetClass: AnyClass, selector: Selector, isSpecifiedInstance: Bool) throws {
        // basic
        self.targetClass = targetClass
        self.selector = selector
        self.isSpecifiedInstance = isSpecifiedInstance

        guard let method = getMethodWithoutSearchingSuperClasses(targetClass: targetClass, selector: selector) else {
            throw HookError.internalError(file: #file, line: #line)
        }
        self.method = method
        self.isHookingDealloc = selector == .dealloc
        
        // original
        let methodSignature = try Signature(method: self.method)
        self.methodOriginalIMP = method_getImplementation(self.method)
        self.methodCifContext = try FFICIFContext.init(signature: methodSignature)
        
        
        
        // Before & after
        self.beforeAfterCifContext = try FFICIFContext.init(signature: Signature(argumentTypes: {
            var types = methodSignature.argumentTypes
            types.insert(.closureTypeValue, at: 0)
            return types
        }(), returnType: .voidTypeValue, signatureType: .closure))
        
        // Instead
        self.insteadCifContext = try FFICIFContext.init(signature: Signature(argumentTypes: {
            var types = methodSignature.argumentTypes
            types.insert(.closureTypeValue, at: 0)
            types.insert(.closureTypeValue, at: 1)
            return types
        }(), returnType: methodSignature.returnType, signatureType: .closure))
        
        self.insteadClosureCifContext = try FFICIFContext.init(signature: Signature(argumentTypes: {
            var types = methodSignature.argumentTypes
            types.insert(.closureTypeValue, at: 0)
            return types
        }(), returnType: methodSignature.returnType, signatureType: .closure))
        
        // Prep closure
        self.methodClosureContext = try FFIClosureContext.init(cif: self.methodCifContext.cif, userData: Unmanaged.passUnretained(self).toOpaque(), fun: methodCalledFunction)
        
        self.insteadClosureContext = try FFIClosureContext.init(cif: self.insteadClosureCifContext.cif, userData: Unmanaged.passUnretained(self).toOpaque(), fun: insteadClosureCalledFunction)
        
        // swizzling
        method_setImplementation(self.method, self.methodClosureContext.targetIMP)
        Self.pool[Key(targetClass, selector)] = self
    }
    
    deinit {
        method_setImplementation(self.method, self.methodOriginalIMP)
    }
    
    func append(hookClosure: AnyObject, mode: HookMode) throws {
        func append(to keyPath: ReferenceWritableKeyPath<HookContext, [ObjectIdentifier: AnyObject]>) throws {
            guard self[keyPath: keyPath].updateValue(hookClosure, forKey: .init(hookClosure)) == nil else {
                throw HookError.duplicateHookClosure
            }
        }
        switch mode {
        case .before:
            try append(to: \.beforeHookClosures)
        case .after:
            try append(to: \.afterHookClosures)
        case .instead:
            try append(to: \.insteadHookClosures)
        }
    }
    
    func remove(hookClosure: AnyObject, mode: HookMode) throws {
        func modify(_ keyPath: ReferenceWritableKeyPath<HookContext, [ObjectIdentifier: AnyObject]>) throws {
            guard self[keyPath: keyPath].removeValue(forKey: .init(hookClosure)) != nil else {
                throw HookError.internalError(file: #file, line: #line)
            }
        }
        switch mode {
        case .before:
            try modify(\.beforeHookClosures)
        case .after:
            try modify(\.afterHookClosures)
        case .instead:
            try modify(\.insteadHookClosures)
        }
    }
    
    var isHookClosurePoolEmpty: Bool {
        beforeHookClosures.isEmpty && insteadHookClosures.isEmpty && afterHookClosures.isEmpty
    }
    
    func isIMPChanged() throws -> Bool {
        guard let currentMethod = getMethodWithoutSearchingSuperClasses(targetClass: targetClass, selector: selector) else {
            throw HookError.internalError(file: #file, line: #line)
        }
        return method != currentMethod ||
            method_getImplementation(currentMethod) != methodClosureContext.targetIMP
    }
    
    func remove() {
        Self.pool[Key(targetClass, selector)] = nil
    }
    
    static func get(for targetClass: AnyClass, selector: Selector, isSpecifiedInstance: Bool) throws -> HookContext {
        try overrideSuperMethodIfNeeded(selector, of: targetClass)
        if let hookContext = Self.pool[Key(targetClass, selector)] {
            return hookContext
        }
        return try HookContext(targetClass: targetClass, selector: selector, isSpecifiedInstance: isSpecifiedInstance)
    }
}

fileprivate func methodCalledFunction(cif: UnsafeMutablePointer<ffi_cif>?, ret: UnsafeMutableRawPointer?, args: UnsafeMutablePointer<UnsafeMutableRawPointer?>?, userdata: UnsafeMutableRawPointer?) {
    
    // Parameters
    guard let userdata = userdata, let cif = cif else {
        assert(false)
        return
    }
    let hookContext = Unmanaged<HookContext>.fromOpaque(userdata).takeUnretainedValue()
    let argsBuffer = UnsafeMutableBufferPointer<UnsafeMutableRawPointer?>(start: args, count: Int(cif.pointee.nargs))
    
    // Get instead hook closures.
    var insteadHookClosures = Array(hookContext.insteadHookClosures.values)
    if hookContext.isSpecifiedInstance {
        let objectPointer = argsBuffer[0]!
        unowned(unsafe) let object = objectPointer.assumingMemoryBound(to: AnyObject.self).pointee
        insteadHookClosures += hookClosures(for: object, selector: hookContext.selector).instead
    }
    
    // instead
    if var hookClosure = insteadHookClosures.last {
        // preparation for instead
        var insteadClosure = createInsteadClosure(targetIMP: hookContext.insteadClosureContext.targetIMP, objectPointer: argsBuffer[0]!, selectorPointer: argsBuffer[1]!, currentHookClosure: hookClosure)
        
        withUnsafeMutablePointer(to: &hookClosure, { hookClosurePointer in
            withUnsafeMutablePointer(to: &insteadClosure, { insteadClosurePointer in
                let nargs = Int(hookContext.insteadCifContext.cif.pointee.nargs)
                let insteadHookArgsBuffer: UnsafeMutableBufferPointer<UnsafeMutableRawPointer?> = UnsafeMutableBufferPointer.allocate(capacity: nargs)
                defer {
                    insteadHookArgsBuffer.deallocate()
                }
                insteadHookArgsBuffer[0] = UnsafeMutableRawPointer(hookClosurePointer)
                insteadHookArgsBuffer[1] = UnsafeMutableRawPointer(insteadClosurePointer)
                if nargs >= 3 {
                    for index in 2 ... nargs - 1 {
                        insteadHookArgsBuffer[index] = argsBuffer[index - 2]
                    }
                }
                ffi_call(hookContext.insteadCifContext.cif, unsafeBitCast(sh_blockInvoke(hookClosurePointer.pointee), to: (@convention(c) () -> Void).self), ret, insteadHookArgsBuffer.baseAddress)
            })
        })
    } else {
        callBeforeHookClosuresAndOriginalMethodAndAfterHookClosures(hookContext: hookContext, ret: ret, argsBuffer: argsBuffer)
    }
}

fileprivate func insteadClosureCalledFunction(cif: UnsafeMutablePointer<ffi_cif>?, ret: UnsafeMutableRawPointer?, args: UnsafeMutablePointer<UnsafeMutableRawPointer?>?, userdata: UnsafeMutableRawPointer?) {
    
    // Parameters
    guard let userdata = userdata, let cif = cif else {
        assert(false)
        return
    }
    let hookContext = Unmanaged<HookContext>.fromOpaque(userdata).takeUnretainedValue()
    let argsBuffer = UnsafeMutableBufferPointer<UnsafeMutableRawPointer?>(start: args, count: Int(cif.pointee.nargs))
    let insteadClosurePointer = argsBuffer[0]!
    unowned(unsafe) let insteadClosure = insteadClosurePointer.assumingMemoryBound(to: AnyObject.self).pointee
    guard let insteadContext = getInsteadContext(insteadClosure: insteadClosure) else {
        assert(false)
        return
    }
    
    // Get instead hook closures.
    var insteadHookClosures = Array(hookContext.insteadHookClosures.values)
    if hookContext.isSpecifiedInstance {
        let objectPointer = hookContext.isHookingDealloc ? insteadContext.objectPointer : argsBuffer[1]!
        unowned(unsafe) let object = objectPointer.assumingMemoryBound(to: AnyObject.self).pointee
        insteadHookClosures += hookClosures(for: object, selector: hookContext.selector).instead
    }
    
    // "insteadHookClosures.first == nil" is for object changing. If user change the object (First parameter). The "insteadHookClosures.first" may be nil.
    if insteadHookClosures.first == nil ||
        insteadContext.currentHookClosure === insteadHookClosures.first {
        // call original method
        let nargs = Int(hookContext.methodCifContext.cif.pointee.nargs)
        let methodArgsBuffer: UnsafeMutableBufferPointer<UnsafeMutableRawPointer?> = UnsafeMutableBufferPointer.allocate(capacity: nargs)
        defer {
            methodArgsBuffer.deallocate()
        }
        if hookContext.isHookingDealloc {
            methodArgsBuffer[0] = insteadContext.objectPointer
            methodArgsBuffer[1] = insteadContext.selectorPointer
        } else {
            for index in 0 ... nargs - 1 {
                methodArgsBuffer[index] = argsBuffer[index + 1]
            }
        }
        callBeforeHookClosuresAndOriginalMethodAndAfterHookClosures(hookContext: hookContext, ret: ret, argsBuffer: methodArgsBuffer)
    } else {
        // call next instead hook closure
        guard let lastIndex = insteadHookClosures.lastIndex(where: {$0 === insteadContext.currentHookClosure}) else {
            assert(false)
            return
        }
        var hookClosure = insteadHookClosures[lastIndex - 1]
        withUnsafeMutablePointer(to: &hookClosure) { hookClosurePointer in
            let nargs = Int(hookContext.insteadCifContext.cif.pointee.nargs)
            let hookArgsBuffer: UnsafeMutableBufferPointer<UnsafeMutableRawPointer?> = UnsafeMutableBufferPointer.allocate(capacity: nargs)
            defer {
                hookArgsBuffer.deallocate()
            }
            hookArgsBuffer[0] = UnsafeMutableRawPointer(hookClosurePointer)
            hookArgsBuffer[1] = insteadClosurePointer
            for index in 2 ... nargs - 1 {
                hookArgsBuffer[index] = argsBuffer[index - 1]
            }
            insteadContext.currentHookClosure = hookClosurePointer.pointee
            ffi_call(hookContext.insteadCifContext.cif, unsafeBitCast(sh_blockInvoke(hookClosurePointer.pointee), to: (@convention(c) () -> Void).self), ret, hookArgsBuffer.baseAddress)
        }
    }
}

fileprivate func callBeforeHookClosuresAndOriginalMethodAndAfterHookClosures(hookContext: HookContext, ret: UnsafeMutableRawPointer?, argsBuffer: UnsafeMutableBufferPointer<UnsafeMutableRawPointer?>) {
    
    // Get before and after hook closures.
    var beforeHookClosures = Array(hookContext.beforeHookClosures.values)
    var afterHookClosures = Array(hookContext.afterHookClosures.values)
    if hookContext.isSpecifiedInstance {
        let objectPointer = argsBuffer[0]!
        unowned(unsafe) let object = objectPointer.assumingMemoryBound(to: AnyObject.self).pointee
        let (before, after, _) = hookClosures(for: object, selector: hookContext.selector)
        beforeHookClosures += before
        afterHookClosures += after
    }
    
    // preparation argsBuffer
    var hookArgsBuffer: UnsafeMutableBufferPointer<UnsafeMutableRawPointer?>?
    defer {
        hookArgsBuffer?.deallocate()
    }
    if !beforeHookClosures.isEmpty || !afterHookClosures.isEmpty {
        let nargs = Int(hookContext.beforeAfterCifContext.cif.pointee.nargs)
        hookArgsBuffer = UnsafeMutableBufferPointer.allocate(capacity: nargs)
        if nargs >= 2 {
            for index in 1 ... nargs - 1 {
                hookArgsBuffer![index] = argsBuffer[index - 1]
            }
        }
    }
    
    // call before closures.
    for hookClosure in beforeHookClosures.reversed() {
        callBeforeOrAfterClosure(hookClosure, hookContext, hookArgsBuffer!)
    }
    
    // call original
    ffi_call(hookContext.methodCifContext.cif, unsafeBitCast(hookContext.methodOriginalIMP, to: (@convention(c) () -> Void).self), ret, argsBuffer.baseAddress)
    
    // call after closures.
    for hookClosure in afterHookClosures.reversed() {
        callBeforeOrAfterClosure(hookClosure, hookContext, hookArgsBuffer!)
    }
}

fileprivate func callBeforeOrAfterClosure(_ hookClosure: AnyObject, _ hookContext: HookContext, _ hookArgsBuffer: UnsafeMutableBufferPointer<UnsafeMutableRawPointer?>) {
    var hookClosure = hookClosure
    withUnsafeMutablePointer(to: &hookClosure) { hookClosurePointer in
        hookArgsBuffer[0] = UnsafeMutableRawPointer(hookClosurePointer)
        ffi_call(hookContext.beforeAfterCifContext.cif, unsafeBitCast(sh_blockInvoke(hookClosurePointer.pointee), to: (@convention(c) () -> Void).self), nil, hookArgsBuffer.baseAddress)
    }
}
#endif
