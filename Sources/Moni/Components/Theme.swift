import SwiftUI

/// Palette derived from the app icon: deep navy card, neon ring gradient,
/// green RAM segments.
enum Theme {
    static let accentBlue   = Color(red: 0.27, green: 0.45, blue: 0.98)
    static let accentCyan   = Color(red: 0.28, green: 0.82, blue: 0.95)
    static let accentPink   = Color(red: 0.95, green: 0.42, blue: 0.78)
    static let accentGreen  = Color(red: 0.36, green: 0.86, blue: 0.50)
    static let accentOrange = Color(red: 1.00, green: 0.62, blue: 0.18)
    static let accentRed    = Color(red: 0.98, green: 0.30, blue: 0.27)

    /// Gradient used for the temperature ring (matches the icon sweep).
    static let ringGradient = AngularGradient(
        colors: [accentBlue, accentCyan, accentGreen, accentPink, accentBlue],
        center: .center
    )

    static let secondaryText = Color.white.opacity(0.55)
}
