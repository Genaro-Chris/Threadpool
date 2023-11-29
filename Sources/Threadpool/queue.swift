import Foundation

prefix operator <-
infix operator <-

///
public class ThreadSafeQueue<Element>: @unchecked Sendable {

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
    }

    private var buffer: [Element] = []
    private let lock = Mutex()

    ///
    /// - Parameter item:
    public func enqueue(_ item: Element) {
        lock.withLock {
            buffer.append(item)
        }
    }

    ///
    /// - Returns:
    public func dequeue() -> Element? {
        return lock.withLock {
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
}
