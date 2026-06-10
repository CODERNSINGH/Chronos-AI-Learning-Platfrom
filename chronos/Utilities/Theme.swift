import SwiftUI

enum ChronosTheme {
    // MARK: - Brand Palette
    static let amber = Color(red: 0.96, green: 0.69, blue: 0.13)        // #F5B021
    static let amberBright = Color(red: 1.0, green: 0.78, blue: 0.20)   // #FFC733
    static let amberDeep = Color(red: 0.78, green: 0.50, blue: 0.05)    // #C77F0D
    static let gold = Color(red: 0.95, green: 0.77, blue: 0.30)
    static let bronze = Color(red: 0.70, green: 0.43, blue: 0.10)

    // MARK: - Semantic
    static let success = Color(red: 0.18, green: 0.72, blue: 0.36)      // #2EB85C
    static let danger = Color(red: 0.91, green: 0.30, blue: 0.24)       // #E84D3D
    static let warning = Color(red: 0.98, green: 0.65, blue: 0.16)      // #FAA628
    static let info = Color(red: 0.27, green: 0.55, blue: 0.95)         // #458CF2

    // MARK: - Background System
    static let background = Color(red: 0.07, green: 0.08, blue: 0.11)   // #12151C
    static let backgroundElevated = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let surface = Color(red: 0.14, green: 0.16, blue: 0.21)      // #232936
    static let surfaceHigh = Color(red: 0.18, green: 0.21, blue: 0.27)  // #2E3645
    static let surfaceBorder = Color.white.opacity(0.07)

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textTertiary = Color.white.opacity(0.45)
    static let textDisabled = Color.white.opacity(0.30)

    // MARK: - Node States
    static let nodeLocked = Color(white: 0.30)
    static let nodeAvailable = amber
    static let nodeCompleted = success
    static let nodeInProgress = Color(red: 0.95, green: 0.55, blue: 0.18)

    // MARK: - Gradients
    static let amberGradient = LinearGradient(
        colors: [amberBright, amber, amberDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.09, green: 0.10, blue: 0.14),
                 Color(red: 0.05, green: 0.06, blue: 0.09)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [surface, surfaceHigh.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [Color(red: 0.25, green: 0.85, blue: 0.45),
                 Color(red: 0.12, green: 0.65, blue: 0.30)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Glow Modifier
    struct Glow: ViewModifier {
        let color: Color
        let radius: CGFloat
        let intensity: Double

        func body(content: Content) -> some View {
            content
                .shadow(color: color.opacity(intensity), radius: radius)
                .shadow(color: color.opacity(intensity * 0.5), radius: radius * 1.8)
        }
    }

    static func glow(_ color: Color, radius: CGFloat = 8, intensity: Double = 0.6) -> some ViewModifier {
        Glow(color: color, radius: radius, intensity: intensity)
    }
}

extension View {
    func amberGlow(radius: CGFloat = 8, intensity: Double = 0.6) -> some View {
        modifier(ChronosTheme.Glow(color: ChronosTheme.amber, radius: radius, intensity: intensity))
    }

    func cardStyle(padding: CGFloat = 16, radius: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(ChronosTheme.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(ChronosTheme.surfaceBorder, lineWidth: 1)
            )
    }

    func primaryButtonStyle() -> some View {
        self
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ChronosTheme.amberGradient)
            )
            .amberGlow(radius: 12, intensity: 0.5)
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(ChronosTheme.amber)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ChronosTheme.amber.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ChronosTheme.amber.opacity(0.4), lineWidth: 1)
            )
    }
}
