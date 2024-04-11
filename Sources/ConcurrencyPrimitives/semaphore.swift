public final class LockBasedSemaphore {

    private let condition = Condition()

    private let mutex = Mutex()

    private let size: Int

    private var innerCount: Int

    var count: Int {
        mutex.whileLocked {
            innerCount
        }
    }

    public init(size: Int = 0) {
        innerCount = size
        self.size = size
    }

    public func decrement(by count: Int = 1) {
        mutex.whileLocked {
            self.innerCount -= count
            if innerCount == 0 {
                condition.signal()
            }
        }
    }

    public func waitForZero() {
        mutex.whileLocked {
            condition.wait(mutex: mutex, condition: innerCount == 0)
        }
    }
}
