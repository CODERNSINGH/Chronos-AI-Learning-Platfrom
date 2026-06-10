import Foundation
import SwiftData

@Model
final class UserProfile {
    var username: String
    var avatar: String
    var totalXP: Int
    var currentStreak: Int
    var bestStreak: Int
    var lastQuizDate: Date?
    var favoriteTopic: String?
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var groqModel: String

    @Relationship(deleteRule: .cascade, inverse: \TopicNode.profile)
    var topics: [TopicNode] = []

    @Relationship(deleteRule: .cascade, inverse: \QuizAttempt.profile)
    var quizAttempts: [QuizAttempt] = []

    @Relationship(deleteRule: .cascade, inverse: \Achievement.profile)
    var achievements: [Achievement] = []

    init(username: String = "Chronos Learner",
         avatar: String = "🦊",
         totalXP: Int = 0,
         currentStreak: Int = 0,
         bestStreak: Int = 0,
         lastQuizDate: Date? = nil,
         favoriteTopic: String? = nil,
         hasCompletedOnboarding: Bool = false,
         createdAt: Date = .now,
         groqModel: String = Constants.defaultGroqModel) {
        self.username = username
        self.avatar = avatar
        self.totalXP = totalXP
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastQuizDate = lastQuizDate
        self.favoriteTopic = favoriteTopic
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.groqModel = groqModel
    }

    // MARK: - Computed stats (all derived from real data, never hard-coded)

    /// Best single quiz score ever achieved (e.g. 5).
    var bestQuizScore: Int {
        quizAttempts.map { $0.score }.max() ?? 0
    }

    /// Total seconds spent answering quizzes.
    var totalQuizSeconds: Int {
        quizAttempts.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Total seconds formatted as e.g. "12m 04s".
    var totalQuizTimeFormatted: String {
        let total = totalQuizSeconds
        let mins = total / 60
        let secs = total % 60
        if mins == 0 { return "\(secs)s" }
        return String(format: "%dm %02ds", mins, secs)
    }

    /// Number of topics that are unlocked (available + in-progress + completed).
    var unlockedCount: Int {
        topics.filter { $0.nodeStatus != .locked }.count
    }

    /// Number of topics currently in progress.
    var inProgressCount: Int {
        topics.filter { $0.nodeStatus == .inProgress }.count
    }

    /// Number of perfect quizzes (5/5).
    var perfectQuizCount: Int {
        quizAttempts.filter { $0.score == $0.totalQuestions && $0.totalQuestions > 0 }.count
    }

    /// Total correct answers across all attempts.
    var totalCorrectAnswers: Int {
        quizAttempts.reduce(0) { $0 + $1.score }
    }

    /// Total questions answered across all attempts.
    var totalQuestionsAnswered: Int {
        quizAttempts.reduce(0) { $0 + $1.totalQuestions }
    }

    /// Overall accuracy across every quiz (0.0 – 1.0).
    var overallAccuracy: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return Double(totalCorrectAnswers) / Double(totalQuestionsAnswered)
    }

    /// The topic with the most attempts (overrides the cached `favoriteTopic`
    /// so the displayed value is always in sync with the live data).
    var computedFavoriteTopic: String? {
        let counts = Dictionary(grouping: quizAttempts, by: \.topicID)
            .mapValues { $0.count }
        guard let top = counts.max(by: { $0.value < $1.value }) else { return nil }
        return topics.first(where: { $0.id == top.key })?.name
    }

    /// Sum of XP earned inside individual topic nodes (cross-check vs. totalXP).
    var xpFromTopics: Int {
        topics.reduce(0) { $0 + $1.xpEarned }
    }
}
