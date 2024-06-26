//
//  JSONEncoderDecoder+.swift
//
//
//  Created by Florian Zand on 02.06.22.
//

import Foundation

extension JSONEncoder.DateEncodingStrategy {
    /**
     Creates a date encoding strategy using the specified date format.

     - Parameter format: The format used to encode the dates.
     */
    public static func formatted(_ format: String) -> JSONEncoder.DateEncodingStrategy {
        .formatted(DateFormatter(format))
    }
}

public extension JSONEncoder {
    /**
     Initializes a JSON encoder with the specified encoding strategies and output formatting options.

     - Parameters:
        - dateEncodingStrategy: The strategy to use for encoding dates.
        - keyEncodingStrategy: The strategy to use for encoding keys.
        - dataEncodingStrategy: The strategy that an encoder uses to encode raw data.
        - outputFormatting: The formatting options to apply to the encoded JSON data.
     */
    convenience init(dateEncodingStrategy: DateEncodingStrategy,
                     keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys,
                     dataEncodingStrategy: DataEncodingStrategy = .base64,
                     outputFormatting: OutputFormatting = []) {
        self.init()
        self.dateEncodingStrategy = dateEncodingStrategy
        self.outputFormatting = outputFormatting
        self.keyEncodingStrategy = keyEncodingStrategy
        self.dataEncodingStrategy = dataEncodingStrategy
    }
}

extension JSONDecoder.DateDecodingStrategy {
    /**
     Creates a date decoding strategy using the specified date format.

     - Parameter format: The format used to decoding the dates.
     */
    public static func formatted(_ format: String) -> JSONDecoder.DateDecodingStrategy {
        .formatted(DateFormatter(format))
    }
}

public extension JSONDecoder {
    /**
     Initializes a JSON decoder with the specified decoding strategies.

     - Parameters:
        - dateDecodingStrategy: The strategy to use for decoding dates.
        - keyDecodingStrategy: The strategy to use for decoding keys.
        - dataDecodingStrategy: The strategy that a decoder uses to decode raw data.
     */
    convenience init(dateDecodingStrategy: DateDecodingStrategy,
                     keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys,
                     dataDecodingStrategy: DataDecodingStrategy = .base64) {
        self.init()
        self.dateDecodingStrategy = dateDecodingStrategy
        self.keyDecodingStrategy = keyDecodingStrategy
        self.dataDecodingStrategy = dataDecodingStrategy
    }
}
