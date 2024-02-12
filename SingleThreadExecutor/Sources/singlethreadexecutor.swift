import ConcurrencyPrimitives
import Foundation
import ThreadPool

/// 
public final class SingleThreadSerialExecutor: SerialExecutor {

    private let queueOfJobs = ThreadSafeQueue<UnownedJob>()

    private let handle = SingleThread(waitType: .cancelAll)

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()

        queueOfJobs <- job

        handle.submit { [weak self] in
            guard let self, let job = <-queueOfJobs else {
                return
            }
            job.runSynchronously(on: executor)
        }
    }
}
