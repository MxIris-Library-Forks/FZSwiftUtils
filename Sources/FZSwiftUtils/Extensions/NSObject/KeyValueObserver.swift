//
//  KeyValueObserver.swift
//  
//
//  Created by Florian Zand on 01.06.23.
//

import Foundation

/**
 Observes multiple keypaths of an object.
 
 When the instances are deallocated, the KVO is automatically unregistered.
 */
public class KeyValueObserver<Object>: NSObject where Object: NSObject {
    internal var observers: [String:  (_ oldValue: Any, _ newValue: Any)->()] = [:]
    /// The object to register for KVO notifications.
    public fileprivate(set) weak var observedObject: Object?
    
    /**
    Creates a key-value observer with the specifed observed object.
     - Parameters observedObject: The object to register for KVO notifications.
     - Returns: The  key-value observer.
     */
    public init(_ observedObject: Object) {
        self.observedObject = observedObject
        super.init()
    }
    
    /**
     Adds an observer for the specified keypath which calls the specified handler.
     
     - Parameters keyPath: The keypath to the value to observe.
     - Parameters handler: The handler to be called when the keypath values changes.
     */
    public func add<Value: Equatable>(_ keyPath: KeyPath<Object, Value>, handler: @escaping (( _ oldValue: Value, _ newValue: Value)->())) {
        guard let name = keyPath._kvcKeyPathString else { return }
        self.add(name) { old, new in
            guard let old = old as? Value, let new = new as? Value, old != new else { return }
            handler(old, new)
        }
    }
    
    /**
     Adds an observer for the specified keypath which calls the specified handler.
     
     - Parameters keyPath: The keypath to the value to observe.
     - Parameters handler: The handler to be called when the keypath values changes.
     */
    public func add<Value>(_ keyPath: KeyPath<Object, Value>, handler: @escaping (( _ oldValue: Value, _ newValue: Value)->())) {
        guard let name = keyPath._kvcKeyPathString else { return }
        
        self.add(name) { old, new in
            guard let old = old as? Value, let new = new as? Value else { return }
            handler(old, new)
        }
    }
    
    /**
     Adds an observer for the specified keypath which calls the specified handler.
     
     - Parameters keyPath: The keypath to the value to observe.
     - Parameters handler: The handler to be called when the keypath values changes.
     */
    public func add(_ keypath: String, handler: @escaping ( _ oldValue: Any, _ newValue: Any)->()) {
        if (observers[keypath] == nil) {
            observers[keypath] = handler
            observedObject?.addObserver(self, forKeyPath: keypath, options: [.old, .new], context: nil)
        }
    }
    
    /**
     Removes the observer for the specified keypath.
     
     - Parameters keyPath: The keypath to remove.
     */
    public func remove(_ keyPath: PartialKeyPath<Object>) {
        guard let name = keyPath._kvcKeyPathString else { return }
        self.remove(name)
    }
    
    /**
     Removes the observesr for the specified keypaths.
     
     - Parameters keyPaths: The keypaths to remove.
     */
    public func remove<S: Sequence<PartialKeyPath<Object>>>(_ keyPaths: S)  {
        keyPaths.compactMap({$0._kvcKeyPathString}).forEach({ self.remove($0) })
    }
    
    /**
     Removes the observer for the specified keypath.
     
     - Parameters keyPath: The keypath to remove.
     */
    public func remove(_ keyPath: String) {
        guard let observedObject = self.observedObject else { return }
        if self.observers[keyPath] != nil {
            observedObject.removeObserver(self, forKeyPath: keyPath)
            self.observers[keyPath] = nil
        }
    }
    
    /// Removes all observers.
    public func removeAll() {
        self.observers.keys.forEach({ self.remove( $0) })
    }
    
    /// A bool indicating whether any value is observed.
    public func isObserving() -> Bool {
        return  self.observers.isEmpty != false
    }
    
    /**
     A bool indicating whether the value at the specified keypath is observed.
     
     - Parameters keyPath: The keyPath to the value.
     */
    public func isObserving(_ keyPath: PartialKeyPath<Object>) -> Bool {
        guard let name = keyPath._kvcKeyPathString else { return false }
        return self.isObserving(name)
    }
    
    /**
     A bool indicating whether the value at the specified keypath is observed.
     
     - Parameters keyPath: The keyPath to the value.
     */
    public func isObserving(_ keyPath: String) -> Bool {
        return self.observers[keyPath] != nil
    }
    
    override public func observeValue(forKeyPath keyPath:String?, of object:Any?, change:[NSKeyValueChangeKey:Any]?, context:UnsafeMutableRawPointer?) {
        guard
            self.observedObject != nil,
            let keyPath = keyPath,
            let handler = self.observers[keyPath],
            let change = change,
            let oldValue = change[NSKeyValueChangeKey.oldKey],
            let newValue = change[NSKeyValueChangeKey.newKey] else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        handler(oldValue, newValue)
    }
    
    deinit {
        self.removeAll()
    }
}

public extension KeyValueObserver {
    subscript<Value: Equatable>(keyPath: KeyPath<Object, Value>) -> ((_ oldValue: Value, _ newValue: Value)->())? {
        get {
            guard let name = keyPath._kvcKeyPathString else { return nil }
            return self.observers[name] as ((_ oldValue: Value, _ newValue: Value)->())?
        }
        set {
            if let newValue = newValue {
                guard let name = keyPath._kvcKeyPathString else { return }
                if self.observers[name] == nil {
                    self.add(keyPath, handler: newValue)
                } else {
                    self.observers[name] = { old, new in
                        guard let old = old as? Value, let new = new as? Value, old != new else { return }
                        newValue(old, new)
                    }
                }
            } else {
                self.remove(keyPath)
            }
        }
        
    }
    
    subscript<Value>(keyPath: KeyPath<Object, Value>) -> ((_ oldValue: Value, _ newValue: Value)->())? {
        get {
            guard let name = keyPath._kvcKeyPathString else { return nil }
            return self.observers[name] as ((_ oldValue: Value, _ newValue: Value)->())?
        }
        set {
            if let newValue = newValue {
                guard let name = keyPath._kvcKeyPathString else { return }
                if self.observers[name] == nil {
                    self.add(keyPath, handler: newValue)
                } else {
                    self.observers[name] = { old, new in
                        guard let old = old as? Value, let new = new as? Value else { return }
                        newValue(old, new)
                    }
                }
            } else {
                self.remove(keyPath)
            }
        }
    }
    
    subscript(keyPath: String) -> ((_ oldValue: Any, _ newValue: Any)->())? {
        get { self.observers[keyPath] }
        set {
            self.remove(keyPath)
            if let newValue = newValue {
                if self.observers[keyPath] == nil {
                    self.add(keyPath, handler: newValue)
                } else {
                    self.observers[keyPath] = newValue
                }
            } else {
                self.remove(keyPath)
            }
        }
    }
}
