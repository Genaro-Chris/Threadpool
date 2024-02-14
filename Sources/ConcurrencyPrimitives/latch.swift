import Foundation

///
public final class Latch {
    private let condition = Condition()
    private let mutex = Mutex()
    private var blockedThreadIndex: Int

    ///
    /// - Parameter count:
    public init?(count: Int) {
        if count < 1 {
            return nil
        }
        blockedThreadIndex = count
    }

    ///
    public func decrementAndWait() {
        mutex.whileLocked {
            blockedThreadIndex -= 1
            guard blockedThreadIndex == 0 else {
                condition.wait(
                    mutex: mutex, condition: blockedThreadIndex == 0)
                return
            }
            condition.broadcast()
        }
    }

    ///
    public func decrementAlone() {
        mutex.whileLocked {
            blockedThreadIndex -= 1
            guard blockedThreadIndex == 0 else {
                return
            }
            condition.broadcast()
        }
    }

    ///
    /// Warning - This function will deadlock if ``decrementAndWait`` method is called more 
    /// or less than the count passed to the initializer
    public func waitForAll() {
        condition.wait(
            mutex: mutex, condition: blockedThreadIndex == 0)
    }

}
