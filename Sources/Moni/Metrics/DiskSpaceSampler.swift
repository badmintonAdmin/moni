import Foundation

/// Free/used space for one mounted volume.
struct VolumeInfo: Identifiable, Hashable {
    let name: String
    let total: UInt64
    let available: UInt64   // "important usage" available — matches Finder
    let isInternal: Bool

    var id: String { "\(name)-\(total)" }
    var usedFraction: Double { total > 0 ? Double(total - min(available, total)) / Double(total) : 0 }
}

/// Lists mounted volumes with capacity info. No root, cheap; changes slowly so
/// it is sampled on demand (when the disk screen appears), not on the timer.
enum DiskSpaceSampler {
    private static let keys: [URLResourceKey] = [
        .volumeNameKey,
        .volumeTotalCapacityKey,
        .volumeAvailableCapacityForImportantUsageKey,
        .volumeIsInternalKey,
    ]

    static func sample() -> [VolumeInfo] {
        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else { return [] }

        var volumes: [VolumeInfo] = []
        for url in urls {
            guard let v = try? url.resourceValues(forKeys: Set(keys)),
                  let total = v.volumeTotalCapacity, total > 0 else { continue }

            let available = v.volumeAvailableCapacityForImportantUsage ?? 0
            volumes.append(VolumeInfo(
                name: v.volumeName ?? url.lastPathComponent,
                total: UInt64(total),
                available: UInt64(max(available, 0)),
                isInternal: v.volumeIsInternal ?? false
            ))
        }

        // Internal volumes first, then largest first.
        return volumes.sorted {
            $0.isInternal != $1.isInternal ? $0.isInternal && !$1.isInternal : $0.total > $1.total
        }
    }
}
