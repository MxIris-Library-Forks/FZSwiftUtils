//
//  Hook+Class.swift
//  FZSwiftUtils
//
//  Created by Florian Zand on 11.05.25.
//

#if os(macOS) || os(iOS)
import Foundation

extension Hook {
    class Class: Hook {
        let isInstance: Bool
        weak var hookContext: HookContext?
        
        override var isActive: Bool {
            get { hookContext != nil }
            set { newValue ? try? apply() : try? revert() }
        }
        
        init(_ class_: AnyClass, selector: Selector, mode: HookMode, hookClosure: AnyObject, isInstance: Bool = false) throws {
            try hookSerialQueue.syncSafely {
                try Self.parametersCheck(for: class_, selector: selector, mode: mode, closure: hookClosure)
            }
            self.isInstance = isInstance
            super.init(selector: selector, hookClosure: hookClosure, mode: mode, class_: class_)
        }
        
        override func apply() throws {
            guard !isActive else { return }
            try hookSerialQueue.syncSafely {
                let hookContext = try HookContext.get(for: self.class, selector: selector, isSpecifiedInstance: false)
                try hookContext.append(hookClosure: hookClosure, mode: mode)
                self.hookContext = hookContext
                !isInstance ? _AnyClass(self.class).addHook(self) : _AnyClass(self.class).addInstanceHook(self)
            }
        }
        
        override func revert(remove: Bool) throws {
            guard isActive else { return }
            try hookSerialQueue.syncSafely {
                guard let hookContext = hookContext else { return }
                try hookContext.remove(hookClosure: hookClosure, mode: mode)
                self.hookContext = nil
                if remove {
                    !isInstance ? _AnyClass(self.class).removeHook(self) : _AnyClass(self.class).removeInstanceHook(self)
                }
                guard !(try hookContext.isIMPChanged()) else { return }
                guard hookContext.isHookClosurePoolEmpty else { return }
                hookContext.remove()
            }
        }
    }
}
#endif
