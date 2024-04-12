public final class _Storage<Element> {

    var innerBuffer: ContiguousArray<Element> = []

    var closed = false

    var ready = false

    var readyToReceive: Bool {
        switch (ready, closed) {
        case (true, true): return true
        case (true, false): return true
        case (false, true): return true
        case (false, false): return false
        }
    }

}

extension _Storage {

    var buffer: ContiguousArray<Element> {
        _read { yield innerBuffer }
        _modify { yield &innerBuffer }
    }

    var count: Int {
        buffer.count
    }

    var isEmpty: Bool {
        buffer.isEmpty
    }

    func enqueue(_ item: Element) {
        buffer.append(item)
    }

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
