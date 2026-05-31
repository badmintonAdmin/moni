import SwiftUI

/// Drill-down screen for one metric: big current value, a history graph, and
/// (for CPU/RAM) a tappable list of top processes by that metric.
struct MetricDetailView: View {
    @Bindable var model: MetricsModel
    let kind: MetricKind
    var push: (PanelRoute) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(currentValue)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                MetricChart(points: series, tint: kind.tint, maxY: kind.maxY, unitSuffix: kind.unit)

                if kind.hasProcesses {
                    Text("TOP PROCESSES")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.top, 2)

                    PanelGroup {
                        VStack(spacing: 0) {
                            let top = topProcesses
                            if top.isEmpty {
                                Text("collecting…")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10)
                            } else {
                                ForEach(Array(top.enumerated()), id: \.element.id) { index, p in
                                    Button {
                                        push(.process(ProcRoute(pid: p.pid, name: p.name, cpu: p.cpu)))
                                    } label: {
                                        ProcessRow(name: p.name, valueText: valueText(p), tint: kind.tint)
                                    }
                                    .buttonStyle(.plain)
                                    .hoverRow()
                                    if index < top.count - 1 {
                                        Divider().overlay(Color.white.opacity(0.06))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .onAppear { if kind.hasProcesses { model.processViewActive = true } }
        .onDisappear { model.processViewActive = false }
    }

    // MARK: Data

    private var currentValue: String {
        switch kind {
        case .cpu:  return Format.percent(model.cpuUsage)
        case .ram:  return Format.percent(model.memUsed)
        case .temp: return model.tempC.map { "\(Int($0.rounded()))°" } ?? "—"
        }
    }

    private var series: [HistoryPoint] {
        switch kind {
        case .cpu:  return model.cpuSeries
        case .ram:  return model.ramSeries
        case .temp: return model.tempSeries
        }
    }

    private var topProcesses: [ProcSample] {
        let sorted: [ProcSample]
        switch kind {
        case .cpu:  sorted = model.processes.sorted { $0.cpu > $1.cpu }
        case .ram:  sorted = model.processes.sorted { $0.rss > $1.rss }
        case .temp: sorted = []
        }
        return Array(sorted.prefix(8))
    }

    private func valueText(_ p: ProcSample) -> String {
        kind == .ram ? Format.bytes(p.rss) : "\(Int(p.cpu.rounded()))%"
    }
}
