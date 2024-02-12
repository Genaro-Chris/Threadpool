import Foundation

actor SpecialActor {

    private let executor = SerialJobExecutor()

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: executor)
    }

    func increment(by value: Int) {
        count += value
    }

    init() {
        count = 0
    }

    var count: Int
}
