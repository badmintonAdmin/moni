import Darwin

/// Reads total CPU busy percentage from Mach host processor tick counters.
/// Cheap: one `host_processor_info` call per sample, no privileges required.
struct CPUSampler {
    private var previousTicks: [UInt32] = []   // user, system, idle, nice per core, flattened

    /// Returns busy fraction in 0...1 (averaged across all logical cores),
    /// or nil on the very first sample (no previous baseline yet).
    mutating func sample() -> Double? {
        var cpuCount: natural_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &infoArray,
            &infoCount
        )
        guard result == KERN_SUCCESS, let infoArray else { return nil }
        defer {
            let size = vm_size_t(UInt(infoCount) * UInt(MemoryLayout<integer_t>.stride))
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: infoArray), size)
        }

        // Flatten the per-core ticks into a single array of UInt32.
        let ticks: [UInt32] = (0..<Int(infoCount)).map { UInt32(bitPattern: infoArray[$0]) }

        defer { previousTicks = ticks }
        guard previousTicks.count == ticks.count, !previousTicks.isEmpty else { return nil }

        let states = Int(CPU_STATE_MAX)            // 4: user, system, idle, nice
        var busyDelta: Double = 0
        var totalDelta: Double = 0

        let cores = Int(cpuCount)
        for core in 0..<cores {
            let base = core * states
            guard base + states <= ticks.count else { break }

            let dUser   = delta(ticks[base + Int(CPU_STATE_USER)],   previousTicks[base + Int(CPU_STATE_USER)])
            let dSystem = delta(ticks[base + Int(CPU_STATE_SYSTEM)], previousTicks[base + Int(CPU_STATE_SYSTEM)])
            let dNice   = delta(ticks[base + Int(CPU_STATE_NICE)],   previousTicks[base + Int(CPU_STATE_NICE)])
            let dIdle   = delta(ticks[base + Int(CPU_STATE_IDLE)],   previousTicks[base + Int(CPU_STATE_IDLE)])

            let busy = dUser + dSystem + dNice
            busyDelta += busy
            totalDelta += busy + dIdle
        }

        guard totalDelta > 0 else { return nil }
        return min(max(busyDelta / totalDelta, 0), 1)
    }

    /// Tick counters are monotonic UInt32 that can wrap; clamp negatives to 0.
    private func delta(_ current: UInt32, _ previous: UInt32) -> Double {
        current >= previous ? Double(current - previous) : 0
    }
}
