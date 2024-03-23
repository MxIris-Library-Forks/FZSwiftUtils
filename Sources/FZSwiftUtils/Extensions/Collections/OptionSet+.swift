//
//  OptionSet+.swift
//
//
//  Created by Florian Zand on 21.10.22.
//

import Foundation

extension BinaryFloatingPoint where Self: LosslessStringConvertible {
    func string(minPlaces: Int? = nil, maxPlaces: Int? = nil) {
        var value = self
        if let max = maxPlaces {
            value = value.rounded(.toPlaces(max))
        }
        var string = String(value)
        if let min = minPlaces {
            let placesCount = value.placesCount
            let diff = min - placesCount
            if diff > 0 {
                if placesCount == 0 {
                    string = string + "."
                }
                (0..<diff).forEach({val in  string = string + "0"})
            }
        }
        
        
    }
}

public extension OptionSet {
    /**
     A Boolean value indicating whether the set contains any of the specified elements.

     - Parameter elements: The elements to look for in the set.
     - Returns: `true` if any of the elements exists in the set, otherwise ` false`.
     */
    func contains(any members: [Self.Element]) -> Bool {
        return members.contains(where: { contains($0) })
    }
}

public extension OptionSet where RawValue: FixedWidthInteger, Element == Self {
    /**
     A Boolean value indicating whether the set contains any of the specified elements.

     - Parameter elements: The elements to look for in the set.
     - Returns: `true` if any of the elements exists in the set, otherwise ` false`.
     */
    func contains(any member: Self.Element) -> Bool {
        for element in member.elements() {
            if contains(element) {
                return true
            }
        }
        return false
    }
    
    /// Returns a sequence of all elements included in the set.
    func elements() -> AnySequence<Self> {
        var remainingBits = rawValue
        var bitMask: RawValue = 1
        return AnySequence {
            AnyIterator {
                while remainingBits != 0 {
                    defer { bitMask = bitMask &* 2 }
                    if remainingBits & bitMask != 0 {
                        remainingBits = remainingBits & ~bitMask
                        return Self(rawValue: bitMask)
                    }
                }
                return nil
            }
        }
    }
}
