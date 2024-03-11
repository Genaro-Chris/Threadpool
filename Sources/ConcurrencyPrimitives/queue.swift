import Foundation

prefix operator <-
infix operator <-

///
public final class ThreadSafeQueue<Element>: @unchecked Sendable {

    private class Buffer<T> {
        var buffer: [T] = []

        public func enqueue(_ item: T) {
            buffer.append(item)
        }

        ///
        /// - Returns:
        public func dequeue(order: Order) -> T? {
            guard !buffer.isEmpty else {
                return nil
            }
            switch order {
            case .firstOut:
                return buffer.remove(at: 0)
            case .lastOut:
                return buffer.popLast()
            }

        }
    }

    ///
    public enum Order {
        /// First-In First out order
        case firstOut
        /// Last-In Last-Out order
        case lastOut
    }

    private let order: Order

    ///
    /// - Parameter order:
    public init(order: Order = .firstOut) {
        self.order = order
        self.buffer = Buffer()
    }

    private let buffer: Buffer<Element>
    private let mutex = Mutex(type: .recursive)

    ///
    /// - Parameter item:
    public func enqueue(_ item: Element) {
        mutex.whileLocked {
            buffer.enqueue(item)
        }
    }

    ///
    /// - Returns:
    public func dequeue() -> Element? {
        return mutex.whileLocked {
            buffer.dequeue(order: order)
        }
    }
}

extension ThreadSafeQueue {

    ///
    public static func <- (this: ThreadSafeQueue, value: Element) {
        this.enqueue(value)
    }

    ///
    public static prefix func <- (this: ThreadSafeQueue) -> Element? {
        this.dequeue()
    }

    public var isEmpty: Bool {
        return mutex.whileLocked {
            buffer.buffer.isEmpty
        }
    }
}
