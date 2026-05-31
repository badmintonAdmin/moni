import SwiftUI

/// Disk screen: free/used space per mounted volume + current read/write rates.
struct DiskDetailView: View {
    @Bindable var model: MetricsModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("VOLUMES")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.secondaryText)

                PanelGroup {
                    VStack(spacing: 0) {
                        if model.volumes.isEmpty {
                            Text("reading…")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                        } else {
                            ForEach(Array(model.volumes.enumerated()), id: \.element.id) { index, vol in
                                volumeRow(vol)
                                if index < model.volumes.count - 1 {
                                    Divider().overlay(Color.white.opacity(0.06))
                                }
                            }
                        }
                    }
                }

                Text("ACTIVITY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.top, 2)

                HStack(spacing: 18) {
                    rate("Read", "arrow.down", Theme.accentCyan, model.io.diskReadPerSec)
                    rate("Write", "arrow.up", Theme.accentPink, model.io.diskWritePerSec)
                }
            }
            .padding(16)
        }
        .onAppear { model.refreshVolumes() }
    }

    private func volumeRow(_ vol: VolumeInfo) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(vol.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text(Format.percent(vol.usedFraction))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
            }
            usedBar(vol.usedFraction)
            Text("\(Format.bytes(vol.available)) free of \(Format.bytes(vol.total))")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.vertical, 9)
    }

    private func usedBar(_ fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))
                Capsule()
                    .fill(LinearGradient(colors: [Theme.accentBlue, Theme.accentCyan],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(4, geo.size.width * min(max(fraction, 0), 1)))
            }
        }
        .frame(height: 7)
    }

    private func rate(_ label: String, _ symbol: String, _ tint: Color, _ value: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
                Text(Format.rate(value))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
    }
}
