import Foundation

///
public final class Condition: @unchecked Sendable {
    private let condition: UnsafeMutablePointer<pthread_cond_t>
    private let conditionAttr: UnsafeMutablePointer<pthread_condattr_t>

    ///
    public init() {
        condition = UnsafeMutablePointer.allocate(capacity: 1)
        condition.initialize(to: pthread_cond_t())
        conditionAttr = UnsafeMutablePointer.allocate(capacity: 1)
        conditionAttr.initialize(to: pthread_condattr_t())
        pthread_cond_init(condition, conditionAttr)
    }

    deinit {
        conditionAttr.deinitialize(count: 1)
        condition.deinitialize(count: 1)
        conditionAttr.deallocate()
        condition.deallocate()
    }

    /// Blocks the current thread until a specified time interval is reached
    /// - Parameters:
    ///   - mutex:
    ///   - forTimeInterval:
    public func wait(mutex: Mutex, forTimeInterval: TimeInterval) {
        let isLocked = mutex.tryLock()
        defer {
            if isLocked { mutex.unlock() }
        }
        var deadline = timespec(tv_sec: Int(ceil(forTimeInterval)), tv_nsec: 0)
        pthread_cond_timedwait(condition, mutex.mutex, &deadline)

    }

    /// Blocks the current thread until the condition return true
    /// - Parameters:
    ///   - mutex:
    ///   - condition:
    public func wait(mutex: Mutex, condition: @autoclosure () -> Bool) {
        let isLocked = mutex.tryLock()
        defer {
            if isLocked { mutex.unlock() }
        }
        while !condition() {
            pthread_cond_wait(self.condition, mutex.mutex)
        }

    }

    /// Blocks the current thread
    /// - Parameter mutex:
    public func wait(mutex: Mutex) {
        let isLocked = mutex.tryLock()
        defer {
            if isLocked { mutex.unlock() }
        }
        pthread_cond_wait(condition, mutex.mutex)
    }

    ///
    public func signal() {
        pthread_cond_signal(condition)
    }

    ///
    public func broadcast() {
        pthread_cond_broadcast(condition)
    }
}
