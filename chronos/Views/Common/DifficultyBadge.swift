import SwiftUI

struct DifficultyBadge: View {
    let difficulty: String

    var body: some View {
        Text(difficulty.uppercased())
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(color)
            )
    }

    private var color: Color {
        switch difficulty.lowercased() {
        case "easy":   return ChronosTheme.success
        case "medium": return ChronosTheme.amber
        case "hard":   return ChronosTheme.danger
        default:       return ChronosTheme.textTertiary
        }
    }
}
