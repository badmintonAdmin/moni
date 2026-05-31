import SwiftUI

/// Read-only details for one process.
struct ProcessDetailView: View {
    let route: ProcRoute
    @State private var detail: ProcDetail?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let d = detail {
                    Text(d.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    PanelGroup {
                        VStack(spacing: 0) {
                            field("PID", "\(d.pid)")
                            divider
                            field("Parent PID", d.parentPID > 0 ? "\(d.parentPID)" : "—")
                            divider
                            field("CPU", "\(Int(d.cpu.rounded()))%")
                            divider
                            field("Memory", Format.bytes(d.rss))
                            divider
                            field("Threads", "\(d.threads)")
                        }
                    }

                    if !d.path.isEmpty {
                        Text("PATH")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.secondaryText)
                        Text(d.path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("Process is no longer available, or access is restricted.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .onAppear { detail = ProcessSampler.detail(route.pid, cpu: route.cpu) }
    }

    private func field(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
    }

    private var divider: some View { Divider().overlay(Color.white.opacity(0.06)) }
}
