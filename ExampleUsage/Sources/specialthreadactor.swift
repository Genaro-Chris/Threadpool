import Foundation

actor SpecialThreadActor {

    private let executor = MultiThreadedSerialJobExecutor()

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: executor)
    }

    private var count_ = 0

    func increment(by: Int) {
        count_ += by
    }

    var count: Int {
        count_
    }
}
