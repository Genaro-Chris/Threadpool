import Foundation

public class Condition {
    private var condition: pthread_cond_t
    private var conditionAttr: pthread_condattr_t
    public init() {
        condition = pthread_cond_t()
        conditionAttr = pthread_condattr_t()
        pthread_cond_init(&condition, &conditionAttr)
    }

    deinit {
        pthread_condattr_destroy(&conditionAttr)
        pthread_cond_destroy(&condition)
    }
    /// 
    /// - Parameters:
    ///   - mutex: 
    ///   - forTimeInterval: 
    public func wait(mutex: Mutex, forTimeInterval: TimeInterval) {
        let isLocked = mutex.tryLock()
        var deadline = timespec(tv_sec: Int(ceil(forTimeInterval)), tv_nsec: 0)
        pthread_cond_timedwait(&condition, &mutex.mutex, &deadline)
        if isLocked == 0 {
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
            pthread_cond_wait(&self.condition, &mutex.mutex)
        }
        if isLocked == 0 {
            mutex.unlock()
        }
    }

    /// 
    /// - Parameter mutex: 
    public func wait(mutex: Mutex) {
        let isLocked = mutex.tryLock()
        pthread_cond_wait(&condition, &mutex.mutex)
        if isLocked == 0 {
            mutex.unlock()
        }
    }

    ///
    public func signal() {
        pthread_cond_signal(&condition)
    }

    ///
    public func broadcast() {
        pthread_cond_broadcast(&condition)
    }
}
