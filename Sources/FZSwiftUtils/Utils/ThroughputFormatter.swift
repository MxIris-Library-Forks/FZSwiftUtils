//
//  ThroughputFormatter.swift
//
//
//  Created by Florian Zand on 18.04.25.
//

import Foundation

/// A formatter that creates string representations of a data throughput (bytes per second).
public class ThroughputFormatter {
    private let formatter = NumberFormatter()

    /// The allowed units to be used for formatting.
    public var units: Units = .all
    
    /// Sets the allowed units to be used for formatting.
    @discardableResult
    public func units( _ units: Units) -> Self {
        self.units = units
        return self
    }
    
    /**
     The unit style.
     
     The default value is `short`.
     */
    public var unitStyle: Formatter.UnitStyle = .short
    
    /**
     Sets the unit style.
     
     The default value is `short`.
     */
    @discardableResult
    func unitStyle(_ style: Formatter.UnitStyle) -> Self {
        unitStyle = style
        return self
    }
    
    /**
     The count style.
     
     The default value is `file`.
     */
    public var countStyle: ByteCountFormatter.CountStyle = .file
    
    /**
     Sets the count style.
     
     The default value is `file`.
     */
    @discardableResult
    func countStyle(_ style: ByteCountFormatter.CountStyle) -> Self {
        countStyle = style
        return self
    }
    
    /// A Boolean value indicating whether to include the units in the resulting formatted string.
    public var includesUnit: Bool = true
    
    /// Sets the Boolean value indicating whether to include the units in the resulting formatted string.
    @discardableResult
    public func includesUnit( _ includes: Bool) -> Self {
        includesUnit = includes
        return self
    }
    
    /// A Boolean value indicating whether to include the count in the resulting formatted string.
    public var includesCount: Bool = true
    
    /// Sets the Boolean value indicating whether to include the count in the resulting formatted string.
    @discardableResult
    public func includesCount( _ includes: Bool) -> Self {
        includesCount = includes
        return self
    }
    
    /// The allowed number of digits after the decimal separator.
    public var fractionLength: NumberFormatter.DigitLength {
        get { formatter.fractionLength }
        set { formatter.fractionLength = newValue }
    }
    
    /// Sets the allowed number of digits after the decimal separator.
    @discardableResult
    public func fractionLength( _ length: NumberFormatter.DigitLength) -> Self {
        fractionLength = length
        return self
    }
    
    /**
     The locale of the formatter.
     
     The default value is `current`.
     */
    public var locale: Locale = .current
    
    /**
     Sets the locale of the formatter.
     
     The default value is `current`.
     */
    @discardableResult
    func locale(_ locale: Locale) -> Self {
        self.locale = locale
        return self
    }
    
    /// Creates a throughput formatter.
    public init(units: Units = .all, fractionLength: NumberFormatter.DigitLength = .max(2)) {
        self.units = units
        self.fractionLength = fractionLength
    }
            
    /// The formatter string for the specified throughput (bytes per second).
    public func string(for dataSizePerSecond: DataSize) -> String {
        string(for: dataSizePerSecond.bytes)
    }
    
    /// The formatted string for the specified throughput (bytes per second).
    public func string<I: BinaryInteger>(for bytesPerSecond: I) -> String {
        if units.isEmpty {
            units = [.bytes]
            let string = string(for: bytesPerSecond)
            units = []
            return string
        }
        let units = units.ordered
        var speed = Double(bytesPerSecond)
        var unitIndex = 0
        while unitIndex < units.count - 1, speed >= 1000 {
            speed /= Double(countStyle.factor)
            unitIndex += 1
        }
        var strings: [String] = []
        if includesCount {
            strings += formatter.string(from: speed)!
        }
        if includesUnit {
            strings += units[unitIndex].localized(to: locale, unitStyle: unitStyle) + "/s"
        }
        return strings.joined(separator: " ")
    }
    
    /// Units for formatting data throughput.
    public struct Units: OptionSet {
        /// Bytes per second (B/s)
        public static let bytes = Units(rawValue: 1 << 0)
        /// Kilobytes per second (KB/s)
        public static let kilobytes = Units(rawValue: 1 << 1)
        /// Megabytes per second (MB/s)
        public static let megabytes = Units(rawValue: 1 << 2)
        /// Gigabytes per second (GB/s)
        public static let gigabytes = Units(rawValue: 1 << 3)
        /// Terabytes per second (TB/s)
        public static let terabytes = Units(rawValue: 1 << 4)
        /// Petabytes per second (PB/s)
        public static let petabytes = Units(rawValue: 1 << 5)
        /// Exabytes per second (EB/s)
        public static let exabytes = Units(rawValue: 1 << 6)
        /// Zettabytes per second (ZB/s)
        public static let zettabytes = Units(rawValue: 1 << 7)
        /// Yottabytes per second (YB/s)
        public static let yottabytes = Units(rawValue: 1 << 8)

        /// All units.
        public static let all: Units = [.bytes, .kilobytes, .megabytes, .gigabytes, .terabytes, .petabytes, .exabytes, .zettabytes, .yottabytes]

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        var ordered: [UnitInformationStorage] {
            var result: [UnitInformationStorage] = []
            if contains(.bytes) { result += .bytes }
            if contains(.kilobytes) { result += .kilobytes }
            if contains(.megabytes) { result += .megabytes }
            if contains(.gigabytes) { result += .gigabytes }
            if contains(.terabytes) { result += .terabytes }
            if contains(.petabytes) { result += .petabytes }
            if contains(.exabytes) { result += .exabytes }
            if contains(.zettabytes) { result += .zettabytes }
            if contains(.yottabytes) { result += .yottabytes }
            return result
        }
    }
}
