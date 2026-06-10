import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) var id: String
    var title: String
    var achievementDescription: String
    var iconName: String
    var colorHex: String
    var earnedAt: Date?

    var profile: UserProfile?

    init(id: String,
         title: String,
         achievementDescription: String,
         iconName: String,
         colorHex: String,
         earnedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.achievementDescription = achievementDescription
        self.iconName = iconName
        self.colorHex = colorHex
        self.earnedAt = earnedAt
    }

    var isEarned: Bool { earnedAt != nil }
}
