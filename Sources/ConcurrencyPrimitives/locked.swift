///
@dynamicMemberLookup
@propertyWrapper
public final class Locked<Element>: @unchecked Sendable {

    @usableFromInline let lock: Mutex

    @usableFromInline var value: Element

    public var wrappedValue: Element {
        get {
            return updateWhileLocked { $0 }
        }
        set {
            updateWhileLocked { $0 = newValue }
        }
    }

    public init(_ value: Element) {
        self.value = value
        lock = Mutex(type: .normal)
    }

    @inlinable
    public func updateWhileLocked<T>(_ using: (inout Element) throws -> T) rethrows -> T {
        return try lock.whileLocked {
            return try using(&value)
        }
    }

    convenience
    public init(wrappedValue value: Element) {
        self.init(value)
    }

    public var projectedValue: Locked<Element> {
        return self
    }
}

extension Locked {

    public subscript<T>(dynamicMember memberKeyPath: KeyPath<Element, T>) -> T {
        updateWhileLocked { $0[keyPath: memberKeyPath] }
    }

    public subscript<T>(dynamicMember memberKeyPath: WritableKeyPath<Element, T>) -> T {
        get {
            updateWhileLocked { $0[keyPath: memberKeyPath] }
        }
        set {
            updateWhileLocked { $0[keyPath: memberKeyPath] = newValue }
        }
    }

}

extension Locked where Element: AnyObject {

    public subscript<T>(dynamicMember memberKeyPath: ReferenceWritableKeyPath<Element, T>) -> T {
        get {
            updateWhileLocked { $0[keyPath: memberKeyPath] }
        }
        set {
            updateWhileLocked { $0[keyPath: memberKeyPath] = newValue }
        }
    }
}
