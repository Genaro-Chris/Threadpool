public enum Timeout {
    case nanoseconds(Int)
    case microseconds(Int)
    case milliseconds(Int)
    case seconds(Int)
}

extension Timeout {

    var timeoutIntoNS: Int64 {
        switch self {
        case let .nanoseconds(time): return Int64(time)

        case let .microseconds(time): return Int64(time * 1_000)

        case let .milliseconds(time): return Int64(time * 1_000_000)

        case let .seconds(time): return Int64(time * 1_000_000_000)

        }
    }
}

extension Timeout {

    var time: Int {
        switch self {
        case let .nanoseconds(time): return time

        case let .microseconds(time): return time

        case let .milliseconds(time): return time

        case let .seconds(time): return time

        }
    }
}
