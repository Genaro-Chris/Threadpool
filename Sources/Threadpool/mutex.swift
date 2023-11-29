import Foundation

public class Mutex {

    var mutex: pthread_mutex_t
    private var mutexAttr: pthread_mutexattr_t

    public enum MutexType {
        case normal, recursive
    }

    public init(type: MutexType = .normal) {
        mutex = pthread_mutex_t()
        mutexAttr = pthread_mutexattr_t()
        let value: Int32 =
            switch type {
                case .normal:
                    0
                case .recursive:
                    1
            }
        pthread_mutexattr_settype(&mutexAttr, value)
        pthread_mutex_init(&mutex, &mutexAttr)
    }

    deinit {
        pthread_mutexattr_destroy(&mutexAttr)
        pthread_mutex_destroy(&mutex)
    }

    public func lock() {
        pthread_mutex_lock(&mutex)
    }

    public func tryLock() -> Int32 {
        pthread_mutex_trylock(&mutex)
    }

    public func unlock() {
        pthread_mutex_unlock(&mutex)
    }

    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
