import ConcurrencyPrimitives

@frozen
@_eagerMove
public struct UnboundedChannel<Element> {

    @usableFromInline let storage: Storage<Element>

    @usableFromInline let mutex: Mutex

    @usableFromInline let condition: Condition

    /// Initializes an instance of `UnboundedChannel` type
    public init() {
        storage = Storage()
        mutex = Mutex()
        condition = Condition()
    }

    @inlinable
    public func enqueue(_ item: Element) -> Bool {
        return mutex.whileLocked {
            guard !storage.closed else {
                return false
            }
            storage.enqueue(item)
            if !storage.ready {
                storage.ready = true
            }
            condition.signal()
            return true
        }
    }

    @inlinable
    public func dequeue() -> Element? {
        mutex.whileLocked {
            guard !storage.closed else {
                return storage.dequeue()
            }
            condition.wait(mutex: mutex, condition: storage.readyToReceive)
            guard !storage.isEmpty else {
                storage.ready = false
                return nil
            }
            return storage.dequeue()
        }
    }

    public func clear() {
        mutex.whileLocked { storage.clear() }
    }

    public func close() {
        mutex.whileLocked {
            storage.closed = true
            condition.broadcast()
        }
    }
}

extension UnboundedChannel: IteratorProtocol, Sequence {

    public mutating func next() -> Element? {
        return dequeue()
    }

}

extension UnboundedChannel {

    public var isClosed: Bool {
        return mutex.whileLocked {
            storage.closed
        }
    }

    public var length: Int {
        return mutex.whileLocked { storage.buffer.count }
    }

    public var isEmpty: Bool {
        return mutex.whileLocked { storage.buffer.isEmpty }
    }
}
