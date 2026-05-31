import Darwin
import Foundation
import QuartzCore

/// One process row: instantaneous CPU% (per-core, may exceed 100 for
/// multithreaded processes, like Activity Monitor) and resident memory.
struct ProcSample: Identifiable, Hashable {
    let pid: Int32
    let name: String
    let cpu: Double      // percent
    let rss: UInt64      // resident bytes
    let threads: Int
    var id: Int32 { pid }
}

/// Full detail for one process (queried lazily when its detail screen opens).
struct ProcDetail {
    let pid: Int32
    let name: String
    let path: String
    let parentPID: Int32
    let cpu: Double
    let rss: UInt64
    let threads: Int
}

/// Enumerates processes via libproc and computes per-process CPU% by diffing
/// cumulative CPU time between samples. No root required — but unprivileged it
/// mainly sees the current user's processes (root/system procs return EPERM).
final class ProcessSampler {
    private var prevCPU: [Int32: UInt64] = [:]   // pid -> cumulative CPU ns
    private var prevWall: CFTimeInterval = 0

    func sample() -> [ProcSample] {
        let now = CACurrentMediaTime()
        let firstRun = prevWall == 0
        let dtNs = max(now - prevWall, 0.0001) * 1_000_000_000
        prevWall = now

        guard let pids = listPIDs() else { return [] }

        var out: [ProcSample] = []
        out.reserveCapacity(pids.count)
        var nextPrev: [Int32: UInt64] = [:]
        nextPrev.reserveCapacity(pids.count)

        for pid in pids where pid > 0 {
            var ti = proc_taskinfo()
            let size = Int32(MemoryLayout<proc_taskinfo>.size)
            // r != size => no permission (EPERM) or process gone; skip quietly.
            guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &ti, size) == size else { continue }

            let totalCPU = ti.pti_total_user + ti.pti_total_system
            nextPrev[pid] = totalCPU

            var cpu = 0.0
            if !firstRun, let prev = prevCPU[pid], totalCPU >= prev {
                cpu = Double(totalCPU - prev) / dtNs * 100.0
            }

            out.append(ProcSample(
                pid: pid,
                name: Self.name(pid),
                cpu: cpu,
                rss: ti.pti_resident_size,
                threads: Int(ti.pti_threadnum)
            ))
        }

        prevCPU = nextPrev
        return out
    }

    /// Re-query everything for a single process for its detail screen.
    static func detail(_ pid: Int32, cpu: Double) -> ProcDetail? {
        var ti = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &ti, size) == size else { return nil }

        var bsd = proc_bsdinfo()
        let bsize = Int32(MemoryLayout<proc_bsdinfo>.size)
        let ppid = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsd, bsize) == bsize ? Int32(bsd.pbi_ppid) : 0

        return ProcDetail(
            pid: pid,
            name: name(pid),
            path: path(pid),
            parentPID: ppid,
            cpu: cpu,
            rss: ti.pti_resident_size,
            threads: Int(ti.pti_threadnum)
        )
    }

    // MARK: - libproc helpers

    private func listPIDs() -> [pid_t]? {
        let needed = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard needed > 0 else { return nil }
        let capacity = Int(needed) / MemoryLayout<pid_t>.stride + 32
        var pids = [pid_t](repeating: 0, count: capacity)
        let got = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(capacity * MemoryLayout<pid_t>.stride))
        guard got > 0 else { return nil }
        let n = Int(got) / MemoryLayout<pid_t>.stride
        return Array(pids.prefix(n))
    }

    static func name(_ pid: pid_t) -> String {
        var buf = [CChar](repeating: 0, count: 256)
        let n = proc_name(pid, &buf, UInt32(buf.count))
        return n > 0 ? cString(buf) : "pid \(pid)"
    }

    static func path(_ pid: pid_t) -> String {
        let maxSize = 4096   // PROC_PIDPATHINFO_MAXSIZE == 4 * MAXPATHLEN
        var buf = [CChar](repeating: 0, count: maxSize)
        let n = proc_pidpath(pid, &buf, UInt32(buf.count))
        return n > 0 ? cString(buf) : ""
    }

    private static func cString(_ buf: [CChar]) -> String {
        buf.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
    }
}
