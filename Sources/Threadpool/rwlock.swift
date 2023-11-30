import Foundation

///
public class RWLock: @unchecked Sendable {

    var rwLock: pthread_rwlock_t
    var rwLockAttr: pthread_rwlockattr_t

    ///
    public init() {
        rwLockAttr = pthread_rwlockattr_t()
        rwLock = pthread_rwlock_t()
        pthread_rwlockattr_setkind_np(&rwLockAttr, 2)
        pthread_rwlock_init(&rwLock, &rwLockAttr)

    }

    deinit {
        pthread_rwlockattr_destroy(&rwLockAttr)
        pthread_rwlock_destroy(&rwLock)
    }

    ///
    public func readLock() {
        pthread_rwlock_rdlock(&rwLock)
    }

    ///
    public func writeLock() {
        pthread_rwlock_wrlock(&rwLock)
    }

    ///
    @discardableResult
    public func tryReadLock() -> Int32 {
        pthread_rwlock_tryrdlock(&rwLock)
    }

    ///
    @discardableResult
    public func tryWriteLock() -> Int32 {
        pthread_rwlock_wrlock(&rwLock)
    }

    ///
    public func unlock() {
        pthread_rwlock_unlock(&rwLock)
    }

    ///
    /// - Parameter body:
    /// - Returns:
    @discardableResult
    public func withReadLock<T>(_ body: () throws -> T) rethrows -> T {
        readLock()
        defer { unlock() }
        return try body()
    }

    ///
    /// - Parameter body:
    /// - Returns:
    @discardableResult
    public func withWriteLock<T>(_ body: () throws -> T) rethrows -> T {
        writeLock()
        defer { unlock() }
        return try body()
    }
}
