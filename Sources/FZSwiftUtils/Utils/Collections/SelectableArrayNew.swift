//
//  ArrayBase.swift
//
//
//  Created by Florian Zand on 15.10.21.
//

import Foundation

public struct SelectableArrayNew<Element>: MutableCollection, RangeReplaceableCollection, RandomAccessCollection, BidirectionalCollection {
    struct SelectableElement {
        let element: Element
        var isSelected: Bool
        init(_ element: Element, isSelected: Bool = false) {
            self.element = element
            self.isSelected = isSelected
        }
    }

    var elements: [SelectableElement] = [] {
        didSet {
            if isSelecting == false {
                updateSelections()
            }
        }
    }

    mutating func updateSelections() {
        if allowsSelection {
            if allowsMultipleSelection == false, let firstIndex = selectedIndexes.first {
                select(at: firstIndex, exclusivly: true)
            }
            if allowsEmptySelection == false && selectedIndexes.count == 0 {
                select(at: 0)
            }
        } else {
            deselect(at: selectedIndexes)
        }
    }

    public var allowsSelection: Bool = true {
        didSet {
            updateSelections()
        }
    }

    public var allowsMultipleSelection: Bool = false {
        didSet {
            updateSelections()
        }
    }

    public var allowsEmptySelection: Bool = true {
        didSet {
            updateSelections()
        }
    }

    public var selectedIndexes: [Int] {
        elements.indexes(where: { $0.isSelected }).compactMap({ $0 })
    }

    public var selectedElements: [Element] {
        elements[selectedIndexes].compactMap({ $0.element })
    }

    var isSelecting: Bool = false

    public mutating func select(at index: Int) {
        select(at: index, exclusivly: false)
    }

    public mutating func select(at index: Int, exclusivly: Bool) {
        isSelecting = true
        guard allowsSelection, index < elements.count else { return }
        if !allowsMultipleSelection || exclusivly == true {
            elements.editEach({ $0.isSelected = false })
        }
        elements[index].isSelected = true
        isSelecting = false
    }

    public mutating func select(at indexes: [Int]) {
        guard allowsSelection else { return }
        if allowsMultipleSelection {
            indexes.forEach { self.select(at: $0) }
        } else if let firstIndex = indexes.first {
            select(at: firstIndex)
        }
    }

    public mutating func select(_ option: AdvanceOption, exclusivly: Bool) {
        switch option {
        case .next:
            if let first = selectedIndexes.first, first + 1 < elements.count {
                select(at: first + 1, exclusivly: exclusivly)
            }
        case .previous:
            if let first = selectedIndexes.first, first - 1 >= 0 {
                select(at: first - 1, exclusivly: exclusivly)
            }
        case .nextLooping:
            if let first = selectedIndexes.first {
                select(at: (first + 1 < elements.count) ? first + 1 : 0, exclusivly: exclusivly)
            }
        case .previousLooping:
            if let first = selectedIndexes.first {
                select(at: (first - 1 >= 0) ? first - 1 : elements.count, exclusivly: exclusivly)
            }
        case .first:
            if elements.isEmpty == false {
                select(at: 0, exclusivly: exclusivly)
            }
        case .last:
            if elements.isEmpty == false {
                select(at: elements.count - 1, exclusivly: exclusivly)
            }
        case .random:
            if elements.isEmpty == false {
                select(at: Int.random(in: 0 ..< elements.count), exclusivly: exclusivly)
            }
        }
    }

    public mutating func deselect(at index: Int) {
        guard elements.isEmpty == false, index < elements.count else { return }
        elements[index].isSelected = false
        updateSelections()
    }

    public mutating func deselect(at indexes: [Int]) {
        indexes.forEach { self.deselect(at: $0) }
    }

    public mutating func deselectFirst() {
        guard elements.isEmpty == false else { return }
        deselect(at: 0)
    }

    public mutating func deselectFirst(_ k: Int) {
        let count = elements.count - k
        guard elements.count >= count else { return }
        var deselectIndexes: [Int] = []
        for i in 0 ..< k {
            deselectIndexes.append(i)
        }
        deselect(at: deselectIndexes)
    }

    public mutating func selectFirst() {
        guard elements.isEmpty == false else { return }
        select(at: 0)
    }

    public mutating func selectFirst(_ k: Int) {
        let count = elements.count - k
        guard elements.count >= count else { return }
        var selectIndexes: [Int] = []
        for i in 0 ..< k {
            selectIndexes.append(i)
        }
        select(at: selectIndexes)
    }

    public mutating func deselectLast() {
        guard elements.isEmpty == false else { return }
        deselect(at: elements.count - 1)
    }

    public mutating func deselectLast(_ k: Int) {
        let count = elements.count - k
        guard elements.count >= count else { return }
        var deselectIndexes: [Int] = []
        for i in 0 ..< k {
            deselectIndexes.append(elements.count - 1 + i)
        }
        deselect(at: deselectIndexes)
    }

    public mutating func selectLast() {
        guard elements.isEmpty == false else { return }
        select(at: elements.count - 1)
    }

    public mutating func selectLast(_ k: Int) {
        let count = elements.count - k
        guard elements.count >= count else { return }
        var selectIndexes: [Int] = []
        for i in 0 ..< k {
            selectIndexes.append(elements.count - 1 + i)
        }
        select(at: selectIndexes)
    }

    public init() { }

    public init(arrayLiteral elements: Element...) {
        self.elements = elements.compactMap({ SelectableElement($0) })
    }

    public init<S>(_ elements: S) where S: Sequence, Element == S.Element {
        self.elements = elements.compactMap({ SelectableElement($0) })
    }

    public init(repeating repeatedValue: Element, count: Int) {
        elements = .init(repeating: SelectableElement(repeatedValue), count: count)
    }

    public var count: Int {
        return elements.count
    }

    public var isEmpty: Bool {
        return elements.isEmpty
    }

    public var startIndex: Int {
        return elements.startIndex
    }

    public var endIndex: Int {
        return elements.endIndex
    }

    public subscript(index: Int) -> Element {
        get {  return elements[index].element }
        set {  elements[index] = SelectableElement(newValue) }
    }

    public mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C)
        where C: Collection, R: RangeExpression, Element == C.Element, Int == R.Bound {
        let newElements =  newElements.compactMap({ SelectableElement($0) })
        elements.replaceSubrange(subrange, with: newElements)
    }
}

extension SelectableArrayNew: ExpressibleByArrayLiteral { }
extension SelectableArrayNew: Sendable where Element: Sendable { }
extension SelectableArrayNew.SelectableElement: Encodable where Element: Encodable { }
extension SelectableArrayNew.SelectableElement: Decodable where Element: Decodable { }
extension SelectableArrayNew: Encodable where Element: Encodable {}
extension SelectableArrayNew: Decodable where Element: Decodable {}

extension SelectableArrayNew: CVarArg {
    public var _cVarArgEncoding: [Int] {
        return elements._cVarArgEncoding
    }
}

extension SelectableArrayNew: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var customMirror: Mirror {
        return elements.customMirror
    }

    public var debugDescription: String {
        return elements.debugDescription
    }

    public var description: String {
        return elements.description
    }
}

extension SelectableArrayNew.SelectableElement: Equatable where Element: Equatable { }
extension SelectableArrayNew.SelectableElement: Hashable where Element: Hashable { }

extension SelectableArrayNew: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(elements)
    }
}

extension SelectableArrayNew: ContiguousBytes {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try elements.withUnsafeBytes(body)
    }
}

extension SelectableArrayNew: Equatable where Element: Equatable {
    public static func == (lhs: SelectableArrayNew<Element>, rhs: SelectableArrayNew<Element>) -> Bool {
        return lhs.elements == rhs.elements
    }
}
