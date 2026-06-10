import Foundation
import SwiftData

@Model
final class QuizAttempt {
    @Attribute(.unique) var id: UUID
    var topicID: String
    var topicName: String
    var score: Int                // number correct
    var totalQuestions: Int
    var xpEarned: Int
    var date: Date
    var durationSeconds: Int
    var answersData: Data         // JSON-encoded [Int: String]  (question index -> selected answer)

    var profile: UserProfile?

    init(id: UUID = UUID(),
         topicID: String,
         topicName: String,
         score: Int,
         totalQuestions: Int,
         xpEarned: Int,
         date: Date = .now,
         durationSeconds: Int = 0,
         answers: [Int: String] = [:]) {
        self.id = id
        self.topicID = topicID
        self.topicName = topicName
        self.score = score
        self.totalQuestions = totalQuestions
        self.xpEarned = xpEarned
        self.date = date
        self.durationSeconds = durationSeconds
        if let data = try? JSONEncoder().encode(answers) {
            self.answersData = data
        } else {
            self.answersData = Data()
        }
    }

    var answers: [Int: String] {
        (try? JSONDecoder().decode([Int: String].self, from: answersData)) ?? [:]
    }

    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions)
    }
}
