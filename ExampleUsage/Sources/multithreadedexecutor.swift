import ConcurrencyPrimitives
import Foundation
import ThreadPool

final class MultiThreadedSerialJobExecutor: SerialExecutor {

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    init() {}

    private let mutex = Mutex()

    private let threadHandle = ThreadPool(count: 2)

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        threadHandle?.submit { [mutex] in
            mutex.whileLocked {
                job.runSynchronously(on: executor)
            }
        }
    }

}
