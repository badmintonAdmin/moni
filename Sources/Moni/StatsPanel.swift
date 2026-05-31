import SwiftUI
import AppKit

/// Root of the popover. Uses a tiny hand-rolled navigation stack (no
/// SwiftUI `NavigationStack`, so there is no system title bar). Tapping
/// CPU/RAM/Temp or the Disk row pushes a detail screen in place; a small
/// chevron returns.
struct StatsPanel: View {
    @Bindable var model: MetricsModel
    @State private var stack: [PanelRoute] = []

    var body: some View {
        ZStack {
            Theme.backdrop

            Group {
                if let top = stack.last {
                    DetailScaffold(title: top.title, onBack: pop) {
                        switch top {
                        case .metric(let kind): MetricDetailView(model: model, kind: kind, push: push)
                        case .process(let route): ProcessDetailView(route: route)
                        case .disk: DiskDetailView(model: model)
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    OverviewView(model: model, push: push)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
        .frame(width: 300, height: 440)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(WindowConfigurator())
        .preferredColorScheme(.dark)
        .onAppear { model.start() }
        .onDisappear { model.stop(); stack.removeAll() }
    }

    private func push(_ route: PanelRoute) {
        withAnimation(.easeInOut(duration: 0.24)) { stack.append(route) }
    }
    private func pop() {
        withAnimation(.easeInOut(duration: 0.24)) { _ = stack.popLast() }
    }
}

/// Wraps a detail screen with a minimal back-chevron header (no gray bar).
struct DetailScaffold<Content: View>: View {
    let title: String
    let onBack: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.accentCyan)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.06), in: .circle)
                }
                .buttonStyle(.plain)
                .hoverLift()

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 4)

            content
        }
    }
}

/// The glanceable root screen: rings + activity + footer.
struct OverviewView: View {
    @Bindable var model: MetricsModel
    var push: (PanelRoute) -> Void
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(spacing: 14) {
            header
            rings
            activity
            Spacer(minLength: 0)
            footer
        }
        .padding(16)
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.accentCyan)
            Text("Moni")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text("\(Format.bytes(model.memTotalBytes)) unified memory")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var rings: some View {
        HStack(spacing: 4) {
            ringButton(.metric(.cpu)) {
                RingStat(title: "CPU",
                         value: Format.percent(model.cpuUsage),
                         subtitle: "\(model.coreCount) cores",
                         fraction: model.cpuUsage,
                         colors: [Theme.accentBlue, Theme.accentCyan])
            }
            ringButton(.metric(.ram)) {
                RingStat(title: "RAM",
                         value: Format.percent(model.memUsed),
                         subtitle: "\(Format.bytes(model.memAvailableBytes)) free",
                         fraction: model.memUsed,
                         colors: [Theme.accentGreen, Theme.accentCyan])
            }
            ringButton(.metric(.temp)) {
                RingStat(title: "CPU Temp",
                         value: model.tempC.map { "\(Int($0.rounded()))°" } ?? "—",
                         subtitle: model.tempC != nil ? model.thermalLabel : nil,
                         fraction: (model.tempC ?? 0) / 100,
                         colors: [Theme.accentOrange, Theme.accentRed],
                         available: model.tempC != nil)
            }
        }
        .padding(.vertical, 2)
    }

    private func ringButton<V: View>(_ route: PanelRoute, @ViewBuilder _ label: () -> V) -> some View {
        Button { push(route) } label: { label() }
            .buttonStyle(.plain)
            .hoverLift()
    }

    private var activity: some View {
        PanelGroup {
            VStack(spacing: 0) {
                ioRow(icon: "network", tint: Theme.accentBlue, title: "Network",
                      down: model.io.netInPerSec, up: model.io.netOutPerSec)
                Divider().overlay(Color.white.opacity(0.07))
                Button { push(.disk) } label: {
                    ioRow(icon: "internaldrive", tint: Theme.accentPink, title: "Disk I/O",
                          down: model.io.diskReadPerSec, up: model.io.diskWritePerSec,
                          chevron: true)
                }
                .buttonStyle(.plain)
                .hoverRow()
            }
        }
    }

    private func ioRow(icon: String, tint: Color, title: String, down: Double, up: Double,
                       chevron: Bool = false) -> some View {
        HStack(spacing: 11) {
            IconBadge(systemName: icon, tint: tint)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .layoutPriority(1)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                rateLabel("arrow.down", Theme.accentCyan, down)
                rateLabel("arrow.up", Theme.accentPink, up)
            }
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText.opacity(0.6))
            }
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }

    private func rateLabel(_ symbol: String, _ tint: Color, _ value: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(tint)
            Text(Format.rate(value))
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .monospacedDigit()
        }
        .fixedSize()
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Toggle(isOn: $launchAtLogin) {
                Text("Launch at login")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryText)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .tint(Theme.accentBlue)
            .onChange(of: launchAtLogin) { _, newValue in
                launchAtLogin = LoginItem.setEnabled(newValue)
            }

            Spacer()

            iconButton("chart.bar.xaxis", help: "Open Activity Monitor", action: openActivityMonitor)
            iconButton("power", help: "Quit Moni") { NSApplication.shared.terminate(nil) }
        }
        .padding(.top, 2)
    }

    private func iconButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .hoverLift()
    }

    private func openActivityMonitor() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
    }
}
