import SwiftUI

struct XPBarChartView: View {
    let attempts: [QuizAttempt]

    private struct DayBucket: Identifiable {
        let id = UUID()
        let date: Date
        let xp: Int
        let label: String
    }

    private var buckets: [DayBucket] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [DayBucket] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        for offset in stride(from: 6, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let xp = attempts.filter { $0.date >= day && $0.date < next }
                .reduce(0) { $0 + $1.xpEarned }
            result.append(DayBucket(date: day, xp: xp, label: formatter.string(from: day)))
        }
        return result
    }

    private var maxXP: Int {
        max(50, buckets.map { $0.xp }.max() ?? 50)
    }

    var body: some View {
        GeometryReader { geo in
            let barWidth = (geo.size.width - CGFloat(buckets.count - 1) * 8) / CGFloat(buckets.count)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(buckets) { bucket in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(ChronosTheme.surfaceHigh)
                                .frame(width: barWidth, height: geo.size.height - 24)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(bucket.xp > 0
                                      ? ChronosTheme.amberGradient
                                      : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom))
                                .frame(
                                    width: barWidth,
                                    height: max(6, CGFloat(bucket.xp) / CGFloat(maxXP) * (geo.size.height - 24))
                                )
                                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: bucket.xp)
                            if bucket.xp > 0 {
                                Text("\(bucket.xp)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(ChronosTheme.textPrimary)
                                    .offset(y: -CGFloat(bucket.xp) / CGFloat(maxXP) * (geo.size.height - 24) - 8)
                            }
                        }
                        Text(bucket.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(ChronosTheme.textTertiary)
                    }
                    .frame(width: barWidth)
                }
            }
        }
    }
}
