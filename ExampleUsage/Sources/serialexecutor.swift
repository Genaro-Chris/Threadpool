import ConcurrencyPrimitives
import Foundation
import ThreadPool

final class SerialJobExecutor: SerialExecutor {

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    init() {}

    private let threadHandle = SingleThread()

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        threadHandle.submit {
            print(type(of: self), Thread.current)
            job.runSynchronously(on: executor)
        }
    }

}
