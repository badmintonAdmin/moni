import Darwin
import Foundation
import IOKit

struct IORates {
    var netInPerSec: Double = 0
    var netOutPerSec: Double = 0
    var diskReadPerSec: Double = 0
    var diskWritePerSec: Double = 0
}

/// Samples cumulative network and disk byte counters and converts successive
/// readings into per-second rates. No privileges required.
final class IOSampler {
    private var prevNetIn: UInt64 = 0
    private var prevNetOut: UInt64 = 0
    private var prevDiskRead: UInt64 = 0
    private var prevDiskWrite: UInt64 = 0
    private var hasBaseline = false

    /// `interval` is the seconds elapsed since the previous sample.
    func sample(interval: Double) -> IORates {
        let (netIn, netOut) = networkCounters()
        let (diskRead, diskWrite) = diskCounters()

        defer {
            prevNetIn = netIn; prevNetOut = netOut
            prevDiskRead = diskRead; prevDiskWrite = diskWrite
            hasBaseline = true
        }

        guard hasBaseline, interval > 0 else { return IORates() }

        return IORates(
            netInPerSec:    Double(netIn >= prevNetIn ? netIn - prevNetIn : 0) / interval,
            netOutPerSec:   Double(netOut >= prevNetOut ? netOut - prevNetOut : 0) / interval,
            diskReadPerSec: Double(diskRead >= prevDiskRead ? diskRead - prevDiskRead : 0) / interval,
            diskWritePerSec: Double(diskWrite >= prevDiskWrite ? diskWrite - prevDiskWrite : 0) / interval
        )
    }

    // MARK: - Network (getifaddrs, AF_LINK if_data counters)

    private func networkCounters() -> (UInt64, UInt64) {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0, let first = addrs else { return (0, 0) }
        defer { freeifaddrs(addrs) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var ptr: UnsafeMutablePointer<ifaddrs>? = first

        while let cur = ptr {
            defer { ptr = cur.pointee.ifa_next }
            guard let sa = cur.pointee.ifa_addr, sa.pointee.sa_family == UInt8(AF_LINK),
                  let dataPtr = cur.pointee.ifa_data else { continue }

            let name = String(cString: cur.pointee.ifa_name)
            if name.hasPrefix("lo") { continue }   // skip loopback

            let data = dataPtr.assumingMemoryBound(to: if_data.self).pointee
            totalIn  += UInt64(data.ifi_ibytes)
            totalOut += UInt64(data.ifi_obytes)
        }
        return (totalIn, totalOut)
    }

    // MARK: - Disk (IOBlockStorageDriver Statistics)

    private func diskCounters() -> (UInt64, UInt64) {
        var iterator: io_iterator_t = 0
        guard let matching = IOServiceMatching("IOBlockStorageDriver"),
              IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS
        else { return (0, 0) }
        defer { IOObjectRelease(iterator) }

        var read: UInt64 = 0
        var write: UInt64 = 0

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }

            guard let props = copyProperties(service),
                  let stats = props["Statistics"] as? [String: Any] else { continue }

            read  += (stats["Bytes (Read)"]  as? NSNumber)?.uint64Value ?? 0
            write += (stats["Bytes (Write)"] as? NSNumber)?.uint64Value ?? 0
        }
        return (read, write)
    }

    private func copyProperties(_ service: io_object_t) -> [String: Any]? {
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any]
        else { return nil }
        return dict
    }
}
