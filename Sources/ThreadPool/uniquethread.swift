import ConcurrencyPrimitives
import Foundation

public typealias TaskItem = () -> Void

public typealias SendableTaskItem = @Sendable () -> Void

class UniqueThread: Thread {

    let condition = Condition()

    let mutex = Mutex(type: .normal)

    let queue = ThreadSafeQueue<TaskItem>()

    func submit(_ body: @escaping TaskItem) {
        mutex.whileLocked {
            queue <- body
            condition.signal()
        }
    }

    fileprivate func dequeue() -> TaskItem? {
        return mutex.whileLocked {
            condition.wait(mutex: mutex, condition: !queue.isEmpty)
            guard !queue.isEmpty else { return nil }
            return queue.dequeue()
        }
    }

    override func main() {
        while !self.isCancelled {
            if let work = self.dequeue() {
                work()
            }
        }
    }
}
