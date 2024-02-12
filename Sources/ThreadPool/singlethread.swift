import ConcurrencyPrimitives
import Foundation

public final class SingleThread: @unchecked Sendable {

    private let handle: Thread

    ///
    public func poll() {
        waitForAll()
    }

    private let queue: ThreadSafeQueue<QueueOperation>

    private let waitType: WaitType

    private let barrier: Barrier

    ///
    /// - Parameter waitType:
    public init(waitType: WaitType = .waitForAll) {
        self.waitType = waitType
        queue = ThreadSafeQueue()
        barrier = Barrier(count: 2)!
        handle = start(queue: queue, barrier: barrier)
    }

    private func end() {
        handle.cancel()
    }

    private func waitForAll() {
        queue <- .wait
        barrier.arriveAndWait()
    }

    public func submit(_ body: @escaping () -> Void) {
        queue <- .ready(element: body)
    }

    deinit {
        switch waitType {
        case .cancelAll: end()

        case .waitForAll:
            waitForAll()
            end()
        }
    }
}

private func start(queue: ThreadSafeQueue<QueueOperation>, barrier: Barrier) -> Thread {
    let thread = Thread { [queue, barrier] in
        while let operation = queue.next() {
            switch (operation, Thread.current.isCancelled) {
            case let (.ready(work), false): work()
            case (.wait, false): barrier.arriveAndWait()
            case (.notYet, false): continue
            default: return
            }
        }
    }
    thread.start()
    return thread
}
