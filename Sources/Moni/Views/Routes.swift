import SwiftUI

/// Which metric a detail screen shows.
enum MetricKind: Hashable {
    case cpu, ram, temp

    var title: String {
        switch self {
        case .cpu: return "CPU"
        case .ram: return "RAM"
        case .temp: return "CPU Temperature"
        }
    }

    var tint: Color {
        switch self {
        case .cpu: return Theme.accentCyan
        case .ram: return Theme.accentGreen
        case .temp: return Theme.accentOrange
        }
    }

    /// Y-axis range and unit for the history chart.
    var maxY: Double { self == .temp ? 100 : 100 }
    var unit: String { self == .temp ? "°" : "%" }

    /// Whether this metric lists top processes.
    var hasProcesses: Bool { self != .temp }
}

/// Navigation target for a process detail screen.
struct ProcRoute: Hashable {
    let pid: Int32
    let name: String
    let cpu: Double
}

/// Navigation target for the disk screen.
struct DiskRoute: Hashable {}

/// One screen in Moni's lightweight in-popover navigation (no NavigationStack,
/// so there is no system title bar). `nil`/empty stack means the overview.
enum PanelRoute: Hashable {
    case metric(MetricKind)
    case process(ProcRoute)
    case disk

    var title: String {
        switch self {
        case .metric(let kind): return kind.title
        case .process(let route): return route.name
        case .disk: return "Disk"
        }
    }
}
