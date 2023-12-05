import ConcurrencyPrimitives

extension ThreadSafeQueue where Element == QueueOperation {

    func next() -> Element? {
        guard let value = <-self else {
            return .notYet
        }
        return value
    }
}
