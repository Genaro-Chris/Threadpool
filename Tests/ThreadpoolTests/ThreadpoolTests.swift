import XCTest

@testable import ConcurrencyPrimitives
@testable import ThreadPool

final class ThreadpoolTests: XCTestCase {

    func testConditionWithSignal() {
        let condition = Condition()
        let lock = Mutex(type: .normal)
        var total = 0
        let threadHanddles = (1 ... 10).map { i in
            Thread {
                lock.whileLocked {
                    total += i
                }
                condition.wait(mutex: lock)
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
        let lock = Mutex(type: .normal)
        var total = 0
        let threadHanddles = (1 ... 10).map { i in
            Thread {
                lock.whileLocked {
                    total += i
                }
                condition.wait(mutex: lock)
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
        let lock = Mutex(type: .normal)
        let total = 0
        let threadHanddles = (1 ... 5).map { i in
            Thread {
                condition.wait(mutex: lock, forTimeInterval: 2)
                if i % 5 == 0 {
                    condition.signal()
                }

            }
        }
        threadHanddles.forEach { $0.start() }

        condition.broadcast()

        condition.wait(mutex: lock, forTimeInterval: 4)

        threadHanddles.forEach { $0.cancel() }
        lock.whileLocked {
            XCTAssertEqual(total, 0)
        }
    }

    func testQueue() {
        let queue = ThreadSafeQueue<Int>(order: .firstOut)
        DispatchQueue.concurrentPerform(iterations: 11) { value in
            queue <- value
        }

        var total = 0
        while let value = <-queue {
            total += value
        }

        XCTAssertEqual(total, 55)
    }

    func testThreadBlocker() {
        let queue = Barrier(value: 3)
        XCTAssertNotNil(queue)
        var total = 0
        let mutex = Mutex()
        for i in 1 ... 10 {
            Thread {
                queue?.arriveAndWait()
                mutex.whileLocked {
                    total += i
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
        XCTAssertNil(Barrier(value: 0))
        XCTAssertNil(Latch(value: 0))
    }

    func testThreadBlockerWithLatch() {
        let queue = Latch(value: 3)
        XCTAssertNotNil(queue)
        let mutex = Mutex(type: .recursive)
        var total = 0
        for i in 1 ... 10 {
            Thread {
                if i % 3 == 0 {
                    mutex.whileLocked {
                        total += i
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

    func testOnce() {
        var total = 0
        for _ in 1 ... 10 {
            Thread {
                Once.runOnce {
                    total += 1
                }
            }.start()
        }
        XCTAssertEqual(total, 1)
    }

    func testQueueReversed() {
        let queue = ThreadSafeQueue<Int>(order: .lastOut)
        DispatchQueue.concurrentPerform(iterations: 11) { value in
            queue <- value
        }

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
            for i in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += i
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
            for i in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += i
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
            for i in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += i
                    }
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
            (1 ... 5).forEach { i in
                pool?.submit {
                    rwLock.whileWriteLocked {
                        counter += i
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
            for i in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += i
                    }
                    Thread.sleep(forTimeInterval: 2)
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
            let pool = ThreadPool(count: 5, waitType: .cancelAll)
            XCTAssertNotNil(pool)
            let lock = Mutex()
            for i in 1 ... 10 {
                pool?.submit {
                    lock.whileLocked {
                        counter += i
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
            let lock = Mutex()
            for _ in 1 ... 10 {
                pool.submit {
                    lock.whileLocked {
                        checks.append(Thread.current.description)
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
            let pool = ThreadPool(count: 5, waitType: .cancelAll)!
            let lock = Mutex()

            for i in 1 ... 10 {
                pool.submit {
                    lock.whileLocked {
                        counter += i
                    }
                    Thread.sleep(forTimeInterval: 1)
                }
            }
        }

        XCTAssertNotEqual(counter, 55)
    }
}
