import UIKit

/// Lightweight wrapper over `UIFeedbackGenerator` for immediate, tactile
/// confirmation on every interactive control. Use generously but sparingly —
/// a tap on every list row is annoying, but a tap on every primary action
/// button makes the app feel responsive.
enum Haptics {
    /// Crisp, light tap. Good for taps on buttons, list rows, and tab items.
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }

    /// Stronger impact. Use for primary CTAs and confirmations.
    static func thud() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred()
    }

    /// Selection "tick" used when value changes (e.g. toggles, chips).
    static func select() {
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        g.selectionChanged()
    }

    /// Success notification — used for "marked complete", quiz pass, etc.
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }

    /// Error notification — used for failed network calls, validation, etc.
    static func error() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.error)
    }
}
