@usableFromInline final class Storage<Element> {

    @usableFromInline var innerBuffer: ContiguousArray<Element> = []

    @usableFromInline var closed = false

    @usableFromInline var ready = false

    @usableFromInline var readyToReceive: Bool {
        switch (ready, closed) {
        case (true, true): true
        case (true, false): true
        case (false, true): true
        case (false, false): false
        }
    }

}

extension Storage {

    @usableFromInline var buffer: ContiguousArray<Element> {
        _read { yield innerBuffer }
        _modify { yield &innerBuffer }
    }

    var count: Int {
        buffer.count
    }

    @inlinable
    var isEmpty: Bool {
        buffer.isEmpty
    }

    @inlinable
    func enqueue(_ item: Element) {
        buffer.append(item)
    }

    @inlinable
    func dequeue() -> Element? {
        guard !buffer.isEmpty else {
            return nil
        }
        return buffer.removeFirst()
    }

    func clear() {
        buffer.removeAll()
    }
}
