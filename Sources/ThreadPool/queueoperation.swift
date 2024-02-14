enum QueueOperation {
    case wait
    case ready(element: () -> Void)
}
