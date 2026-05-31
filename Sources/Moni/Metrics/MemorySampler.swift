import Darwin

struct MemorySample {
    var usedFraction: Double    // 0...1 — "memory used" comparable to Activity Monitor
    var availableBytes: UInt64  // total - used (what the user can actually still use)
    var totalBytes: UInt64
}

/// Reads physical memory usage from Mach VM statistics. No privileges required.
struct MemorySampler {
    let totalBytes: UInt64 = {
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        return size
    }()

    private let pageSize: UInt64 = {
        var size: vm_size_t = 0
        host_page_size(mach_host_self(), &size)
        return UInt64(size)
    }()

    func sample() -> MemorySample? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS, totalBytes > 0 else { return nil }

        let active     = UInt64(stats.active_count)    * pageSize
        let wired      = UInt64(stats.wire_count)      * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize

        // Matches Activity Monitor's "Memory Used": app (active) + wired + compressed.
        // Inactive/file-backed pages are reclaimable, so they count as available —
        // that is why strict "free pages" looks tiny while plenty is actually usable.
        let used = min(active + wired + compressed, totalBytes)
        let usedFraction = min(max(Double(used) / Double(totalBytes), 0), 1)
        let available = totalBytes - used

        return MemorySample(usedFraction: usedFraction, availableBytes: available, totalBytes: totalBytes)
    }
}
