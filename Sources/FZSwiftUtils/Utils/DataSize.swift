//
//  DataSize.swift
//
//
//  Created by Florian Zand on 19.01.23.
//

import Foundation

/// A struct representing a data size.
public struct DataSize: Hashable, Sendable {
    
    /// Specifies display of file or storage byte counts.
    public typealias CountStyle = ByteCountFormatter.CountStyle
    
    /**
     Initializes a `DataSize` instance with the given number of bytes and count style.

     - Parameters:
       - bytes: The number of bytes.
       - countStyle: Specify the number of bytes to be used for ``kilobytes``. The default value is `file`.
     */
    public init<Value: BinaryInteger>(_ bytes: Value, countStyle: CountStyle = .file) {
        self.bytes = Int(bytes)
        self.countStyle = countStyle
    }

    /**
     Initializes a `DataSize` instance with the specified sizes in various units and count style.

     - Parameters:
        - bytes: The bytes. The default value is `0`.
        - kilobytes: The kilobytes. The default value is `0`.
        - megabytes: The megabytes. The default value is `0`.
        - gigabytes: The gigabytes. The default value is `0`.
        - terabytes: The terabytes. The default value is `0`.
        - petabytes: The petabytes. The default value is `0`.
        - exabytes: The exabytes. The default value is `0`.
        - zettabytes: The zettabytes. The default value is `0`.
        - yottabytes: The yottabytes. The default value is `0`.
        - countStyle: The number of bytes to be used for ``kilobytes``. The default value is `file`.
     */
    public init(bytes: Int = 0, kilobytes: Double = 0, megabytes: Double = 0, gigabytes: Double = 0, terabytes: Double = 0, petabytes: Double = 0, exabytes: Double = 0, zettabytes: Double = 0, yottabytes: Double = 0, countStyle: CountStyle = .file) {
        self.bytes = bytes
        self.countStyle = countStyle
        self.bytes += self.bytes(for: kilobytes, .kilobyte)
        self.bytes += self.bytes(for: megabytes, .megabyte)
        self.bytes += self.bytes(for: gigabytes, .gigabyte)
        self.bytes += self.bytes(for: terabytes, .terabyte)
        self.bytes += self.bytes(for: petabytes, .petabyte)
        self.bytes += self.bytes(for: exabytes, .exabyte)
        self.bytes += self.bytes(for: zettabytes, .zettabyte)
        self.bytes += self.bytes(for: yottabytes, .yottabyte)
    }

    /**
     Specify the number of bytes to be used for kilobytes.
     
     The default setting is `file`, which is the system specific value for file and storage sizes.
     */
    public var countStyle: CountStyle = .file

    /// The size in bytes.
    public var bytes: Int {
        didSet { bytes = bytes.clamped(min: 0) }
    }

    /// The size in kilobytes.
    public var kilobytes: Double {
        get { value(for: .kilobyte) }
        set { bytes = bytes(for: newValue, .kilobyte) }
    }

    /// The size in megabytes.
    public var megabytes: Double {
        get { value(for: .megabyte) }
        set { bytes = bytes(for: newValue, .megabyte) }
    }

    /// The size in gigabytes.
    public var gigabytes: Double {
        get { value(for: .gigabyte) }
        set { bytes = bytes(for: newValue, .gigabyte) }
    }

    /// The size in terabytes.
    public var terabytes: Double {
        get { value(for: .terabyte) }
        set { bytes = bytes(for: newValue, .terabyte) }
    }

    /// The size in petabytes.
    public var petabytes: Double {
        get { value(for: .petabyte) }
        set { bytes = bytes(for: newValue, .petabyte) }
    }
    
    /// The size in exabytes.
    public var exabytes: Double {
        get { value(for: .exabyte) }
        set { bytes = bytes(for: newValue, .exabyte) }
    }
    
    /// The size in zettabytes.
    public var zettabytes: Double {
        get { value(for: .zettabyte) }
        set { bytes = bytes(for: newValue, .zettabyte) }
    }
    
    /// The size in yottabytes.
    public var yottabytes: Double {
        get { value(for: .yottabyte) }
        set { bytes = bytes(for: newValue, .yottabyte) }
    }

    func value(for unit: Unit) -> Double {
        Unit.byte.convert(Double(bytes), to: unit, countStyle: countStyle)
    }

    func bytes(for value: Double, _ unit: Unit) -> Int {
        Int(unit.convert(value, to: .byte, countStyle: countStyle))
    }

    /// Returns a `DataSize`  with zero bytes.
    public static var zero: DataSize {
        DataSize()
    }
}

public extension DataSize {
    /**
     Returns a data size with the specified bytes.

     - Parameters:
        - value: The bytes.
        - countStyle: The count style for formatting the data size. The default value is `file`.

     - Returns: `DataSize`with the specified bytes.
     */
    static func bytes(_ value: Int, countStyle: CountStyle = .file) -> Self { Self(bytes: value, countStyle: countStyle) }

    /**
     Returns a data size with the specified kilobytes.

     - Parameters:
        - value: The kilobytes.
        - countStyle: The count style for formatting the data size. The default value is `file`.

     - Returns: `DataSize`with the specified kilobytes.
     */
    static func kilobytes(_ value: Double, countStyle: CountStyle = .file) -> Self { Self(kilobytes: value, countStyle: countStyle) }

    /**
     Returns a data size with the specified megabytes.

     - Parameters:
        - value: The megabytes.
        - countStyle: The count style for formatting the data size. The default value is `file`.

     - Returns: `DataSize`with the specified megabytes.
     */
    static func megabytes(_ value: Double, countStyle: CountStyle = .file) -> Self { Self(megabytes: value, countStyle: countStyle) }

    /**
     Returns a data size with the specified gigabytes.

     - Parameters:
        - value: The gigabytes.
        - countStyle: The count style for formatting the data size. The default value is `file`.

     - Returns: `DataSize`with the specified gigabytes.
     */
    static func gigabytes(_ value: Double, countStyle: CountStyle = .file) -> Self { Self(gigabytes: value, countStyle: countStyle) }

    /**
     Returns a data size with the specified terabytes.

     - Parameters:
        - value: The terabytes.
        - countStyle: The count style for formatting the data size. The default value is `file`.

     - Returns: `DataSize`with the specified terabytes.
     */
    static func terabytes(_ value: Double, countStyle: CountStyle = .file) -> Self { Self(terabytes: value, countStyle: countStyle) }

    /**
     Returns a data size with the specified petabytes.

     - Parameters:
        - value: The petabytes.
        - countStyle: The count style for formatting the data size. The default value is `file`.

     - Returns: `DataSize`with the specified petabytes.
     */
    static func petabytes(_ value: Double, countStyle: CountStyle = .file) -> Self { Self(petabytes: value, countStyle: countStyle) }
    
    /**
     Returns a data size with the specified exabytes.

     - Parameters:
        - value: The exabytes.
        - countStyle: The count style for formatting the data size. The default value is `file`.

     - Returns: `DataSize`with the specified exabytes.
     */
    static func exabytes(_ value: Double, countStyle: CountStyle = .file) -> Self { Self(exabytes: value, countStyle: countStyle) }
    
    /**
     Returns a data size with the specified zettabytes.

     - Parameters:
        - value: The zettabytes.
        - countStyle: The count style for formatting the data size. The default value is `file`.

     - Returns: `DataSize`with the specified zettabytes.
     */
    static func zettabytes(_ value: Double, countStyle: CountStyle = .file) -> Self { Self(zettabytes: value, countStyle: countStyle) }
    
    /**
     Returns a data size with the specified yottabytes.

     - Parameters:
        - value: The yottabytes.
        - countStyle: The count style for formatting the data size. The default value is `file`.

     - Returns: `DataSize`with the specified yottabytes.
     */
    static func yottabytes(_ value: Double, countStyle: CountStyle = .file) -> Self { Self(yottabytes: value, countStyle: countStyle) }
}

extension DataSize: Codable {
    public enum CodingKeys: CodingKey {
        case bytes
        case countStyle
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys.self)
        try container.encode(bytes, forKey: .bytes)
        try container.encode(countStyle, forKey: .countStyle)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bytes = try container.decode(Int.self, forKey: .bytes)
        let countStyle = try container.decode(CountStyle.self, forKey: .countStyle)
        self.init(bytes, countStyle: countStyle)
    }
}

extension ByteCountFormatter.CountStyle: Codable { }

extension DataSize: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        bytes = value
        countStyle = .file
    }
}

public extension DataSize {
    ///  Enumeration representing different data size units.
    enum Unit: Int {
        /// Byte
        case byte = 0
        /// Kilobyte
        case kilobyte = 1
        /// Megabyte
        case megabyte = 2
        /// Gigabyte
        case gigabyte = 3
        /// Terabyte
        case terabyte = 4
        /// Petabyte
        case petabyte = 5
        /// Exabyte
        case exabyte = 6
        /// Zettabyte
        case zettabyte = 7
        /// Yottabyte
        case yottabyte = 8

        var byteCountFormatterUnit: ByteCountFormatter.Units {
            switch self {
            case .byte:
                return .useBytes
            case .kilobyte:
                return .useKB
            case .megabyte:
                return .useMB
            case .gigabyte:
                return .useGB
            case .terabyte:
                return .useTB
            case .petabyte:
                return .usePB
            case .exabyte:
                return .useEB
            case .zettabyte:
                return .useZB
            case .yottabyte:
                return .useYBOrHigher
            }
        }

        func convert(_ number: Double, to targetUnit: Unit, countStyle: CountStyle = .file) -> Double {
            let factor: Double = (countStyle == .binary) ? 1024 : 1000
            let conversionFactor = pow(factor, Double(rawValue - targetUnit.rawValue))
            return number * conversionFactor
        }
    }
}

public extension Sequence where Element == DataSize {
    /**
     The total size of all data sizes in the sequence.

     - Returns: A `DataSize` instance representing the total size. If the sequence is empty, it returns `zero`.
     */
    func sum() -> DataSize {
        let bytes = compactMap(\.bytes).sum()
        return DataSize(bytes)
    }
}

public extension Collection where Element == DataSize {
    /**
     The average size of all data sizes in the collection.

     - Returns: A `DataSize` instance representing the average size. If the collection is empty, it returns `zero`.
     */
    func average() -> DataSize {
        guard !isEmpty else { return .zero }
        let average = Int(compactMap(\.bytes).average().rounded(.down))
        return DataSize(average)
    }
}

extension DataSize: CustomStringConvertible {
    /// A string representation of the data size.
    public var description: String {
        string(includesActualByteCount: true)
    }

    /**
     A string representation of the data size that includes the units.
     
     Example usage:

     ```swift
     let dataSize = DataSize(gigabytes: 1, megabytes: 2, bytes: 3)
     dataSize.string // "1 GB"
     ```
     */
    public var string: String {
        string()
    }
        
    /**
     A detailed string representation of the data size that includes the units.
     
     Example usage:

     ```swift
     let dataSize1 = DataSize(gigabytes: 1, megabytes: 15)
     dataSize1.stringDetailed() // "1.015 MB"
     
     let dataSize2 = DataSize(terabytes: 2.5, gigabytes: 1)
     dataSize2.stringDetailed() // "2.501 GB"
     ```
     
     - Parameters:
        - includesUnit: A Boolean value indicating whether to include the unit in the string representation. The default value is `true`.
        - zeroPadsFractionDigits: A Boolean value indicating whether to zero pad fraction digits so a consistent number of characters is displayed in a representation.  The default value is `false`.
        - includesActualByteCount: A Boolean value indicating whether to include the number of bytes after the formatted string. The default value is `false`.

     - Returns: A detailed string representation of the data size.
     */
    public func stringDetailed(includesUnit: Bool = true, zeroPadsFractionDigits: Bool = false) -> String {
        if yottabytes >= 1 {
            return string(for: .zettabyte, includesUnit: includesUnit, zeroPadsFractionDigits: zeroPadsFractionDigits)
        } else if zettabytes >= 1 {
            return string(for: .exabyte, includesUnit: includesUnit, zeroPadsFractionDigits: zeroPadsFractionDigits)
        } else if exabytes >= 1 {
            return string(for: .petabyte, includesUnit: includesUnit, zeroPadsFractionDigits: zeroPadsFractionDigits)
        } else if petabytes >= 1 {
            return string(for: .terabyte, includesUnit: includesUnit, zeroPadsFractionDigits: zeroPadsFractionDigits)
        } else if terabytes >= 1 {
            return string(for: .gigabyte, includesUnit: includesUnit, zeroPadsFractionDigits: zeroPadsFractionDigits)
        } else if gigabytes >= 1 {
            return string(for: .megabyte, includesUnit: includesUnit, zeroPadsFractionDigits: zeroPadsFractionDigits)
        } else if megabytes >= 1 {
            return string(for: .kilobyte, includesUnit: includesUnit, zeroPadsFractionDigits: zeroPadsFractionDigits)
        } else {
            return string(for: .byte, includesUnit: includesUnit, zeroPadsFractionDigits: zeroPadsFractionDigits)
        }
    }

    /**
     Returns a string representation of the data size using the specified unit.
     
     Example usage:

     ```swift
     let dataSize = DataSize(gigabytes: 1, megabytes: 2, bytes: 3)

     dataSize.string(for: .byte, includesUnit: false) // "1.002.000.003"
     dataSize.string(for: .megabyte, includesUnit: true) // "1.002 MB"
     ```
     
     - Parameters:
        - unit: The unit to use for formatting the data size.
        - includesUnit: A Boolean value indicating whether to include the unit in the string representation. The default value is `true`.
        - zeroPadsFractionDigits: A Boolean value indicating whether to zero pad fraction digits so a consistent number of characters is displayed in a representation.  The default value is `false`.
        - includesActualByteCount: A Boolean value indicating whether to include the number of bytes after the formatted string. The default value is `false`.

     - Returns: A string representation of the data size.
     */
    public func string(for unit: Unit, includesUnit: Bool = true, zeroPadsFractionDigits: Bool = false, includesActualByteCount: Bool = false) -> String {
        string(allowedUnits: unit.byteCountFormatterUnit, includesUnit: includesUnit, zeroPadsFractionDigits: zeroPadsFractionDigits, includesActualByteCount: includesActualByteCount)
    }

    /**
     Returns a string representation of the data size using the specified allowed units.
     
     Example usage:
     
     ```swift
     let dataSize = DataSize(gigabytes: 1, megabytes: 2, bytes: 3)

     dataSize.string(allowedUnits: .useAll, includesUnit: true) // "1 GB"
     dataSize.string(allowedUnits: .useMB, includesUnit: false) // "1.002"
     ```

     - Parameters:
        - allowedUnits: The allowed units for formatting the data size. The default value is `useAll`.
        - includesUnit: A Boolean value indicating whether to include the unit in the string representation. The default value is `true`.
        - zeroPadsFractionDigits: A Boolean value indicating whether to zero pad fraction digits so a consistent number of characters is displayed in a representation.  The default value is `false`.
        - includesActualByteCount: A Boolean value indicating whether to include the number of bytes after the formatted string. The default value is `false`.

     - Returns: A string representation of the data size.
     */
    public func string(allowedUnits: ByteCountFormatter.Units = .useAll, includesUnit: Bool = true, zeroPadsFractionDigits: Bool = false, includesActualByteCount: Bool = false) -> String {
        let formatter = ByteCountFormatter(allowedUnits: .useAll, countStyle: countStyle)
        formatter.allowedUnits = allowedUnits
        formatter.includesUnit = includesUnit
        formatter.includesActualByteCount = includesActualByteCount
        formatter.zeroPadsFractionDigits = zeroPadsFractionDigits
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

extension DataSize: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let intValue = Int(description) else { return nil }
        bytes = intValue
        countStyle = .binary
    }
}

extension DataSize: Comparable, AdditiveArithmetic {
    /// Adds the two data sizes.
    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs.bytes + rhs.bytes, countStyle: lhs.countStyle)
    }

    /// Adds two data size and stores the result in the left-hand-side variable.
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    /// Subtracts the two data sizes.
    public static func - (lhs: Self, rhs: Self) -> Self {
        var bytes = lhs.bytes - rhs.bytes
        if bytes < 0 { bytes = 0 }
        return Self(bytes, countStyle: lhs.countStyle)
    }

    /// Subtracts the second data size from the first and stores the difference in the left-hand-side variable.
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    /// A Boolean value indicating whether the first data size is smaller than the second data size.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes < rhs.bytes
    }

    /// A Boolean value indicating whether the first data size is smaller or equal to the second data size.
    public static func <= (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes <= rhs.bytes
    }

    /// A Boolean value indicating whether the first data size is larger than the second data size.
    public static func > (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes > rhs.bytes
    }

    /// A Boolean value indicating whether the first data size is larger or equal to the second data size.
    public static func >= (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes >= rhs.bytes
    }
}

extension Data {
    /// The size of the data.
    public var size: DataSize {
        DataSize(count)
    }
}

extension DataSize: ReferenceConvertible {

    /// The Objective-C type for the data size.
    public typealias ReferenceType = __DataSize

    public var debugDescription: String {
        description
    }

    public func _bridgeToObjectiveC() -> __DataSize {
        return __DataSize(bytes: bytes, countStyle: countStyle)
    }

    public static func _forceBridgeFromObjectiveC(_ source: __DataSize, result: inout DataSize?) {
        result = DataSize(source.bytes, countStyle: source.countStyle)
    }

    public static func _conditionallyBridgeFromObjectiveC(_ source: __DataSize, result: inout DataSize?) -> Bool {
        _forceBridgeFromObjectiveC(source, result: &result)
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: __DataSize?) -> DataSize {
        if let source = source {
            var result: DataSize?
            _forceBridgeFromObjectiveC(source, result: &result)
            return result!
        }
        return .zero
    }
}

/// The Objective-C type for `DataSize`.
public class __DataSize: NSObject, NSCopying {
    
    let bytes: Int
    let countStyle: ByteCountFormatter.CountStyle
    
    init(bytes: Int, countStyle: ByteCountFormatter.CountStyle) {
        self.bytes = bytes
        self.countStyle = countStyle
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        __DataSize(bytes: bytes, countStyle: countStyle)
    }
}
