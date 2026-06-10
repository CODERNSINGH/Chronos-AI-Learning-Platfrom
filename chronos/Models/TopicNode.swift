import Foundation
import SwiftData

enum NodeStatus: String, Codable, CaseIterable {
    case locked
    case available
    case inProgress
    case completed

    var iconName: String {
        switch self {
        case .locked: return "lock.fill"
        case .available: return "play.fill"
        case .inProgress: return "ellipsis"
        case .completed: return "checkmark"
        }
    }
}

@Model
final class TopicNode {
    @Attribute(.unique) var id: String
    var name: String
    var topicDescription: String
    var difficulty: String         // "easy" | "medium" | "hard"
    var category: String           // e.g. "Arrays & Strings"
    var parentID: String?
    var status: String             // NodeStatus raw
    var bestScore: Int
    var attemptCount: Int
    var xpEarned: Int
    var orderIndex: Int
    var unlockedAt: Date?
    var completedAt: Date?

    var profile: UserProfile?

    init(id: String,
         name: String,
         topicDescription: String = "",
         difficulty: String = "medium",
         category: String = "General",
         parentID: String? = nil,
         status: NodeStatus = .locked,
         bestScore: Int = 0,
         attemptCount: Int = 0,
         xpEarned: Int = 0,
         orderIndex: Int = 0,
         unlockedAt: Date? = nil,
         completedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.topicDescription = topicDescription
        self.difficulty = difficulty
        self.category = category
        self.parentID = parentID
        self.status = status.rawValue
        self.bestScore = bestScore
        self.attemptCount = attemptCount
        self.xpEarned = xpEarned
        self.orderIndex = orderIndex
        self.unlockedAt = unlockedAt
        self.completedAt = completedAt
    }

    var nodeStatus: NodeStatus {
        get { NodeStatus(rawValue: status) ?? .locked }
        set { status = newValue.rawValue }
    }
}
