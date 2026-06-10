import Foundation
import SwiftUI

extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func daysFromNow() -> Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: self)
        let to = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }
}

extension Int {
    func formattedWithCommas() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    var asPercentage: String {
        String(format: "%.0f%%", self)
    }
}

extension Color {
    static let amberCustom = ChronosTheme.amber
    static let successCustom = ChronosTheme.success
}

extension View {
    @ViewBuilder
    func ifLet<V, T: View>(_ value: V?, transform: (Self, V) -> T) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}
