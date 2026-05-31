import SwiftUI
import AppKit

/// Small leading icon badge (rounded tinted square) used in the activity rows.
struct IconBadge: View {
    var systemName: String
    var tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 28, height: 28)
            .background(tint.opacity(0.16), in: .rect(cornerRadius: 8))
    }
}

/// A barely-there grouping container: a hairline outline over the panel
/// background (no gray fill, no glass). Matches the reference's activity block.
struct PanelGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

/// Makes the hosting menu-bar window fully transparent and removes the system
/// popover's vibrant backdrop, so the ONLY visible shape is our own rounded
/// background — eliminating the light outer outline the system draws.
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        if let content = window.contentView { stripVibrancy(content) }
    }

    /// The system places an NSVisualEffectView behind the content that paints
    /// the rounded glass + light border. Disable it; our own background draws
    /// the panel shape instead.
    private func stripVibrancy(_ view: NSView) {
        if let effect = view as? NSVisualEffectView {
            effect.state = .inactive
            effect.isHidden = true
        }
        view.subviews.forEach(stripVibrancy)
    }
}
