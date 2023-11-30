import Foundation

print("Hello, world!")

let specialActorInstance = SpecialActor()


await withDiscardingTaskGroup { group in 
    for i in 1...10 {
        group.addTask {
            await specialActorInstance.increment(by: i)
        }
    }
}

print("Count is \(await specialActorInstance.count)")
