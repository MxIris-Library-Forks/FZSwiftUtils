//
//  Array+.swift
//
//
//  Created by Florian Zand on 01.11.23.
//

import Foundation

public extension Array {
    /**
     Creates a new array containing the specified number of elements returned by the specifed closure.
     
     Here’s an example of creating an array initialized with five random integers.
     
     ```swift
     let numbers = Array(repeating: { Int.random(in: 0..<10) }, count: 5)
     print(numbers)
     // Prints "[4, 7, 3, 2, 7]"
     ```
     
     - Parameters:
        - repeating: The closure that returns an element.
        - count: The number of times to repeat the closure's value passed in the `repeating` parameter.
     */
    init(repeating: ()->(Element), count: Int) {
        self = count >= 0 ? (0..<count).compactMap({ _ in repeating() }) : []
    }
}

public extension ArraySlice {
     /// The array slice as `Array`.
    var asArray: [Element] {
        Array(self)
    }
}

extension Array {
    @resultBuilder
    public enum Builder {
        public typealias Component = [Element]

        public static func buildExpression(_ expression: Element?) -> Component {
            expression.map({ [$0] }) ?? []
        }

        public static func buildExpression(_ component: Component?) -> Component {
            component ?? []
        }

        public static func buildBlock(_ components: Component...) -> Component {
            components.flatMap { $0 }
        }

        public static func buildOptional(_ component: Component?) -> Component {
            component ?? []
        }

        public static func buildEither(first component: Component) -> Component {
            component
        }

        public static func buildEither(second component: Component) -> Component {
            component
        }

        public static func buildArray(_ components: [Component]) -> Component {
            components.flatMap { $0 }
        }

        public static func buildLimitedAvailability(_ component: Component) -> Component {
            component
        }

        public static func buildFinalResult(_ component: Component) -> [Element] {
            component
        }
    }

    public init(@Builder elements: () -> Self) {
        self = elements()
    }

    public mutating func append(@Builder elements: () -> Self) {
        append(contentsOf: elements())
    }

    public func appending(@Builder elements: () -> Self) -> Self {
        self + elements()
    }
}
