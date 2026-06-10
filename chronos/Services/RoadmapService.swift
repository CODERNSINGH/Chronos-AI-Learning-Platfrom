import Foundation
import SwiftData

@MainActor
final class RoadmapService {
    static let shared = RoadmapService()
    private init() {}

    /// Seed the SwiftData store with all the static roadmap topics
    /// and unlock the foundation topics on first run.
    @discardableResult
    func seedTopicsIfNeeded(profile: UserProfile) -> [TopicNode] {
        if !profile.topics.isEmpty { return profile.topics }

        let definitions = RoadmapData.allTopics
        let foundationIDs: Set<String> = ["found_bigo", "found_arrays", "found_recursion"]

        var created: [TopicNode] = []
        for def in definitions {
            let node = TopicNode(
                id: def.id,
                name: def.name,
                topicDescription: def.shortDescription,
                difficulty: def.difficulty,
                category: def.category,
                parentID: def.parents.first,
                status: .locked,
                orderIndex: created.count
            )
            node.profile = profile
            profile.topics.append(node)
            created.append(node)
        }

        // Unlock foundation topics
        for id in foundationIDs {
            if let node = created.first(where: { $0.id == id }) {
                node.nodeStatus = .available
                node.unlockedAt = Date()
            }
        }

        return created
    }

    /// Recompute node statuses based on completion:
    ///   - Locked by default
    ///   - A node becomes available if all its parents are completed (or it has no parents)
    ///   - Already in-progress nodes are preserved
    ///   - Completed nodes stay completed
    func recomputeStatuses(profile: UserProfile) {
        let all = profile.topics
        let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

        for def in RoadmapData.allTopics {
            guard let node = byID[def.id] else { continue }

            // Preserve completed
            if node.nodeStatus == .completed { continue }

            // Determine if all parents are completed
            let parentsCompleted = def.parents.allSatisfy { parentID in
                byID[parentID]?.nodeStatus == .completed
            }

            // A root node with no parents OR a node whose parents are all completed
            let shouldBeAvailable = def.parents.isEmpty || parentsCompleted

            if shouldBeAvailable {
                if node.nodeStatus == .locked {
                    node.unlockedAt = Date()
                }
                if node.nodeStatus != .inProgress {
                    node.nodeStatus = .available
                }
            }
        }
    }

    /// Returns the next topic the user should focus on.
    func suggestedNextTopic(profile: UserProfile) -> TopicNode? {
        let all = profile.topics

        // 1. In-progress first
        if let inProgress = all.first(where: { $0.nodeStatus == .inProgress }) {
            return inProgress
        }

        // 2. Any topic that is .available (already unlocked)
        let available = all.filter { $0.nodeStatus == .available }

        // 3. Bottom-up progression: highest orderIndex first (foundation → root)
        return available.sorted { $0.orderIndex > $1.orderIndex }.first
    }

    /// The topic the user last completed (for "recent activity").
    func recentTopics(profile: UserProfile, limit: Int = 3) -> [(node: TopicNode, lastAttempt: QuizAttempt?)] {
        let recentAttempts = profile.quizAttempts
            .sorted { $0.date > $1.date }
            .prefix(limit * 2)
        var seen = Set<String>()
        var results: [(TopicNode, QuizAttempt?)] = []
        for attempt in recentAttempts {
            if seen.contains(attempt.topicID) { continue }
            seen.insert(attempt.topicID)
            if let node = profile.topics.first(where: { $0.id == attempt.topicID }) {
                results.append((node, attempt))
                if results.count >= limit { break }
            }
        }
        return results
    }
}
