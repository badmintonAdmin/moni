import SwiftUI

/// One row in a top-processes list: name on the left, a metric value on the
/// right (monospaced), with a chevron to hint at the detail screen.
struct ProcessRow: View {
    var name: String
    var valueText: String
    var tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 6)
            Text(valueText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.secondaryText.opacity(0.6))
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
