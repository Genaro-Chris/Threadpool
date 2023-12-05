import ConcurrencyPrimitives
import Foundation

///
public final class ThreadPool: @unchecked Sendable {

    private let queue: ThreadSafeQueue<QueueOperation>

    private let count: Int

    private let threadHandles: [Thread]

    private let barrier: Barrier

    private let wait: WaitType

    ///
    public func poll() {
        waitForAll()
    }

    ///
    /// - Parameters:
    ///   - count:
    ///   - waitType:
    public init?(count: Int, waitType: WaitType = .cancelAll) {
        if count < 1 {
            return nil
        }
        self.count = count
        self.wait = waitType
        self.queue = ThreadSafeQueue()
        self.barrier = Barrier(count: count + 1)!
        self.threadHandles = start(queue: queue, count: count, barrier: barrier)
    }

    ///
    /// - Parameter body:
    public func submit(_ body: @escaping () -> Void) {
        queue <- .ready(element: body)
    }

    private func end() {
        threadHandles.forEach { $0.cancel() }
    }

    private func waitForAll() {
        (0 ..< count).forEach { _ in
            queue <- .wait
        }
        barrier.arriveAndWait()
    }

    deinit {
        switch wait {
            case .cancelAll:
                end()
            case .waitForAll:
                waitForAll()
                end()
        }
    }
}

private func start(
    queue: ThreadSafeQueue<QueueOperation>, count: Int, barrier: Barrier
) -> [Thread] {
    let threadHandles = (0 ..< count).map { _ in
        let thread = Thread {
            while let op = queue.next() {
                switch (op, Thread.current.isCancelled) {
                    case let (.ready(work), false): work()
                    case (.wait, _):
                        barrier.arriveAndWait()
                    case (.notYet, false): continue
                    default: return
                }
            }
        }
        thread.start()
        return thread
    }
    return threadHandles
}
