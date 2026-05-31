import Foundation
import Observation
import QuartzCore

/// One timestamped point for a history graph.
struct HistoryPoint: Identifiable {
    let t: Date
    let v: Double
    var id: Double { t.timeIntervalSinceReferenceDate }
}

/// Central metrics store.
///
/// Two cadences:
///  - A slow `historyTimer` (~5s) runs ALWAYS (even with the popover closed) and
///    records CPU% and RAM into ring buffers, so the history graphs are useful
///    the moment you open them. Cost is negligible (two mach calls per 5s).
///  - The fast `timer` (~1.5s) runs only while the popover is open and drives the
///    live rings/activity, temperature, and — when a process screen is open — the
///    top-processes list.
@Observable
@MainActor
final class MetricsModel {
    // Live values (kept across open/close so the panel shows instantly).
    var cpuUsage: Double = 0           // 0...1
    var memUsed: Double = 0            // 0...1
    var memAvailableBytes: UInt64 = 0
    var memTotalBytes: UInt64 = 0
    var tempC: Double? = nil
    var thermalLabel: String = "—"
    var io = IORates()

    // Drill-down data.
    var processes: [ProcSample] = []   // refreshed only while a process screen is open
    var volumes: [VolumeInfo] = []     // refreshed when the disk screen appears

    // History (newest last).
    private(set) var cpuSeries: [HistoryPoint] = []
    private(set) var ramSeries: [HistoryPoint] = []
    private(set) var tempSeries: [HistoryPoint] = []
    static let seriesLength = 360      // ~30 min at 5s

    let coreCount: Int = {
        var n: Int32 = 0
        var len = MemoryLayout<Int32>.size
        sysctlbyname("hw.logicalcpu", &n, &len, nil, 0)
        return Int(n)
    }()

    /// Set by the process detail screens so the fast timer also samples processes.
    var processViewActive = false {
        didSet {
            guard processViewActive, !oldValue else { return }
            processes = processSampler.sample()   // baseline; %s fill in next tick
        }
    }

    private let liveInterval: TimeInterval = 1.5
    private let historyInterval: TimeInterval = 5

    private var cpuSampler = CPUSampler()
    private var historyCpuSampler = CPUSampler()   // separate delta state from live
    private let memSampler = MemorySampler()
    private let tempSampler = TempSampler()
    private let ioSampler = IOSampler()
    private let processSampler = ProcessSampler()

    private var timer: Timer?
    private var historyTimer: Timer?
    private var lastTick: CFTimeInterval = 0

    init() {
        memTotalBytes = memSampler.totalBytes
        startHistory()
    }

    // MARK: Live timer (popover open)

    func start() {
        guard timer == nil else { return }
        lastTick = CACurrentMediaTime()
        tick()
        let t = Timer(timeInterval: liveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = max(now - lastTick, 0.001)
        lastTick = now

        if let cpu = cpuSampler.sample() { cpuUsage = cpu }
        if let mem = memSampler.sample() {
            memUsed = mem.usedFraction
            memAvailableBytes = mem.availableBytes
            memTotalBytes = mem.totalBytes
        }
        tempC = tempSampler.sample()
        thermalLabel = Self.thermalWord(ProcessInfo.processInfo.thermalState)
        if let t = tempC { push(&tempSeries, HistoryPoint(t: Date(), v: t)) }

        io = ioSampler.sample(interval: dt)

        if processViewActive {
            processes = processSampler.sample()
        }
    }

    // MARK: History timer (always on)

    private func startHistory() {
        guard historyTimer == nil else { return }
        sampleHistory()
        let t = Timer(timeInterval: historyInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sampleHistory() }
        }
        RunLoop.main.add(t, forMode: .common)
        historyTimer = t
    }

    private func sampleHistory() {
        let now = Date()
        if let cpu = historyCpuSampler.sample() { push(&cpuSeries, HistoryPoint(t: now, v: cpu * 100)) }
        if let mem = memSampler.sample() { push(&ramSeries, HistoryPoint(t: now, v: mem.usedFraction * 100)) }
    }

    // MARK: Disk

    func refreshVolumes() {
        volumes = DiskSpaceSampler.sample()
    }

    // MARK: Helpers

    private static func thermalWord(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:  return "Normal"
        case .fair:     return "Fair"
        case .serious:  return "Hot"
        case .critical: return "Critical"
        @unknown default: return "—"
        }
    }

    private func push(_ buffer: inout [HistoryPoint], _ point: HistoryPoint) {
        buffer.append(point)
        if buffer.count > Self.seriesLength {
            buffer.removeFirst(buffer.count - Self.seriesLength)
        }
    }
}
