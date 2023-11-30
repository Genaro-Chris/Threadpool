import Foundation

public final class SingleThread: @unchecked Sendable {

    private let handle: Thread

    ///
    public func poll() {
        waitForAll()
    }

    private let queue: ThreadSafeQueue<QueueOperation>

    private let waitType: WaitType

    private let semaphore: DispatchSemaphore

    /// 
    /// - Parameter waitType: 
    public init(waitType: WaitType = .waitForAll) {
        self.waitType = waitType
        queue = ThreadSafeQueue()
        semaphore = DispatchSemaphore(value: 0)
        handle = start(queue: queue, semaphore: semaphore)
    }

    private func end() {
        handle.cancel()
    }

    private func waitForAll() {
        queue <- .wait
        semaphore.wait()
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

private func start(queue: ThreadSafeQueue<QueueOperation>, semaphore: DispatchSemaphore) -> Thread {
    let thread = Thread { [queue, semaphore] in
        for op in queue {
            switch (op, Thread.current.isCancelled) {
                case let (.ready(work), false): work()
                case (.wait, false):
                    semaphore.signal()
                case (.notYet, false): continue
                default: return
            }
        }
    }
    thread.start()
    return thread
}
