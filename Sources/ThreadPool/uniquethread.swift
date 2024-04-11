import ConcurrencyPrimitives

import class Foundation.Thread

public typealias TaskItem = () -> Void

public typealias SendableTaskItem = @Sendable () -> Void

class UniqueThread: Thread {

    let latch = Latch(count: 1)

    let queue = UnboundedChannel<TaskItem>()

    func submit(_ body: @escaping TaskItem) {
        _ = queue.enqueue(body)
    }

    override func main() {
        while !self.isCancelled {
            for work in queue {
                work()
            }
        }
        latch?.decrementAlone()
    }

    func join() {
        latch?.waitForAll()
    }

    override func cancel() {
        queue.close()
        queue.clear()
        super.cancel()
    }
}
