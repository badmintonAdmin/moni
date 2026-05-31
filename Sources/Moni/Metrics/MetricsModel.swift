import Foundation
import Observation
import QuartzCore

/// Central metrics store. Polling runs ONLY while the panel is visible:
/// `start()` is called from the panel's `.onAppear`, `stop()` from
/// `.onDisappear`. When the panel is closed the app uses ~0% CPU.
@Observable
@MainActor
final class MetricsModel {
    // Latest values (kept across open/close so the panel shows instantly).
    var cpuUsage: Double = 0           // 0...1
    var memUsed: Double = 0            // 0...1
    var memAvailableBytes: UInt64 = 0  // total - used (usable memory)
    var memTotalBytes: UInt64 = 0
    var tempC: Double? = nil           // nil => sensors unavailable
    var thermalLabel: String = "—"     // Normal / Fair / Hot / Critical
    var io = IORates()

    let coreCount: Int = {
        var n: Int32 = 0
        var len = MemoryLayout<Int32>.size
        sysctlbyname("hw.logicalcpu", &n, &len, nil, 0)
        return Int(n)
    }()

    // Short history for sparklines (newest last).
    private(set) var cpuHistory: [Double] = []
    private(set) var netHistory: [Double] = []
    static let historyLength = 40

    private let interval: TimeInterval = 1.5

    private var cpuSampler = CPUSampler()
    private let memSampler = MemorySampler()
    private let tempSampler = TempSampler()
    private let ioSampler = IOSampler()

    private var timer: Timer?
    private var lastTick: CFTimeInterval = 0

    init() {
        memTotalBytes = memSampler.totalBytes
    }

    func start() {
        guard timer == nil else { return }
        lastTick = CACurrentMediaTime()
        tick()   // immediate first sample so the panel isn't empty
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        // .common so it keeps firing while the menu/popover tracks mouse events.
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

        if let cpu = cpuSampler.sample() {
            cpuUsage = cpu
            push(&cpuHistory, cpu)
        }
        if let mem = memSampler.sample() {
            memUsed = mem.usedFraction
            memAvailableBytes = mem.availableBytes
            memTotalBytes = mem.totalBytes
        }
        tempC = tempSampler.sample()
        thermalLabel = Self.thermalWord(ProcessInfo.processInfo.thermalState)

        io = ioSampler.sample(interval: dt)
        let netTotal = io.netInPerSec + io.netOutPerSec
        push(&netHistory, netTotal)
    }

    private static func thermalWord(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:  return "Normal"
        case .fair:     return "Fair"
        case .serious:  return "Hot"
        case .critical: return "Critical"
        @unknown default: return "—"
        }
    }

    private func push(_ buffer: inout [Double], _ value: Double) {
        buffer.append(value)
        if buffer.count > Self.historyLength {
            buffer.removeFirst(buffer.count - Self.historyLength)
        }
    }
}
