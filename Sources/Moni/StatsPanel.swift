import SwiftUI

struct StatsPanel: View {
    @Bindable var model: MetricsModel
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(spacing: 14) {
            header
            rings
            activity
            footer
        }
        .padding(16)
        .frame(width: 296)
        .background(backdrop)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(WindowConfigurator())
        .preferredColorScheme(.dark)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    // MARK: Header

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

    // MARK: Ring gauges

    private var rings: some View {
        HStack(spacing: 4) {
            RingStat(
                title: "CPU",
                value: Format.percent(model.cpuUsage),
                subtitle: "\(model.coreCount) cores",
                fraction: model.cpuUsage,
                colors: [Theme.accentBlue, Theme.accentCyan]
            )
            RingStat(
                title: "RAM",
                value: Format.percent(model.memUsed),
                subtitle: "\(Format.bytes(model.memAvailableBytes)) free",
                fraction: model.memUsed,
                colors: [Theme.accentGreen, Theme.accentCyan]
            )
            RingStat(
                title: "CPU Temp",
                value: model.tempC.map { "\(Int($0.rounded()))°" } ?? "—",
                subtitle: model.tempC != nil ? model.thermalLabel : nil,
                fraction: (model.tempC ?? 0) / 100,
                colors: [Theme.accentOrange, Theme.accentRed],
                available: model.tempC != nil
            )
        }
        .padding(.vertical, 2)
    }

    // MARK: Activity (network + disk)

    private var activity: some View {
        PanelGroup {
            VStack(spacing: 0) {
                ioRow(icon: "network", tint: Theme.accentBlue, title: "Network",
                      down: model.io.netInPerSec, up: model.io.netOutPerSec)
                Divider().overlay(Color.white.opacity(0.07))
                ioRow(icon: "internaldrive", tint: Theme.accentPink, title: "Disk I/O",
                      down: model.io.diskReadPerSec, up: model.io.diskWritePerSec)
            }
        }
    }

    private func ioRow(icon: String, tint: Color, title: String, down: Double, up: Double) -> some View {
        HStack(spacing: 10) {
            IconBadge(systemName: icon, tint: tint)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            rateLabel("arrow.down", Theme.accentCyan, down)
            rateLabel("arrow.up", Theme.accentPink, up)
        }
        .padding(.vertical, 9)
    }

    private func rateLabel(_ symbol: String, _ tint: Color, _ value: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(tint)
            Text(Format.rate(value))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .monospacedDigit()
        }
        .frame(width: 78, alignment: .trailing)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
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

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Theme.secondaryText)
            .help("Quit Moni")
        }
        .padding(.top, 2)
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Color(red: 0.07, green: 0.09, blue: 0.16),
                     Color(red: 0.04, green: 0.05, blue: 0.10)],
            startPoint: .top, endPoint: .bottom
        )
    }
}
