import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

///
public final class Condition {
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
    public func wait(mutex: Mutex, forTimeInterval timeoutSeconds: TimeInterval) {
        guard timeoutSeconds >= 0 else {
            return
        }

        mutex.tryLock()

        // convert argument passed into nanoseconds
        let nsecPerSec: Int64 = 1_000_000_000
        let timeoutNS = Int64(timeoutSeconds * Double(nsecPerSec))

        // get the current clock id
        var clockID = clockid_t()
        pthread_condattr_getclock(conditionAttr, &clockID)

        // get the current time
        var curTime = timespec(tv_sec: __time_t(0), tv_nsec: 0)
        clock_gettime(clockID, &curTime)

        // calculate the timespec from the argument passed
        let allNSecs: Int64 = timeoutNS + Int64(curTime.tv_nsec) / nsecPerSec
        var timeoutAbs = timespec(
            tv_sec: curTime.tv_sec + Int(allNSecs / nsecPerSec),
            tv_nsec: curTime.tv_nsec + Int(allNSecs % nsecPerSec)
        )

        // wait until the time passed as argument as elapsed
        pthread_cond_timedwait(condition, mutex.mutex, &timeoutAbs)
    }

    /// Blocks the current thread until the condition return true
    /// - Parameters:
    ///   - mutex:
    ///   - condition:
    public func wait(mutex: Mutex, condition: @autoclosure () -> Bool) {
        mutex.tryLock()
        while !condition() {
            pthread_cond_wait(self.condition, mutex.mutex)
        }

    }

    /// Blocks the current thread
    /// - Parameter mutex:
    public func wait(mutex: Mutex) {
        mutex.tryLock()
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
