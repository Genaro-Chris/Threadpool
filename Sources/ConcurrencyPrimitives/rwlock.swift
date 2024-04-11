import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#else
    #error("Unable to identify your C library.")
#endif

///
public final class RWLock: @unchecked Sendable {

    let rwLock: UnsafeMutablePointer<pthread_rwlock_t>
    let rwLockAttr: UnsafeMutablePointer<pthread_rwlockattr_t>

    ///
    public enum RWLockPreference: Int32 {
        ///
        case readingFirst = 0
        ///
        case writingFirst
    }

    ///
    public init(preference: RWLockPreference = .readingFirst) {
        rwLockAttr = UnsafeMutablePointer.allocate(capacity: 1)
        rwLockAttr.initialize(to: pthread_rwlockattr_t())
        rwLock = UnsafeMutablePointer.allocate(capacity: 1)
        rwLock.initialize(to: pthread_rwlock_t())
        pthread_rwlock_init(rwLock, rwLockAttr)
        #if os(Linux)
            pthread_rwlockattr_setkind_np(rwLockAttr, preference.rawValue)
        #endif
    }

    deinit {
        pthread_rwlockattr_destroy(rwLockAttr)
        pthread_rwlock_destroy(rwLock)
        rwLockAttr.deallocate()
        rwLock.deallocate()
    }

    ///
    public func readLock() {
        pthread_rwlock_rdlock(rwLock)
    }

    ///
    public func writeLock() {
        pthread_rwlock_wrlock(rwLock)
    }

    ///
    @discardableResult
    public func tryReadLock() -> Bool {
        pthread_rwlock_tryrdlock(rwLock) == 0
    }

    ///
    @discardableResult
    public func tryWriteLock() -> Bool {
        pthread_rwlock_wrlock(rwLock) == 0
    }

    ///
    public func unlock() {
        pthread_rwlock_unlock(rwLock)
    }

    ///
    /// - Parameter body:
    /// - Returns:
    @discardableResult
    @inlinable
    public func whileReadLocked<T>(_ body: () throws -> T) rethrows -> T {
        readLock()
        defer { unlock() }
        return try body()
    }

    ///
    /// - Parameter body:
    /// - Returns:
    @discardableResult
    @inlinable
    public func whileWriteLocked<T>(_ body: () throws -> T) rethrows -> T {
        writeLock()
        defer { unlock() }
        return try body()
    }
}
