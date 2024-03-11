import ConcurrencyPrimitives
import Foundation

///
public final class ThreadPool: @unchecked Sendable {

private struct RandomGenerator {

    var filled: [Int]

    let max: Int

    init(to size: Int) {
        max = size
        filled = (0..<max).shuffled()
    }

    mutating func random() -> Int {
        if filled.isEmpty {
            filled = (0..<max).shuffled()
            return filled.removeFirst()
        }
        return filled.removeFirst()
    }

}

    private var generator: RandomGenerator

    private let threadHandles: [UniqueThread]

    private let barrier: Barrier

    private let wait: WaitType

    private let mutex: Mutex

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
        mutex = Mutex()
        self.wait = waitType
        self.barrier = Barrier(count: count + 1)!
        generator = RandomGenerator(to: count)
        started = OnceState()
        threadHandles = (0..<count).map { _ in  UniqueThread() }
    }

    ///
    /// - Parameter body:
    public func submit(_ body: @escaping TaskItem) {
        started.runOnce {
            threadHandles.forEach { $0.start() }
        }
        mutex.whileLocked {
            threadHandles[generator.random()].submit(body)
        }
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
    }
}
