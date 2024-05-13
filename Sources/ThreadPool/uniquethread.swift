import ConcurrencyPrimitives

import class Foundation.Thread

public typealias TaskItem = () -> Void

public typealias SendableTaskItem = @Sendable () -> Void

class UniqueThread: Thread {

    let queue = Channel<TaskItem>()

    func submit(_ body: @escaping TaskItem) {
        _ = queue.enqueue(body)
    }

    override func main() {
        while !self.isCancelled {
            if let work = queue.dequeue() {
                work()
            }
        }
    }

    override func cancel() {
        queue.close()
        queue.clear()
        super.cancel()
    }
}
