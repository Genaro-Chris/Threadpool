import XCTest

@testable import ConcurrencyPrimitives
@testable import ThreadPool

final class ThreadpoolTests: XCTestCase {

    func testConditionWithSignal() {
        let condition = Condition()
        let lock = Mutex(type: .normal)
        var total = 0
        let threadHanddles = (1 ... 10).map { index in
            Thread {
                lock.whileLocked {
                    total += index
                    condition.wait(mutex: lock)
                }
            }
        }
        threadHanddles.forEach { $0.start() }

        Thread.sleep(forTimeInterval: 1)

        (1 ... 10).forEach { _ in condition.signal() }

        threadHanddles.forEach { $0.cancel() }
        lock.whileLocked {
            XCTAssertEqual(total, 55)
        }
    }

    func testConditionWithBroadcast() {
        let condition = Condition()
        let lock = Mutex()
        var total = 0
        let threadHanddles = (1 ... 10).map { index in
            Thread {
                lock.whileLocked {
                    total += index
                    condition.wait(mutex: lock)
                }
            }
        }
        threadHanddles.forEach { $0.start() }

        Thread.sleep(forTimeInterval: 1)

        condition.broadcast()

        threadHanddles.forEach { $0.cancel() }
        lock.whileLocked {
            XCTAssertEqual(total, 55)
        }
    }

    func testConditionSleepWithBroadcast() {
        let condition = Condition()
        let lock = Mutex()
        let total = 0
        let threadHandles = (1 ... 5).map { index in
            Thread {
                defer {
                    print("Thread \(index) done")
                }
                lock.whileLocked {
                    condition.wait(mutex: lock, forTimeInterval: .microseconds(200))
                    if index % 5 == 0 {
                        condition.signal()
                    }
                }

            }
        }

        threadHandles.forEach { $0.start() }

        lock.whileLocked {
            condition.wait(mutex: lock, forTimeInterval: .microseconds(400))
        }

        threadHandles.forEach { $0.cancel() }
        lock.whileLocked {
            XCTAssertEqual(total, 0)
        }
    }

    func testQueue() {
        let queue = ThreadSafeQueue<Int>(order: .firstOut)
        let latch = Latch(count: 10)!
        for value in 1 ... 10 {
            Thread {
                queue <- value
                latch.decrementAndWait()
            }.start()
        }
        latch.waitForAll()

        var total = 0
        while let value = <-queue {
            total += value
        }

        XCTAssertEqual(total, 55)
    }

    func testThreadBlocker() {
        let queue = Barrier(count: 3)
        XCTAssertNotNil(queue)
        var total = 0
        let mutex = Mutex()
        for index in 1 ... 10 {
            Thread {
                queue?.arriveAndWait()
                mutex.whileLocked {
                    total += index
                }
            }.start()
        }
        mutex.whileLocked {
            XCTAssertNotEqual(total, 0)
        }
    }

    func testNils() {
        XCTAssertNil(ThreadPool(count: 0))
        XCTAssertNil(ThreadPool(count: 0, waitType: .waitForAll))
        XCTAssertNil(Barrier(count: 0))
        XCTAssertNil(Latch(count: 0))
    }

    func testThreadBlockerWithLatch() {
        let queue = Latch(count: 3)
        XCTAssertNotNil(queue)
        let mutex = Mutex(type: .recursive)
        var total = 0
        for index in 1 ... 10 {
            Thread {
                if index % 3 == 0 {
                    mutex.whileLocked {
                        total += index
                    }
                    queue?.decrementAndWait()
                }
            }.start()
        }
        queue?.waitForAll()
        mutex.whileLocked {
            XCTAssertEqual(total, 18)
        }
    }

    func testMutex() {
        struct Student {
            var age: Int
            var scores: [Int]
        }
        let mutex = Mutex()
        var student = Student(age: 0, scores: [])
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            mutex.whileLocked {
                student.scores.append(index)
                if index == 9 {
                    student.age = 18
                }
            }
        }
        XCTAssertEqual(student.scores.count, 10)
        XCTAssertEqual(student.age, 18)
    }

    func testMutexTimedOut() {
        struct Student {
            var age: Int
            var scores: [Int]
        }
        let mutex = Mutex()
        var student = Student(age: 0, scores: [])
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            mutex.whileLocked {
                student.scores.append(index)
                if index == 9 {
                    student.age = 18
                }
            }
        }

        DispatchQueue.global().async {
            mutex.lock()
            Thread.sleep(forTimeInterval: 10)
        }

        mutex.tryLockUntil(forTimeInterval: .seconds(6))

        XCTAssertEqual(student.scores.count, 10)
        XCTAssertEqual(student.age, 18)
    }

    func testLocked() {
        struct Student {
            var age: Int
            var scores: [Int]
        }
        let student = Locked(Student(age: 0, scores: []))
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            student.updateWhileLocked { student in
                student.scores.append(index)
            }
            if index == 9 {
                student.age = 18
            }
        }
        XCTAssertEqual(student.scores.count, 10)
        XCTAssertEqual(student.age, 18)
    }

    func testLockedWrapper() {
        struct Student {
            var age: Int
            var scores: [Int]
        }
        @Locked var student = Student(age: 0, scores: [])
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            $student.updateWhileLocked { student in
                student.scores.append(index)
                if index == 9 {
                    student.age = 18
                }
            }
        }
        XCTAssertEqual(student.scores.count, 10)
        XCTAssertEqual(student.age, 18)
    }

    func testOnce() {
        var total = 0
        let mutex = Mutex()
        for _ in 1 ... 10 {
            Thread {
                mutex.whileLocked {
                    Once.runOnce {
                        total += 1
                    }
                }
            }.start()
        }
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertEqual(total, 1)
    }

    func testOnceState() {
        var total = 0
        let mutex = Mutex()
        let once = OnceState()
        for _ in 1 ... 10 {
            Thread {
                mutex.whileLocked {
                    once.runOnce {
                        total += 1
                    }
                }
            }.start()
        }
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertEqual(total, 1)
    }

    func testQueueReversed() {
        let queue = ThreadSafeQueue<Int>(order: .lastOut)
        let latch = Latch(count: 10)!
        for value in 1 ... 10 {
            Thread {
                queue <- value
                latch.decrementAndWait()
            }.start()
        }
        latch.waitForAll()
        var total = 0
        while let value = <-queue {
            total += value
        }

        XCTAssertEqual(total, 55)
    }

    func testThreadPool() {
        var counter = 0

        do {
            let pool = ThreadPool(count: 10, waitType: .waitForAll)
            XCTAssertNotNil(pool)
            let lock = Mutex()
            for index in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += index
                    }
                    Thread.sleep(forTimeInterval: 1)
                }
            }
        }

        XCTAssertEqual(counter, 55)
    }

    func testSingleThreadPool() {
        var counter = 0

        do {
            let pool = ThreadPool(count: 1, waitType: .waitForAll)
            XCTAssertNotNil(pool)
            let lock = Mutex()
            for index in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += index
                    }
                }
            }
        }

        XCTAssertEqual(counter, 55)
    }

    func testSingleCancellingThreadPool() {
        var counter = 0

        do {
            let pool = ThreadPool(count: 1, waitType: .cancelAll)
            XCTAssertNotNil(pool)
            let lock = Mutex()
            for index in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += index
                    }
                    Thread.sleep(forTimeInterval: 1)
                }
            }
        }

        XCTAssertNotEqual(counter, 55)
    }

    func testRWLock() {
        let rwLock = RWLock()
        var counter = 0
        do {
            let pool = ThreadPool(count: 3, waitType: .waitForAll)
            (1 ... 5).forEach { index in
                pool?.submit {
                    rwLock.whileWriteLocked {
                        counter += index
                    }
                }
            }
        }
        rwLock.whileReadLocked {
            XCTAssertEqual(counter, 15)
        }
    }

    func testPollingThreadPool() {
        var counter = 0

        do {
            let pool = ThreadPool(count: 5, waitType: .waitForAll)
            XCTAssertNotNil(pool)
            let lock = Mutex()
            for index in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += index
                        print("At \(index)")
                    }
                }
            }

            pool?.poll()

            pool?.submit {
                lock.whileLocked {
                    XCTAssertEqual(counter, 55)
                    counter += 11
                }
            }
        }

        XCTAssertGreaterThan(counter, 55)
    }

    func testThreadPoolCancelAtDeinit() {
        var counter = 0

        do {
            let pool = ThreadPool(count: 3, waitType: .cancelAll)
            XCTAssertNotNil(pool)
            let lock = Mutex()
            for index in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += index
                    }
                    Thread.sleep(forTimeInterval: 2)
                }
            }
        }

        XCTAssertNotEqual(counter, 55)
    }

    func testSingleThread() {
        var checks: [String] = []
        do {
            let pool = SingleThread(waitType: .waitForAll)
            let lock = Mutex(type: .recursive)
            for _ in 1 ... 10 {
                pool.submit {
                    lock.whileLocked {
                        checks.append(Thread.current.description)
                        print(checks.count)
                    }
                }
            }
        }

        if let first = checks.first {
            XCTAssert(checks.allSatisfy { $0 == first })
        }
        XCTAssertEqual(checks.count, 10)
    }

    func testSingleThreadCancelAtDeinit() {
        var checks: [String] = []
        do {
            let pool = SingleThread(waitType: .cancelAll)
            let lock = Mutex()

            for _ in 1 ... 10 {
                pool.submit {
                    lock.whileLocked {
                        checks.append(Thread.current.description)
                        Thread.sleep(forTimeInterval: 1)
                    }
                }
            }
        }
        if let first = checks.first {
            XCTAssert(checks.allSatisfy { $0 == first })
        }
        XCTAssertNotEqual(checks.count, 10)
    }

    func testSingleThreadCancelAtDeinitButPoll() {
        var checks: [String] = []
        do {
            let pool = SingleThread(waitType: .cancelAll)
            let lock = Mutex()

            for _ in 1 ... 10 {
                pool.submit {
                    lock.whileLocked {
                        checks.append(Thread.current.description)
                    }
                }
            }
            pool.poll()
        }

        if let first = checks.first {
            XCTAssert(checks.allSatisfy { $0 == first })
        }
        XCTAssertEqual(checks.count, 10)
    }

    func testThreadPoolDontWaitAtDeinit() {
        var counter = 0
        do {
            let pool = ThreadPool(count: 3, waitType: .cancelAll)!
            let lock = Mutex()
            for index in 1 ... 10 {
                pool.submit {
                    lock.whileLocked {
                        counter += index
                    }
                    Thread.sleep(forTimeInterval: 1)
                }
            }
        }

        XCTAssertNotEqual(counter, 55)
    }

    func testSemaphore() {
        let semaphore = LockBasedSemaphore(size: 10)
        for _ in 1 ... 10 {
            DispatchQueue.global().async {
                defer { semaphore.decrement() }
                Thread.sleep(forTimeInterval: Double.random(in: 1 ... 5))
            }
        }

        semaphore.waitForZero()
        XCTAssertEqual(semaphore.count, 0)
    }
}
