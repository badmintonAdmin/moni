import SwiftUI

/// Compact circular gauge: a thin gradient ring with a value in the center and
/// a title (plus optional subtitle) below. No glow — clean flat strokes.
struct RingStat: View {
    var title: String
    var value: String           // center text, e.g. "8%" or "42°"
    var subtitle: String? = nil // small line under the title
    var fraction: Double        // 0...1 ring fill
    var colors: [Color]         // ring gradient
    var available: Bool = true  // false => dimmed placeholder

    private let ringSize: CGFloat = 72
    private let lineWidth: CGFloat = 7

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: lineWidth)

                if available {
                    Circle()
                        .trim(from: 0, to: min(max(fraction, 0), 1))
                        .stroke(
                            AngularGradient(
                                colors: colors + [colors.first ?? .white],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.smooth(duration: 0.6), value: fraction)
                }

                Text(value)
                    .font(.system(size: 21, weight: .medium, design: .rounded))
                    .foregroundStyle(available ? .white : Theme.secondaryText)
                    .contentTransition(.numericText())
            }
            .frame(width: ringSize, height: ringSize)

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))

                Text(subtitle ?? " ")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Theme.secondaryText.opacity(subtitle == nil ? 0 : 1))
                    .lineLimit(1)
                    .frame(height: 12)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
