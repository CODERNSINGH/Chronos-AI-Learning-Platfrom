import SwiftUI

struct XPBarView: View {
    let progress: Double
    let currentLevel: Int
    let currentXP: Int
    let xpToNext: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Level \(currentLevel)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.amber)
                Spacer()
                Text("\(currentXP) / \(currentXP + xpToNext) XP")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(ChronosTheme.surfaceHigh)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(ChronosTheme.amberGradient)
                        .frame(width: max(8, geo.size.width * CGFloat(progress)))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 14)

            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ChronosTheme.textTertiary)
        }
    }
}
