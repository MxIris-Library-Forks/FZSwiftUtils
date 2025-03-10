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
     
     To reset the replaced method, use `resetMethod(_:)` with the selector or set tokens `isActive` to false.
          
     - Returns: The token for resetting the replaced method.
     */
    @discardableResult
    public func replaceMethod<MethodSignature, HookSignature> (
        _ selector: Selector,
        methodSignature: MethodSignature.Type = MethodSignature.self,
        hookSignature: HookSignature.Type = HookSignature.self,
        _ implementation: (TypedHook<MethodSignature, HookSignature>) -> HookSignature?) throws -> ReplacedMethodToken {
            let kvoObservers = kvoObservers
            kvoObservers.forEach({ $0.isActive = false })
            do {
                let hook = try Interpose.ObjectHook(object: self, selector: selector, implementation: implementation).apply()
                hooks[selector, default: []].append(hook)
                 kvoObservers.forEach({ $0.isActive = true })
                return .init(hook, self)
            } catch {
                kvoObservers.forEach({ $0.isActive = true })
                throw error
            }
    }
    
    /**
     Replace an `@objc dynamic` class method of the current class.
     
     To reset the replaced method, use `resetMethod(_:)` with the selector or set tokens `isActive` to false.

     - Returns: The token for resetting the replaced method.
     */
    @discardableResult
    public class func replaceMethod<MethodSignature, HookSignature> (
        _ selector: Selector,
        methodSignature: MethodSignature.Type = MethodSignature.self,
        hookSignature: HookSignature.Type = HookSignature.self,
        _ implementation: (TypedHook<MethodSignature, HookSignature>) -> HookSignature?) throws -> ReplacedMethodToken {
        let hook = try Interpose.ClassHook(class: self as AnyClass,
                                       selector: selector, implementation: implementation).apply()
        hooks[selector, default: []].append(hook)
        return .init(hook, self)
    }
    
    /**
     Adds an unimplemented protocol instance method to the current object.
     
     Use this method to add an unimplemented protocol method to the object. To replace a already implemented method use ``replaceMethod(_:methodSignature:hookSignature:_:)-swift.type.method``.
     
     To remove the added method, use `resetMethod(_:)` with the selector or set tokens `isActive` to false.
          
     - Returns: The token for resetting the adding method.
     */
    @discardableResult
    public func addMethod<MethodSignature> (
        _ selector: Selector,
        methodSignature: MethodSignature.Type = MethodSignature.self,
        _ implementation: MethodSignature) throws -> ReplacedMethodToken {
            let kvoObservers = kvoObservers
            kvoObservers.forEach({ $0.isActive = false })
            do {
                let hook = try Interpose.OptionalObjectHook(object: self, selector: selector, implementation: implementation).apply()
                hooks[selector, default: []].append(hook)
                kvoObservers.forEach({ $0.isActive = true })
                return .init(hook, self)
            } catch {
                kvoObservers.forEach({ $0.isActive = true })
                throw error
            }
        }
    
    /// A Boolean value indicating whether the instance method for the specified selector is replaced.
    public func isMethodReplaced(_ selector: Selector) -> Bool {
        (hooks[selector] ?? []).isEmpty == false
    }
    
    /// Resets an replaced instance method of the object to it's original state.
    public func resetMethod(_ selector: Selector) {
        let kvoObservers = kvoObservers
        kvoObservers.forEach({ $0.isActive = false })
        _resetMethod(selector)
        kvoObservers.forEach({ $0.isActive = true })
    }
    
    func _resetMethod(_ selector: Selector) {
        let all = hooks[selector] ?? []
        for hook in all {
            do {
                _ = try hook.revert()
                hooks[selector, default: []].removeFirst(where: {$0.id == hook.id })
            } catch {
                debugPrint(error)
            }
        }
    }
    
    /// Resets all replaced instance methods on the current object to their original state.
    public func resetAllMethods() {
        let kvoObservers = kvoObservers
        kvoObservers.forEach({ $0.isActive = false })
        for selector in hooks.keys {
            _resetMethod(selector)
        }
        kvoObservers.forEach({ $0.isActive = true })
    }
    
    /// A Boolean value indicating whether the class method for the selector is replaced.
    public static func isMethodReplaced(_ selector: Selector) -> Bool {
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
    
    /// Resets all replaced class methods of the class to their original state.
    public static func resetAllMethods() {
        for selector in hooks.keys {
            resetMethod(selector)
        }
    }
    
    var hooks: [Selector: [AnyHook]] {
        get { getAssociatedValue("_hooks", initialValue: [:]) }
        set { setAssociatedValue(newValue, key: "_hooks") }
    }
    
    static var hooks: [Selector: [AnyHook]] {
        get { getAssociatedValue("_hooks", initialValue: [:]) }
        set { setAssociatedValue(newValue, key: "_hooks") }
    }
    
    var addedMethods: Set<Selector> {
        get { getAssociatedValue("addedMethods") ?? [] }
        set {
            setAssociatedValue(newValue, key: "addedMethods")
            if newValue.count == 1 {
                do {
                   try replaceMethod(
                    #selector(NSObject.responds(to:)),
                   methodSignature: (@convention(c)  (AnyObject, Selector, Selector?) -> (Bool)).self,
                   hookSignature: (@convention(block)  (AnyObject, Selector?) -> (Bool)).self) { store in {
                       object, selector in
                       if let object = object as? NSObject, let selector = selector, object.addedMethods.contains(selector) {
                           return true
                       }
                       return store.original(object, #selector(NSObject.responds(to:)), selector)
                       }
                   }
                } catch {
                   debugPrint(error)
                }
            } else if newValue.isEmpty {
                resetMethod(#selector(NSObject.responds(to:)))
            }
        }
    }
        
    /**
     The token for a replaced method.
     
     To reset or activate a replaced method, use ``isActive``.
     */
    public class ReplacedMethodToken {
        
        /// The selector for the replaced method.
        public let selector: Selector
        
        /// The class for the replaced method.
        public let `class`: AnyClass
                
        /// A Boolean value indicating whether the replaced method is active.
        public var isActive: Bool {
            get { hook?.state == .interposed }
            set {
                guard newValue != isActive, let hook = hook else { return }
                do {
                    if newValue {
                        try hook.apply()
                        object?.hooks[selector, default: []].append(hook)
                        _class?.hooks[selector, default: []].append(hook)
                    } else {
                        try hook.revert()
                        object?.hooks[selector, default: []].removeFirst(where: {$0.id == hook.id })
                        _class?.hooks[selector, default: []].removeFirst(where: {$0.id == hook.id })
                    }
                } catch {
                    debugPrint(error)
                }
            }
        }
        
        weak var hook: AnyHook?
        weak var object: NSObject?
        var _class: NSObject.Type?
        
        init(_ hook: AnyHook, _ object: NSObject) {
            self.selector = hook.selector
            self.hook = hook
            self.object = object
            self.class = hook.class
        }
        
        init(_ hook: AnyHook, _ classType: NSObject.Type) {
            self.selector = hook.selector
            self.hook = hook
            self._class = classType
            self.class = hook.class
        }
    }
}
