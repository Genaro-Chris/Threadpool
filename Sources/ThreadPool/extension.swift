import ConcurrencyPrimitives

extension ThreadSafeQueue<QueueOperation> {

    func next() -> QueueOperation? {
        guard let value = <-self else {
            return .notYet
        }
        return value
    }
}
