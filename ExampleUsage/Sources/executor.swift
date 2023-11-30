import ConcurrencyPrimitives
import Foundation
import ThreadPool

final class SerialJobExecutor: SerialExecutor {

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    private let queue = ThreadSafeQueue<(UnownedJob, UnownedSerialExecutor)>()

    init() {}

    private let threadHandle = SingleThread()

    func enqueue(_ job: consuming ExecutorJob) {
        queue <- (UnownedJob(job), asUnownedSerialExecutor())
        threadHandle.submit { [queue] in
            guard let (job, executor) = <-queue else {
                return
            }
            job.runSynchronously(on: executor)
        }
    }

}
