//
//  Collection+Flat.swift
//
//
//  Created by Florian Zand on 04.05.23.
//

import Foundation

public extension Sequence where Element: Collection {
    /// Returns a flattened array of all collection elements.
    func flattened() -> [Element.Element] {
        flatMap { $0 }
    }
}

public extension Sequence where Element: OptionalProtocol {
    /// Returns a flattened array of all collection elements.
    func flattened<V>() -> [V] where Element.Wrapped: Collection<V> {
        compactMap(\.optional).flattened()
    }
}

public extension Sequence where Element: Any {
    /// Returns a flattened array of all elements.
    func anyFlattened() -> [Any] {
        flatMap { x -> [Any] in
            if let anyarray = x as? [Any] {
                return anyarray.map { $0 as Any }.anyFlattened()
            }
            return [x]
        }
    }
}

public extension Sequence where Element: OptionalProtocol, Element.Wrapped: Any {
    /// Returns a flattened array of all elements.
    func anyFlattened() -> [Any] where Element.Wrapped: Any {
        compactMap(\.optional).anyFlattened()
    }
}
