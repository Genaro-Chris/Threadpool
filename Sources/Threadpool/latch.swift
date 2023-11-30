import Foundation

///
public class Latch: @unchecked Sendable {
    private let condition = Condition()
    private let mutex = Mutex()
    private var blockedThreadIndex: Int

    ///
    /// - Parameter value:
    public init?(value: Int) {
        if value < 1 {
            return nil
        }
        blockedThreadIndex = value
    }

    ///
    public func decrementAndWait() {
        mutex.withLock {
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
    /// Warning - This function will deadlock if ``decrementAndWait`` method is called more or less than the value 
    public func waitForAll() {
        condition.wait(
            mutex: mutex, condition: blockedThreadIndex == 0)
    }

}
