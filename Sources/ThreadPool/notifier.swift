import ConcurrencyPrimitives
import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

final class LockBasedSemaphore {

    private let condition = Condition()

    private let mutex = Mutex()

    private let size: Int

    private var innerCount: Int

    var count: Int {
        mutex.whileLocked {
            innerCount
        }
    }

    init(_ size: Int = 0) {
        innerCount = size
        self.size = size
    }

    func decrement(by count: Int = 1) {
        mutex.whileLocked {
            self.innerCount -= count
            if innerCount == 0 {
                condition.signal()
            }
        }
    }

    func waitForZero() {
        mutex.whileLocked {
            condition.wait(mutex: mutex, condition: innerCount == 0)
        }
        print("Done")
    }
}
