//
//  NSObject+Swizzle.swift
//
//  Created by Florian Zand on 05.10.23.
//
//  Adopted from:
//  InterposeKit - https://github.com/steipete/InterposeKit/
//  Copyright (c) 2020 Peter Steinberger

import Foundation

extension NSObject {
    /**
     Replace an `@objc dynamic` instance method of the current object.
          
     Example usage that replaces the `mouseDown` method of a view:
     
     ```swift
     let view = NSView()
     do {
        try view.replaceMethod(
        #selector(NSView.mouseDown(with:)),
        methodSignature: (@convention(c)  (AnyObject, Selector, NSEvent) -> ()).self,
        hookSignature: (@convention(block)  (AnyObject, NSEvent) -> ()).self) { store in {
            object, event in
            let view = (object as! NSView)
            // handle replaced `mouseDown`
     
            // calls `super.mouseDown`
            store.original(object, #selector(NSView.mouseDown(with:)), event)
            }
        }
     } catch {
        // handle error
        debugPrint(error)
     }
     ```
          
     To reset the replaced method, use `resetMethod(_:)`.
     
     You can only replace methods of objects that are KVO observed, if you observe them using `observeChanges(for:handler:)` or ``KeyValueObserver``.
     
     - Returns: The token for resetting the replaced method.
     */
    @discardableResult
    public func replaceMethod<MethodSignature, HookSignature> (
        _ selector: Selector,
        methodSignature: MethodSignature.Type = MethodSignature.self,
        hookSignature: HookSignature.Type = HookSignature.self,
        _ implementation: (TypedHook<MethodSignature, HookSignature>) -> HookSignature?) throws -> ReplacedMethodToken {
            if hooks.isEmpty {
                try checkObjectForSwizzling()
            }
            let hook = try Interpose.ObjectHook(object: self, selector: selector, implementation: implementation).apply()
            var _hooks = hooks[selector] ?? []
    
            _hooks.append(hook)
            hooks[selector] = _hooks
            if didDeactivateObservations {
                activateAllObservations()
                didDeactivateObservations = false
            }
            return ReplacedMethodToken(hook)
        }
    
    /// Replace an `@objc dynamic` class method of the current class.
    @discardableResult
    public static func replaceMethod<MethodSignature, HookSignature> (
        _ selector: Selector,
        methodSignature: MethodSignature.Type = MethodSignature.self,
        hookSignature: HookSignature.Type = HookSignature.self,
        _ implementation: (TypedHook<MethodSignature, HookSignature>) -> HookSignature?) throws -> ReplacedMethodToken {
            let hook = try Interpose.ClassHook(class: self as AnyClass, selector: selector, implementation: implementation).apply()
            var _hooks = hooks[selector] ?? []
            _hooks.append(hook)
            hooks[selector] = _hooks
            return ReplacedMethodToken(hook)
        }
    
    func checkObjectPosingAsDifferentClass() -> AnyClass? {
         let perceivedClass: AnyClass = type(of: self)
         let actualClass: AnyClass = object_getClass(self)!
         if actualClass != perceivedClass {
             return actualClass
         }
         return nil
     }
    
    func isKVORuntimeGeneratedClass(_ klass: AnyClass) -> Bool {
        NSStringFromClass(klass).hasPrefix("NSKVO")
    }
    
    var didDeactivateObservations: Bool {
        get { getAssociatedValue("didDeactivateObservations", initialValue: false) }
        set { setAssociatedValue(newValue, key: "didDeactivateObservations") }
    }
    
    func checkObjectForSwizzling() throws {
        if let actualClass = checkObjectPosingAsDifferentClass() {
            if isKVORuntimeGeneratedClass(actualClass) {
                if didDeactivateObservations == false {
                    deactivateAllObservations()
                    didDeactivateObservations = true
                    return try checkObjectForSwizzling()
                }
                activateAllObservations()
                throw SwizzleError.keyValueObservationDetected(self)
            } else {
                throw SwizzleError.objectPosingAsDifferentClass(self, actualClass: actualClass)
            }
        }
    }
    
    /**
     The token for resetting a replaced method.
     
     To reset a replaced method of an object, use the token on the object's `resetMethod(:_)`.
     */
    public struct ReplacedMethodToken {
        /// The selector for the replaced method.
        public let selector: Selector
        /// The id of the token.
        public let id: UUID
        
        init(_ hook: AnyHook) {
            self.selector = hook.selector
            self.id = hook.id
        }
    }
    
    /// Resets an replaced instance method of the object to it's original state.
    public func resetMethod(_ selector: Selector) {
        for hook in hooks[selector] ?? [] {
            do {
                _ = try hook.revert()
            } catch {
                debugPrint(error)
            }
        }
        hooks[selector] = nil
    }
    
    /// Resets an replaced instance method of the object to it's original state.
    public func resetMethod(_ token: ReplacedMethodToken) {
        if var hooks = hooks[token.selector], let index = hooks.firstIndex(where: {$0.id == token.id}) {
            do {
                try hooks[safe: index]?.revert()
                hooks.remove(at: index)
                self.hooks[token.selector] = hooks.isEmpty ? nil : hooks
            } catch {
                debugPrint(error)
            }
        }
    }
    
    /// Resets all replaced instance methods on the current object to their original state.
    public func resetAllMethods() {
        for selector in hooks.keys {
            resetMethod(selector)
        }
    }
    
    /// A Boolean value indicating whether the instance method for the specified selector is replaced.
    public func isMethodReplaced(_ selector: Selector) -> Bool {
        (hooks[selector] ?? []).isEmpty == false
    }
    
    /// Resets an replaced class method of the class to it's original state.
    public static func resetMethod(_ selector: Selector) {
        for hook in hooks[selector] ?? [] {
            do {
                _ = try hook.revert()
            } catch {
                debugPrint(error)
            }
        }
        hooks[selector] = nil
    }
    
    /// Resets an replaced class method of the class to it's original state.
    public static func resetMethod(_ token: ReplacedMethodToken) {
        if var hooks = hooks[token.selector], let index = hooks.firstIndex(where: {$0.id == token.id}) {
            do {
                try hooks[safe: index]?.revert()
                hooks.remove(at: index)
                self.hooks[token.selector] = hooks.isEmpty ? nil : hooks
            } catch {
                debugPrint(error)
            }
        }
    }
    
    /// Resets all replaced class methods of the class to their original state.
    public static func resetAllMethods() {
        for selector in hooks.keys {
            resetMethod(selector)
        }
    }
    
    /// A Boolean value indicating whether the class method for the selector is replaced.
    public static func isMethodReplaced(_ selector: Selector) -> Bool {
        (hooks[selector] ?? []).isEmpty == false
    }
    
    var hooks: [Selector: [AnyHook]] {
        get { getAssociatedValue("_hooks", initialValue: [:]) }
        set { setAssociatedValue(newValue, key: "_hooks") }
    }
    
    static var hooks: [Selector: [AnyHook]] {
        get { getAssociatedValue("_hooks", initialValue: [:]) }
        set { setAssociatedValue(newValue, key: "_hooks") }
    }
    
    /// All replaced instance methods.
    public var replacedMethods: [ReplacedMethodToken] {
        hooks.flatMap({$0.value}).compactMap({ReplacedMethodToken($0)})
    }
    
    /// All replaced class methods.
    public static var replacedMethods: [ReplacedMethodToken] {
        hooks.flatMap({$0.value}).compactMap({ReplacedMethodToken($0)})
    }
    
    /// A Boolean value indicating whether the object is being key value observed.
    public var isKeyValueObserved: Bool {
        if let actualClass = checkObjectPosingAsDifferentClass() {
            return isKVORuntimeGeneratedClass(actualClass)
        }
        return false
    }
}

