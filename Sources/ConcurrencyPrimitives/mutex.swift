import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

/// A threading mutex based on `libpthread` instead of `libdispatch`.
///
/// This object provides a mutex on top of a single `pthread_mutex_t`. This kind
/// of mutex is safe to use with `libpthread`-based threading models, such as the
/// one used by NIO.

public class Mutex {

    let mutex: UnsafeMutablePointer<pthread_mutex_t>
    private let mutexAttr: UnsafeMutablePointer<pthread_mutexattr_t>

    ///
    public enum MutexType: Int32 {
        ///
        case normal = 0
        ///
        case recursive
    }

    ///
    /// - Parameter type:
    public init(type: MutexType = .normal) {
        mutex = UnsafeMutablePointer.allocate(capacity: 1)
        mutex.initialize(to: pthread_mutex_t())
        mutexAttr = UnsafeMutablePointer.allocate(capacity: 1)
        mutexAttr.initialize(to: pthread_mutexattr_t())
        pthread_mutexattr_settype(mutexAttr, type.rawValue)
        pthread_mutex_init(mutex, mutexAttr)
    }

    deinit {
        mutexAttr.deinitialize(count: 1)
        mutex.deinitialize(count: 1)
        mutexAttr.deallocate()
        mutex.deallocate()
    }

    ///
    public func lock() {
        pthread_mutex_lock(mutex)
    }

    /// Wait until lock becomes available, or specified time passes
    public func tryLockUntil(forTimeInterval timeoutSeconds: TimeInterval) {
        guard timeoutSeconds >= 0 else {
            return
        }

        // convert argument passed into nanoseconds
        let nsecPerSec: Int64 = 1_000_000_000
        let timeoutNS = Int64(timeoutSeconds * Double(nsecPerSec))

        // get the current time
        var curTime = timeval()
        gettimeofday(&curTime, nil)

        // calculate the timespec from the argument passed
        let allNSecs: Int64 = timeoutNS + Int64(curTime.tv_usec) * 1000
        var timeoutAbs = timespec(
            tv_sec: curTime.tv_sec + Int(allNSecs / nsecPerSec),
            tv_nsec: Int(allNSecs % nsecPerSec)
        )

        // wait until the time passed as argument as elapsed
        pthread_mutex_timedlock(mutex, &timeoutAbs)
    }

    ///
    /// - Returns:
    @discardableResult
    public func tryLock() -> Bool {
        pthread_mutex_trylock(mutex) == 0
    }

    ///
    public func unlock() {
        pthread_mutex_unlock(mutex)
    }

    ///
    /// - Parameter body:
    /// - Returns:
    @discardableResult
    @inlinable
    public func whileLocked<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
