import Foundation

extension ThreadSafeQueue<QueueOperation>: Sequence, IteratorProtocol {

   public func next() -> QueueOperation? {
        guard let value = <-self else {
            return .notYet
        }
        return value
    }
}
