#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#else
    #error("Unable to identify your underlying C library.")
#endif

func getTimeSpec(with timeout: Timeout) -> timespec {
    // converts seconds into nanoseconds
    let nsecsPerSec: Int64 = 1_000_000_000

    #if canImport(Darwin) || os(macOS)

        var currentTime: timeval = timeval()
        // get the current time
        gettimeofday(&currentTime, nil)

        let allNSecs: Int64 = timeout.timeoutIntoNS + Int64(currentTime.tv_usec) * 1000

        // calculate the timespec from the argument passed
        let timeoutAbs: timespec = timespec(
            tv_sec: currentTime.tv_sec + Int((allNSecs / nsecsPerSec)),
            tv_nsec: Int(allNSecs % nsecsPerSec))

        assert(timeoutAbs.tv_nsec >= 0 && timeoutAbs.tv_nsec < Int(nsecsPerSec))
        assert(timeoutAbs.tv_sec >= currentTime.tv_sec)

    #elseif os(Linux)

        // get the current time
        var currentTime: timespec = timespec(tv_sec: 0, tv_nsec: 0)
        clock_gettime(CLOCK_REALTIME, &currentTime)

        // calculate the timespec from the argument passed 
        let allNSecs: Int64 = (timeout.timeoutIntoNS + Int64(currentTime.tv_nsec)) / nsecsPerSec
        let timeoutAbs: timespec = timespec(
            tv_sec: currentTime.tv_sec + Int(allNSecs / nsecsPerSec),
            tv_nsec: currentTime.tv_nsec + Int(allNSecs % nsecsPerSec)
        )

        assert(timeoutAbs.tv_nsec >= 0 && timeoutAbs.tv_nsec < Int(nsecsPerSec))
        assert(timeoutAbs.tv_sec >= currentTime.tv_sec)

    #endif

    return timeoutAbs
}
