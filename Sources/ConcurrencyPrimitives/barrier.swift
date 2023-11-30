import Foundation

///
public class Barrier: @unchecked Sendable {
    private let condition = Condition()
    private let mutex = Mutex()
    private var blockedThreadIndex = 0
    private let threadCount: Int

    /// 
    /// - Parameter value: 
    public init?(value: Int) {
        if value < 1 {
            return nil
        }
        threadCount = value
    }

    ///
    public func arriveAndWait() {
        mutex.withLock {
            blockedThreadIndex += 1
            guard blockedThreadIndex != threadCount else {
                blockedThreadIndex = 0
                condition.broadcast()
                return
            }
            condition.wait(mutex: mutex, condition: blockedThreadIndex == 0)
        }
    }
}

