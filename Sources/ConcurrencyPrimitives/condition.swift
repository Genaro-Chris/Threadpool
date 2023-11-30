import Foundation

public class Condition: @unchecked Sendable {
    private let condition: UnsafeMutablePointer<pthread_cond_t>
    private let conditionAttr: UnsafeMutablePointer<pthread_condattr_t>
    public init() {
        condition = UnsafeMutablePointer.allocate(capacity: 1)
        condition.initialize(to: pthread_cond_t())
        conditionAttr = UnsafeMutablePointer.allocate(capacity: 1)
        conditionAttr.initialize(to: pthread_condattr_t())
        pthread_cond_init(condition, conditionAttr)
    }

    deinit {
        pthread_condattr_destroy(conditionAttr)
        pthread_cond_destroy(condition)
    }
    ///
    /// - Parameters:
    ///   - mutex:
    ///   - forTimeInterval:
    public func wait(mutex: Mutex, forTimeInterval: TimeInterval) {
        let isLocked = mutex.tryLock()
        var deadline = timespec(tv_sec: Int(ceil(forTimeInterval)), tv_nsec: 0)
        pthread_cond_timedwait(condition, mutex.mutex, &deadline)
        if isLocked {
            mutex.unlock()
        }
    }

    ///
    /// - Parameters:
    ///   - mutex:
    ///   - condition:
    public func wait(mutex: Mutex, condition: @autoclosure () -> Bool) {
        let isLocked = mutex.tryLock()
        while !condition() {
            pthread_cond_wait(self.condition, mutex.mutex)
        }
        if isLocked {
            mutex.unlock()
        }
    }

    ///
    /// - Parameter mutex:
    public func wait(mutex: Mutex) {
        let isLocked = mutex.tryLock()
        pthread_cond_wait(condition, mutex.mutex)
        if isLocked {
            mutex.unlock()
        }
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
