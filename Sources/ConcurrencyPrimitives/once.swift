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

public typealias TaskItem = () -> Void

public typealias SendableTaskItem = @Sendable () -> Void

///
public enum Once {

    private static let once = Locked(false)

    ///
    /// - Parameter body:
    public static func runOnce(_ body: @escaping TaskItem) {
        once.updateWhileLocked {
            guard !$0 else {
                return
            }
            $0 = true
            body()
        }
    }

    private static let queue = ThreadSafeQueue<() -> Void>()
}

public class OnceState {

    public init() {}

    private var done = false

    private let mutex = Mutex()

    public func runOnce(body: TaskItem) {
        mutex.whileLocked {
            guard !done else {
                return
            }
            done = true
            body()
        }
    }
    public var hasExecuted: Bool {
        mutex.whileLocked {
            done
        }
    }
}
