import ConcurrencyPrimitives

@frozen
public struct Channel<Element> {

    private let storage: _Storage<Element>

    private let mutex: Mutex

    private let condition: Condition

    /// Initializes an instance of `Channel` type
    public init() {
        storage = _Storage()
        mutex = Mutex()
        condition = Condition()
    }

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

extension Channel {

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
