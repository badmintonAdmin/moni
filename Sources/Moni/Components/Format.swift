import Foundation

enum Format {
    /// Bytes as a compact human string (GB/MB...), e.g. "12.4 GB".
    static func bytes(_ value: UInt64) -> String {
        bytes(Double(value))
    }

    static func bytes(_ value: Double) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var v = value
        var i = 0
        while v >= 1024, i < units.count - 1 { v /= 1024; i += 1 }
        return String(format: v >= 100 || i == 0 ? "%.0f %@" : "%.1f %@", v, units[i])
    }

    /// Per-second byte rate, e.g. "1.2 MB/s".
    static func rate(_ bytesPerSec: Double) -> String {
        bytes(bytesPerSec) + "/s"
    }

    static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }
}
