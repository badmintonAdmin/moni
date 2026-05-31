import SwiftUI
import Charts

/// A compact dark time-series chart (area + line) for a metric's history.
struct MetricChart: View {
    var points: [HistoryPoint]
    var tint: Color
    var maxY: Double          // 100 for CPU/RAM %, ~100 for temperature
    var unitSuffix: String    // "%" or "°"

    var body: some View {
        Chart {
            ForEach(points) { p in
                AreaMark(x: .value("t", p.t), y: .value("v", p.v))
                    .foregroundStyle(
                        LinearGradient(colors: [tint.opacity(0.35), tint.opacity(0.02)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("t", p.t), y: .value("v", p.v))
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: 0...maxY)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, maxY / 2, maxY]) { value in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))\(unitSuffix)")
                            .font(.system(size: 8))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
        }
        .frame(height: 96)
        .overlay {
            if points.count < 2 {
                Text("collecting…")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}
