import ConcurrencyPrimitives
import Foundation
import ThreadPool

final class SerialJobExecutor: SerialExecutor {

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    public init() {}

    private let threadHandle = SingleThread(waitType: .cancelAll)

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        threadHandle.submit {
            job.runSynchronously(on: executor)
        }
    }

}
