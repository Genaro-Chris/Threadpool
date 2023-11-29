///
public enum QueueOperation {
    case notYet
    case wait
    case ready(element: () -> Void)
}
