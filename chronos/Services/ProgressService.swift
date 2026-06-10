import Foundation
import SwiftData

@MainActor
final class ProgressService {
    static let shared = ProgressService()
    private init() {}

    // MARK: - Levels

    func level(forXP xp: Int) -> Constants.Level {
        Constants.levels.last(where: { xp >= $0.xpRequired }) ?? Constants.levels[0]
    }

    func nextLevel(forXP xp: Int) -> Constants.Level? {
        Constants.levels.first(where: { xp < $0.xpRequired })
    }

    func progressInCurrentLevel(xp: Int) -> Double {
        let current = level(forXP: xp)
        if let next = nextLevel(forXP: xp) {
            let span = Double(next.xpRequired - current.xpRequired)
            let into = Double(xp - current.xpRequired)
            return span > 0 ? min(1, max(0, into / span)) : 0
        } else {
            return 1
        }
    }

    func xpToNextLevel(xp: Int) -> Int {
        if let next = nextLevel(forXP: xp) {
            return next.xpRequired - xp
        }
        return 0
    }

    // MARK: - Streak

    /// Update the streak on a successful quiz completion.
    /// Returns the new streak value.
    @discardableResult
    func updateStreak(profile: UserProfile) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = profile.lastQuizDate {
            let lastDay = calendar.startOfDay(for: last)
            let days = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if days == 0 {
                // same day — no change
            } else if days == 1 {
                profile.currentStreak += 1
            } else {
                profile.currentStreak = 1
            }
        } else {
            profile.currentStreak = 1
        }

        profile.bestStreak = max(profile.bestStreak, profile.currentStreak)
        profile.lastQuizDate = Date()
        return profile.currentStreak
    }

    // MARK: - XP

    struct QuizResult {
        let score: Int
        let total: Int
        let xpEarned: Int
        let leveledUp: Bool
        let newLevel: Constants.Level
    }

    func calculateXP(score: Int, total: Int, fastAnswers: Int, perfect: Bool) -> Int {
        var xp = score * Constants.xpPerCorrect
        xp += min(fastAnswers, score) * Constants.xpSpeedBonus
        if perfect { xp += Constants.xpPerfectScoreBonus }
        return xp
    }

    /// Result of recording a quiz. Includes any topics that just unlocked so
    /// the UI can celebrate them.
    struct RecordResult {
        let quizResult: QuizResult
        let newlyUnlocked: [TopicNode]
        let topicCompletedThisAttempt: Bool
    }

    func recordQuizCompletion(
        profile: UserProfile,
        topicID: String,
        topicName: String,
        score: Int,
        total: Int,
        xpEarned: Int,
        duration: Int,
        answers: [Int: String]
    ) -> RecordResult {
        let oldLevel = level(forXP: profile.totalXP)
        profile.totalXP += xpEarned
        let newLevel = level(forXP: profile.totalXP)
        let leveledUp = newLevel.level > oldLevel.level

        let attempt = QuizAttempt(
            topicID: topicID,
            topicName: topicName,
            score: score,
            totalQuestions: total,
            xpEarned: xpEarned,
            date: .now,
            durationSeconds: duration,
            answers: answers
        )
        attempt.profile = profile
        profile.quizAttempts.append(attempt)

        // Update topic node
        var completedNow = false
        if let node = profile.topics.first(where: { $0.id == topicID }) {
            node.attemptCount += 1
            node.bestScore = max(node.bestScore, score)
            node.xpEarned += xpEarned
            if score == total {
                completedNow = node.nodeStatus != .completed
                if completedNow {
                    node.completedAt = Date()
                }
                node.nodeStatus = .completed
            } else if node.nodeStatus != .completed {
                node.nodeStatus = .inProgress
            }
        }

        // Snapshot which topics are currently available, then recompute
        // (children of the just-completed node will flip from .locked to .available).
        let before = Set(
            profile.topics
                .filter { $0.nodeStatus == .available || $0.nodeStatus == .inProgress }
                .map { $0.id }
        )
        RoadmapService.shared.recomputeStatuses(profile: profile)
        let after = Set(
            profile.topics
                .filter { $0.nodeStatus == .available || $0.nodeStatus == .inProgress }
                .map { $0.id }
        )
        let newlyUnlockedIDs = after.subtracting(before)
        let newlyUnlocked = profile.topics.filter { newlyUnlockedIDs.contains($0.id) }

        // Update favorite topic
        updateFavoriteTopic(profile: profile, topicID: topicID, topicName: topicName)

        // Update streak
        updateStreak(profile: profile)

        return RecordResult(
            quizResult: QuizResult(
                score: score,
                total: total,
                xpEarned: xpEarned,
                leveledUp: leveledUp,
                newLevel: newLevel
            ),
            newlyUnlocked: newlyUnlocked,
            topicCompletedThisAttempt: completedNow
        )
    }

    private func updateFavoriteTopic(profile: UserProfile, topicID: String, topicName: String) {
        // Tally attempts per topic name
        var counts: [String: Int] = [:]
        for attempt in profile.quizAttempts {
            counts[attempt.topicName, default: 0] += 1
        }
        profile.favoriteTopic = counts.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Achievements

    func checkAndUnlockAchievements(profile: UserProfile) -> [Achievement] {
        let unlocked: [Achievement] = []

        func ensure(_ id: String, _ title: String, _ desc: String, _ icon: String, _ color: String) -> Achievement {
            if let existing = profile.achievements.first(where: { $0.id == id }) {
                return existing
            }
            let a = Achievement(id: id, title: title, achievementDescription: desc, iconName: icon, colorHex: color)
            a.profile = profile
            profile.achievements.append(a)
            return a
        }

        let firstQuiz   = ensure("first_quiz",  "First Quiz",     "Complete your first quiz",              "1.circle.fill",     "#F5B021")
        let perfect     = ensure("perfect",     "Perfect Score",  "Score 5/5 on a quiz",                   "star.fill",         "#FFD700")
        let weekWarrior = ensure("week_warrior","Week Warrior",   "Maintain a 7-day streak",                "flame.fill",        "#E84D3D")
        let graphMaster = ensure("graph_master","Graph Master",   "Complete all Graph nodes",               "point.3.connected.trianglepath.fill", "#458CF2")
        let dpDestroyer = ensure("dp_destroyer","DP Destroyer",   "Complete all DP nodes",                  "square.stack.3d.up.fill", "#9B59FF")
        let speedDemon  = ensure("speed_demon", "Speed Demon",    "Answer 3 questions under 5s in one quiz", "bolt.fill",        "#00C8FF")

        // First quiz
        if !profile.quizAttempts.isEmpty {
            firstQuiz.earnedAt = firstQuiz.earnedAt ?? Date()
        }
        // Perfect score
        if profile.quizAttempts.contains(where: { $0.score == $0.totalQuestions && $0.totalQuestions > 0 }) {
            perfect.earnedAt = perfect.earnedAt ?? Date()
        }
        // 7-day streak
        if profile.bestStreak >= 7 {
            weekWarrior.earnedAt = weekWarrior.earnedAt ?? Date()
        }
        // All graph completed
        let graphIDs: Set<String> = [
            "graph", "graph_dijkstra", "graph_bellman", "graph_fw",
            "graph_topo", "graph_tarjan", "graph_mst"
        ]
        let completedGraph = profile.topics.filter { graphIDs.contains($0.id) && $0.nodeStatus == .completed }
        if !graphIDs.isEmpty && completedGraph.count == graphIDs.count {
            graphMaster.earnedAt = graphMaster.earnedAt ?? Date()
        }
        // All DP completed
        let dpIDs: Set<String> = ["dp", "dp_knapsack", "dp_lcs_lis", "dp_bitmask", "dp_tree"]
        let completedDP = profile.topics.filter { dpIDs.contains($0.id) && $0.nodeStatus == .completed }
        if !dpIDs.isEmpty && completedDP.count == dpIDs.count {
            dpDestroyer.earnedAt = dpDestroyer.earnedAt ?? Date()
        }

        _ = speedDemon
        return unlocked
    }
}
