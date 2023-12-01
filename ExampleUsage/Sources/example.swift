import ConcurrencyPrimitives
import Foundation
import ThreadPool

@main
enum Program {
    static func main() async throws {
        print("Hello, world!")

        let specialActorInstance = SpecialActor()

        let specialInstance = SpecialThreadActor()

        let priorities = [TaskPriority.background, .high, .medium, .low, .userInitiated, .utility]

        var counter = 0

        let rwLock = RWLock()

        let pool = ThreadPool(count: 4)

        for i in 1 ... 10 {
            pool?.submit {
                rwLock.whileWriteLocked {
                    counter += i
                }
            }
        }

        Thread.sleep(forTimeInterval: 1)

        rwLock.whileReadLocked {
            print("Counter \(counter)")
        }

        await withDiscardingTaskGroup { group in
            for priority in priorities {
                group.addTask(priority: priority) {
                    Once.runOnce {
                        print("\(Task.currentPriority)")
                    }
                    await specialActorInstance.increment(by: Int.random(in: 1 ... 10))
                    await specialInstance.increment(by: Int.random(in: 1 ... 10))
                }
            }
        }

        print("Count for \(type(of: specialActorInstance)): \(await specialActorInstance.count)")
        print("Count for \(type(of: specialInstance)): \(await specialInstance.count)")

    }
}