import Foundation

actor SpecialThreadActor {

    private let executor = MultiThreadedSerialJobExecutor()

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: executor)
    }

    init() {
        count = 0
    }

    func increment(by value: Int) {
        count += value
    }

    var count: Int
}
