import XCTest

@testable import ThreadPool

final class ThreadpoolTests: XCTestCase {

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
        for i in 1 ... 10 {
            Thread {
                print("About to block thread \(i)")
                queue?.arriveAndWait()
                total += i
                print("About to release thread \(i)")
                //queue?.arriveAndWait()
            }.start()
        }
        //queue?.waitForAll()
        XCTAssertNotEqual(total, 0)
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
                    mutex.withLock {
                        print("About to block thread \(i)")
                        total += i
                    }
                    queue?.decrementAndWait()
                }
                print("About to release thread \(i)")
            }.start()
        }
        queue?.waitForAll()
        mutex.withLock {
            XCTAssertEqual(total, 18)
        }
    }

    func testOnce() {
        var total = 0
        DispatchQueue.concurrentPerform(iterations: 11) { _ in
            Once.runOnce {
                print("once")
                total += 1
            }
        }
        Once.runOnce {
            print("once")
            total += 1
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
                    lock.withLock {
                        counter += i
                        Thread.sleep(forTimeInterval: 1)
                    }
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
                    lock.withLock {
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
                    lock.withLock {
                        counter += i
                    }
                }
            }
        }

        XCTAssertNotEqual(counter, 55)
    }

    func testPollingThreadPool() {
        var counter = 0

        do {
            let pool = ThreadPool(count: 5, waitType: .waitForAll)
            XCTAssertNotNil(pool)
            let lock = Mutex()
            for i in 1 ... 10 {
                pool?.submit {
                    lock.withLock {
                        counter += i
                        Thread.sleep(forTimeInterval: 2)
                    }
                }
            }

            pool?.poll()

            pool?.submit {
                lock.withLock {
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
                    lock.withLock {
                        counter += i
                        Thread.sleep(forTimeInterval: 2)
                    }
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
                    lock.withLock {
                        append(msg: Thread.current.description, to: &checks)
                    }
                }
            }
        }

        XCTAssert(checks.allEqual())
        XCTAssertEqual(checks.count, 10)
    }

    func testSingleThreadCancelAtDeinit() {
        var checks: [String] = []
        do {
            let pool = SingleThread(waitType: .cancelAll)
            let lock = Mutex()

            for _ in 1 ... 10 {
                pool.submit {
                    lock.withLock {
                        append(msg: Thread.current.description, to: &checks)
                    }
                }
            }
        }
        XCTAssert(checks.allEqual())
        XCTAssertNotEqual(checks.count, 10)
    }

    func testSingleThreadCancelAtDeinitButPoll() {
        var checks: [String] = []
        do {
            let pool = SingleThread(waitType: .cancelAll)
            let lock = Mutex()

            for _ in 1 ... 10 {
                pool.submit {
                    lock.withLock {
                        append(msg: Thread.current.description, to: &checks)
                    }
                }
            }
            pool.poll()
        }
        XCTAssert(checks.allEqual())
        XCTAssertEqual(checks.count, 10)
    }

    func testThreadPoolDontWaitAtDeinit() {
        var counter = 0
        do {
            let pool = ThreadPool(count: 5, waitType: .cancelAll)!
            let lock = Mutex()

            for i in 1 ... 10 {
                pool.submit {
                    lock.withLock {
                        Thread.sleep(forTimeInterval: 1)
                        counter += i
                    }
                }
            }
        }

        XCTAssertNotEqual(counter, 55)
    }

    func testThreadPoolIsNil() {
        let poolOfZero = ThreadPool(count: 0)
        XCTAssertNil(poolOfZero)
    }
}

extension Array where Element: Equatable {

    func allEqual() -> Bool {
        if let firstValue = first {
            return !contains {
                $0 != firstValue
            }
        }
        return true
    }
}

func append(msg: String, to: inout [String]) {
    to.append(msg)
}
