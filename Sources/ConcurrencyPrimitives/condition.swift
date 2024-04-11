import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#else
    #error("Unable to identify your underlying C library.")
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
        pthread_condattr_init(conditionAttr)
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
    public func wait(mutex: Mutex, forTimeInterval timeoutSeconds: Timeout) {
        guard timeoutSeconds.time >= 0 else {
            return
        }

        if case .recursive = mutex.mutexType {
            fatalError("Condition type should never be used with recursive mutexes")
        }

        precondition(!mutex.tryLock(), "\(#function) must be called only while the mutex is locked")

        // convert seconds into nanoseconds
        let nsecPerSec: Int64 = 1_000_000_000
        let timeoutNS = timeoutSeconds.timeoutIntoNS

        #if os(macOS) || canImport(Darwin)

            var curTime = timeval()
            // get the current time
            gettimeofday(&curTime, nil)

            let allNSecs: Int64 = timeoutNS + Int64(curTime.tv_usec) * 1000
            // calculate the timespec from the argument passed
            var timeoutAbs = timespec(
                tv_sec: curTime.tv_sec + Int((allNSecs / nsecPerSec)),
                tv_nsec: Int(allNSecs % nsecPerSec))
            assert(timeoutAbs.tv_nsec >= 0 && timeoutAbs.tv_nsec < Int(nsecPerSec))
            assert(timeoutAbs.tv_sec >= curTime.tv_sec)
            switch pthread_cond_timedwait(condition, mutex.mutex, &timeoutAbs) {
            case 0, ETIMEDOUT:
                return
            case let err:
                fatalError("caught error \(err) when calling pthread_cond_timedwait")
            }

        #else
            pthread_condattr_setclock(conditionAttr, CLOCK_MONOTONIC)

            // get the current clock id
            var clockID = clockid_t(0)
            pthread_condattr_getclock(conditionAttr, &clockID)

            // get the current time
            var curTime = timespec(tv_sec: 0, tv_nsec: 0)
            clock_gettime(clockID, &curTime)

            // calculate the timespec from the argument passed
            let allNSecs: Int64 = timeoutNS + Int64(curTime.tv_nsec) / nsecPerSec
            var timeoutAbs = timespec(
                tv_sec: curTime.tv_sec + Int(allNSecs / nsecPerSec),
                tv_nsec: curTime.tv_nsec + Int(allNSecs % nsecPerSec)
            )

            // wait until the time passed as argument as elapsed
            switch pthread_cond_timedwait(condition, mutex.mutex, &timeoutAbs) {
            case 0, ETIMEDOUT: ()
            case let err:
                fatalError("caught error \(err) when calling pthread_cond_timedwait")
            }
        #endif

    }

    /// Blocks the current thread until the condition return true
    /// - Parameters:
    ///   - mutex:
    ///   - condition:
    public func wait(mutex: Mutex, condition: @autoclosure () -> Bool) {
        if case .recursive = mutex.mutexType {
            fatalError("Condition type should never be used with recursive mutexes")
        }
        precondition(!mutex.tryLock(), "\(#function) must be called only while the mutex is locked")
        while !condition() {
            pthread_cond_wait(self.condition, mutex.mutex)
        }

    }

    /// Blocks the current thread
    /// - Parameter mutex:
    public func wait(mutex: Mutex) {
        if case .recursive = mutex.mutexType {
            fatalError("Condition type should never be used with recursive mutexes")
        }
        precondition(!mutex.tryLock(), "\(#function) must be called only while the mutex is locked")
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
