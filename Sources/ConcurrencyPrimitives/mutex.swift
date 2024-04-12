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

/// A threading mutex based on `libpthread` instead of `libdispatch`.
///
/// This object provides a mutex on top of a single `pthread_mutex_t`. This kind
/// of mutex is safe to use with `libpthread`-based threading models, such as the
/// one used by NIO.

public class Mutex {

    let mutex: UnsafeMutablePointer<pthread_mutex_t>
    private let mutexAttr: UnsafeMutablePointer<pthread_mutexattr_t>
    let mutexType: MutexType

    ///
    public struct MutexType: Equatable {

        let rawValue: Int32

        /// normal type
        public static let normal = MutexType(rawValue: Int32(PTHREAD_MUTEX_NORMAL))

        /// recursive type
        public static let recursive = MutexType(rawValue: Int32(PTHREAD_MUTEX_RECURSIVE))

        // error check type
        public static let error = MutexType(rawValue: Int32(PTHREAD_MUTEX_ERRORCHECK))
    }

    ///
    /// - Parameter type:
    public init(type: MutexType = .normal) {

        mutexType = type
        mutex = UnsafeMutablePointer.allocate(capacity: 1)
        mutex.initialize(to: pthread_mutex_t())
        mutexAttr = UnsafeMutablePointer.allocate(capacity: 1)
        mutexAttr.initialize(to: pthread_mutexattr_t())
        pthread_mutexattr_settype(mutexAttr, mutexType.rawValue)
        pthread_mutexattr_init(mutexAttr)
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
    public func tryLockUntil(forTimeInterval timeout: Timeout) {
        guard timeout.time >= 0 else {
            return
        }

        #if os(Linux)
            // wait until the time passed as argument as elapsed
            var timeoutAbs = getTimeSpec(with: timeout)
            pthread_mutex_timedlock(mutex, &timeoutAbs)
        #endif
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
