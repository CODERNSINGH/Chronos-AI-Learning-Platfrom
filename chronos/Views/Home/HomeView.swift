import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var navigateToQuiz: QuizStartPayload?
    @State private var navigateToNode: TopicNode?
    @State private var appeared: Bool = false

    private var profile: UserProfile? { profiles.first }
    private var progressService = ProgressService.shared
    private var roadmapService = RoadmapService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                ChronosTheme.backgroundGradient.ignoresSafeArea()
                ambientBlobs

                ScrollView {
                    VStack(spacing: 18) {
                        if let p = profile {
                            heroHeader(profile: p)
                            xpCard(profile: p)
                            streakAndGoalRow(profile: p)
                            quickActionsRow(profile: p)
                            todayGoalCard(profile: p)
                            recentActivity(profile: p)
                            Spacer().frame(height: 30)
                        } else {
                            ProgressView().tint(ChronosTheme.amber)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CHRONOS")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(ChronosTheme.amber)
                }
            }
            .navigationDestination(item: $navigateToNode) { node in
                NodeDetailView(topicID: node.id, navigateToQuiz: $navigateToQuiz)
            }
            .fullScreenCover(item: $navigateToQuiz) { payload in
                QuizGenerationView(topic: payload)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
        }
    }

    // MARK: - Ambient background

    private var ambientBlobs: some View {
        ZStack {
            Circle()
                .fill(ChronosTheme.amber.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -120, y: -260)
            Circle()
                .fill(ChronosTheme.amberDeep.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: 160, y: 360)
        }
        .ignoresSafeArea()
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Hero

    private func heroHeader(profile p: UserProfile) -> some View {
        let level = progressService.level(forXP: p.totalXP)
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ChronosTheme.amberGradient)
                    .frame(width: 60, height: 60)
                    .amberGlow(radius: 8, intensity: 0.4)
                Text(p.avatar)
                    .font(.system(size: 30))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello, \(p.username)!")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                HStack(spacing: 6) {
                    Text("Level \(level.level)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(ChronosTheme.amber)
                    Text("·")
                        .foregroundStyle(ChronosTheme.textTertiary)
                    Text(level.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(ChronosTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    // MARK: - XP

    private func xpCard(profile p: UserProfile) -> some View {
        let progress = progressService.progressInCurrentLevel(xp: p.totalXP)
        let level    = progressService.level(forXP: p.totalXP)
        let toNext   = progressService.xpToNextLevel(xp: p.totalXP)
        return XPBarView(
            progress: progress,
            currentLevel: level.level,
            currentXP: p.totalXP,
            xpToNext: toNext,
            title: toNext == 0 ? "Max level reached" : "\(toNext) XP to next level"
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 20)
    }

    // MARK: - Streak & masteries

    private func streakAndGoalRow(profile p: UserProfile) -> some View {
        HStack(spacing: 10) {
            miniTile(
                icon: "flame.fill",
                value: "\(p.currentStreak)",
                label: "Day Streak",
                accent: ChronosTheme.danger
            )
            miniTile(
                icon: "trophy.fill",
                value: "\(p.topics.filter { $0.nodeStatus == .completed }.count)",
                label: "Mastered",
                accent: ChronosTheme.success
            )
            miniTile(
                icon: "bolt.fill",
                value: "\(p.totalXP)",
                label: "Total XP",
                accent: ChronosTheme.amber
            )
        }
    }

    private func miniTile(icon: String, value: String, label: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Circle().fill(accent.opacity(0.18)).frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accent)
            }
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(ChronosTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ChronosTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.20), lineWidth: 1)
        )
    }

    // MARK: - Quick actions

    private func quickActionsRow(profile p: UserProfile) -> some View {
        let next = roadmapService.suggestedNextTopic(profile: p)
        return HStack(spacing: 10) {
            Button {
                Haptics.thud()
                if let node = next {
                    navigateToQuiz = QuizStartPayload(
                        topicID: node.id,
                        topicName: node.name,
                        difficulty: node.difficulty
                    )
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("AI Quiz")
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .disabled(next == nil)
        }
    }

    // MARK: - Today's goal

    private func todayGoalCard(profile p: UserProfile) -> some View {
        let next = roadmapService.suggestedNextTopic(profile: p)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("TODAY'S GOAL", icon: "target")
                Spacer()
                if next != nil {
                    Text("READY")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(ChronosTheme.success)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(ChronosTheme.success.opacity(0.18)))
                }
            }

            if let node = next {
                Button {
                    Haptics.tap()
                    navigateToNode = node
                } label: {
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(ChronosTheme.amber.opacity(0.18))
                                .frame(width: 48, height: 48)
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(ChronosTheme.amber)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(node.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(ChronosTheme.textPrimary)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                DifficultyBadge(difficulty: node.difficulty)
                                Text(node.category)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(ChronosTheme.textTertiary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(ChronosTheme.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All topics mastered 🎉")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(ChronosTheme.amber)
                    Text("Incredible work — keep reviewing to stay sharp.")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(ChronosTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 20)
    }

    // MARK: - Recent activity

    private func recentActivity(profile p: UserProfile) -> some View {
        let recents = roadmapService.recentTopics(profile: p, limit: 3)
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("RECENT ACTIVITY", icon: "clock.arrow.circlepath")

            if recents.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 18))
                        .foregroundStyle(ChronosTheme.amber)
                    Text("Take your first quiz to see history here.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(ChronosTheme.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(recents, id: \.node.id) { item in
                        recentRow(node: item.node, attempt: item.lastAttempt)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 20)
    }

    private func recentRow(node: TopicNode, attempt: QuizAttempt?) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ChronosTheme.success.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ChronosTheme.success)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(node.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                    .lineLimit(1)
                if let a = attempt {
                    Text("\(a.score)/\(a.totalQuestions) • \(a.xpEarned) XP")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(ChronosTheme.textTertiary)
                }
            }
            Spacer()
            if let a = attempt {
                Text(timeAgo(a.date))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(ChronosTheme.textTertiary)
            }
        }
    }

    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.5)
        }
        .foregroundStyle(ChronosTheme.amber)
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
