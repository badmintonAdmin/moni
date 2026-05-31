import SwiftUI
import AppKit

/// Hover feedback for tappable elements: pointing-hand cursor + a subtle lift
/// (scale + brightness). Use on rings and icon buttons.
private struct HoverLift: ViewModifier {
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(hovering ? 1.03 : 1.0)
            .brightness(hovering ? 0.07 : 0)
            .animation(.easeOut(duration: 0.12), value: hovering)
            .onHover { inside in
                hovering = inside
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
    }
}

/// Hover feedback for list rows: pointing-hand cursor + a soft rounded
/// highlight behind the row.
private struct HoverRow: ViewModifier {
    var cornerRadius: CGFloat
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(hovering ? 0.07 : 0))
            )
            .animation(.easeOut(duration: 0.12), value: hovering)
            .onHover { inside in
                hovering = inside
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
    }
}

extension View {
    func hoverLift() -> some View { modifier(HoverLift()) }
    func hoverRow(cornerRadius: CGFloat = 8) -> some View { modifier(HoverRow(cornerRadius: cornerRadius)) }
}
