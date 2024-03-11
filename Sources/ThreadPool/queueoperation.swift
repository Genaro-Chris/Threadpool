enum QueueOperation {
    case wait
    case ready(element: TaskItem)
}
