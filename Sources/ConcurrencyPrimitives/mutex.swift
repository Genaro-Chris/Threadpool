import Foundation

public class Mutex {

    let mutex: UnsafeMutablePointer<pthread_mutex_t>
    private let mutexAttr: UnsafeMutablePointer<pthread_mutexattr_t>

    ///
    public enum MutexType {
        case normal, recursive
    }

    ///
    /// - Parameter type:
    public init(type: MutexType = .normal) {
        mutex = UnsafeMutablePointer.allocate(capacity: 1)
        mutex.initialize(to: pthread_mutex_t())
        mutexAttr = UnsafeMutablePointer.allocate(capacity: 1)
        mutexAttr.initialize(to: pthread_mutexattr_t())
        switch type {
        case .normal:
            pthread_mutexattr_settype(mutexAttr, 0)
        case .recursive:
            pthread_mutexattr_settype(mutexAttr, 1)
        }
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

    ///
    /// - Returns:
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
