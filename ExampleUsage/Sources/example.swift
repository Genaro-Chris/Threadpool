import ConcurrencyPrimitives
import Foundation
import ThreadPool

@main
enum Program {
    static func main() async throws {

        /* print("Hello, world!")

        let specialActorInstance = SpecialActor()

        let specialInstance = SpecialThreadActor()

        let priorities = [TaskPriority.background, .high, .medium, .low, .userInitiated, .utility]

        var counter = 0

        let rwLock = RWLock()

        let pool = ThreadPool(count: 4)

        for index in 1...10 {
            pool?.submit {
                rwLock.whileWriteLocked {
                    counter += index
                }
            }
        }

        Thread.sleep(forTimeInterval: 0.000002)

        rwLock.whileReadLocked {
            print("Counter \(counter)")
        }

        await withDiscardingTaskGroup { group in
            for priority in priorities {
                group.addTask(priority: priority) {
                    async let _ = specialActorInstance.increment(by: Int.random(in: 1...10))
                    async let _ = specialInstance.increment(by: Int.random(in: 1...10))
                    Once.runOnce {
                        print("\(Task.currentPriority)")
                    }
                }
            }
        }

        print("Count for \(type(of: specialActorInstance)): \(await specialActorInstance.count)")
        print("Count for \(type(of: specialInstance)): \(await specialInstance.count)") */

        try await Task.sleep(for: .seconds(1.2))

        let mutex = Mutex(type: .error)
        let condition = Condition()
        let now = ContinuousClock.continuous.measure {
            mutex.whileLocked {
                condition.wait(mutex: mutex, forTimeInterval: .nanoseconds(1))
            }
        }
        print("It took \(now) seconds")
    }
}
