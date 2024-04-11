import ConcurrencyPrimitives
import Foundation

///
public final class ThreadPool: @unchecked Sendable {

    private let threadHandles: [UniqueThread]

    private let barrier: Barrier

    private let wait: WaitType

    private let started: OnceState

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
        self.wait = waitType
        self.barrier = Barrier(count: count + 1)!
        started = OnceState()
        threadHandles = (0..<count).map { _ in  UniqueThread() }
    }

    ///
    /// - Parameter body:
    public func submit(_ body: @escaping TaskItem) {
        started.runOnce {
            threadHandles.forEach { $0.start() }
        }
        threadHandles.randomElement()?.submit(body)
    }

    private func end() {
        threadHandles.forEach {
            $0.cancel()
        }
    }

    private func waitForAll() {
        guard started.hasExecuted else { return }
        threadHandles.forEach { [barrier] in
            $0.submit {
                barrier.arriveAlone()
            }
        }
        barrier.arriveAndWait()
    }

    deinit {
        guard started.hasExecuted else { return }
        switch wait {
        case .cancelAll:
            end()
        case .waitForAll:
            waitForAll()
            end()
        }
        threadHandles.forEach { $0.join() }
    }
}
