import Foundation

///
public enum Once {

    private static var once_t = pthread_once_t()

    private static let mutex = Mutex(type: .normal)

    ///
    /// - Parameter body:
    public static func runOnce(_ body: @escaping () -> Void) {
        Self.queue <- body
        mutex.withLock {
            pthread_once(&once_t) {
                (<-Once.queue)?()
            }
        }

    }

    private static let queue = ThreadSafeQueue<() -> Void>()
}
