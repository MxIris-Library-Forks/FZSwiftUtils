//
//  Synchronized.swift
//
//  Created by Florian Zand on 01.06.23.
//
//  Adopted from:
//  Copyright ©2016-2018 Peter Baumgartner. All rights reserved.

import Foundation

/**
 Synchronizes an object.
 
 - Parameter lock: The object that is used for locking.
 - Parameter closure: The closure that is executed when the lock is acquired.
 - Returns: The return value of the block is returned to the caller.
 - Throws: Re-throws if the given block throws.
*/
public func synchronized<T>(_ lock: Any, _ closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }

    return try closure()
}

public extension NSObject {
    /**
     Synchronizes the object.
     
     - Parameter closure: The closure that is executed when the lock is acquired.
     - Returns: The return value of the block is returned to the caller.
     - Throws: Re-throws if the given block throws.
    */
    func synchronized<T>(_ closure: () throws -> T) rethrows -> T {
        try FZSwiftUtils.synchronized(self, closure)
    }
}

public extension Array {
    /**
     Synchronizes the array.
     
     - Parameter closure: The closure that is executed when the lock is acquired.
     - Returns: The return value of the block is returned to the caller.
     - Throws: Re-throws if the given block throws.
    */
    func synchronized<T>(_ closure: () throws -> T) rethrows -> T {
        try FZSwiftUtils.synchronized(self, closure)
    }
}

public extension Dictionary {
    /**
     Synchronizes the dictionary.
     
     - Parameter closure: The closure that is executed when the lock is acquired.
     - Returns: The return value of the block is returned to the caller.
     - Throws: Re-throws if the given block throws.
    */
    func synchronized<T>(_ closure: () throws -> T) rethrows -> T {
        try FZSwiftUtils.synchronized(self, closure)
    }
}

public extension Set {
    /**
     Synchronizes the set.
     
     - Parameter closure: The closure that is executed when the lock is acquired.
     - Returns: The return value of the block is returned to the caller.
     - Throws: Re-throws if the given block throws.
    */
    func synchronized<T>(_ closure: () throws -> T) rethrows -> T {
        try FZSwiftUtils.synchronized(self, closure)
    }
}
