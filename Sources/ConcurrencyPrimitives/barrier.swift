import Foundation

///
public final class Barrier: @unchecked Sendable {
    private let condition = Condition()
    private let mutex = Mutex()
    private var blockedThreadIndex = 0
    private let threadCount: Int

    /// 
    /// - Parameter count: 
    public init?(count: Int) {
        if count < 1 {
            return nil
        }
        threadCount = count
    }

    ///
    public func arriveAndWait() {
        mutex.whileLocked {
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

