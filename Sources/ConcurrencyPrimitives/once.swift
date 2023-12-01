import Foundation

///
public enum Once {

    private static var once = pthread_once_t()

    ///
    /// - Parameter body:
    public static func runOnce(_ body: @escaping () -> Void) {
        Self.queue <- body
        pthread_once(&once) {
            (<-Once.queue)?()
        }

    }

    private static let queue = ThreadSafeQueue<() -> Void>()
}
