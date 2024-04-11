import ConcurrencyPrimitives
import Foundation

public final class SingleThread: @unchecked Sendable {

    private let handle: UniqueThread

    ///
    public func poll() {
        waitForAll()
    }

    private let waitType: WaitType

    private let barrier: Barrier

    private let started: OnceState

    ///
    /// - Parameter waitType:
    public init(waitType: WaitType = .waitForAll) {
        self.waitType = waitType
        barrier = Barrier(count: 2)!
        handle = UniqueThread()
        started = OnceState()
    }

    private func end() {
        handle.cancel()
    }

    private func waitForAll() {
        handle.submit { [barrier] in
            barrier.arriveAlone()
        }
        barrier.arriveAndWait()
    }

    public func submit(_ body: @escaping TaskItem) {
        started.runOnce {
            handle.start()
        }
        handle.submit(body)
    }

    deinit {
        guard started.hasExecuted else { return }
        switch waitType {
        case .cancelAll: end()

        case .waitForAll:
            waitForAll()
            end()
        }

        handle.join()
    }
}
