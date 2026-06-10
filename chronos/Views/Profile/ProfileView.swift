import SwiftUI
import SwiftData

extension UserProfile {
    /// Max score achieved in any single quiz (0 if no attempts yet).
    var bestScoreAllTime: Int { bestQuizScore }
}

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showAvatarPicker: Bool = false
    @State private var editingUsername: Bool = false
    @State private var tempUsername: String = ""
    @State private var appeared: Bool = false

    private var profile: UserProfile? { profiles.first }
    private var progressService = ProgressService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                ChronosTheme.backgroundGradient.ignoresSafeArea()

                if let p = profile {
                    ScrollView {
                        VStack(spacing: 18) {
                            identityHero(profile: p)
                            levelCard(profile: p)
                            statsGrid(profile: p)
                            xpChartCard(profile: p)
                            achievementsCard(profile: p)
                            Spacer().frame(height: 30)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                    }
                } else {
                    ProgressView().tint(ChronosTheme.amber)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROFILE")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(ChronosTheme.amber)
                }
            }
            .sheet(isPresented: $showAvatarPicker) {
                if let p = profile {
                    AvatarPickerSheet(currentAvatar: p.avatar) { new in
                        p.avatar = new
                        try? modelContext.save()
                    }
                    .presentationDetents([.medium])
                }
            }
            .alert("Edit Username", isPresented: $editingUsername) {
                TextField("Username", text: $tempUsername)
                Button("Save") {
                    if let p = profile, !tempUsername.trimmingCharacters(in: .whitespaces).isEmpty {
                        p.username = tempUsername
                        try? modelContext.save()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
        }
    }

    // MARK: - Identity hero

    private func identityHero(profile p: UserProfile) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ChronosTheme.amberGradient)
                    .frame(width: 120, height: 120)
                    .amberGlow(radius: 14, intensity: 0.5)
                Text(p.avatar)
                    .font(.system(size: 60))
                Button {
                    showAvatarPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(ChronosTheme.amber)
                            .frame(width: 32, height: 32)
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 42, y: 42)
                }
                .buttonStyle(.plain)
            }

            Button {
                tempUsername = p.username
                editingUsername = true
            } label: {
                HStack(spacing: 6) {
                    Text(p.username)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(ChronosTheme.textPrimary)
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ChronosTheme.amber)
                }
            }
            .buttonStyle(.plain)

            let level = progressService.level(forXP: p.totalXP)
            HStack(spacing: 6) {
                Text("LVL \(level.level)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(ChronosTheme.amber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(ChronosTheme.amber.opacity(0.18)))
                Text(level.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 22, radius: 22)
    }

    // MARK: - Level

    private func levelCard(profile p: UserProfile) -> some View {
        let level = progressService.level(forXP: p.totalXP)
        let progress = progressService.progressInCurrentLevel(xp: p.totalXP)
        let toNext = progressService.xpToNextLevel(xp: p.totalXP)
        return VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LEVEL \(level.level)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(ChronosTheme.amber)
                    Text(level.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(ChronosTheme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(p.totalXP.formattedWithCommas())
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(ChronosTheme.amber)
                    Text("Total XP")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundStyle(ChronosTheme.textTertiary)
                }
            }
            XPBarView(
                progress: progress,
                currentLevel: level.level,
                currentXP: p.totalXP,
                xpToNext: toNext,
                title: toNext == 0 ? "Max level reached" : "\(toNext) XP to next level"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 20)
    }

    // MARK: - Stats

    private func statsGrid(profile p: UserProfile) -> some View {
        let total = max(1, p.topics.count)
        let completed = p.topics.filter { $0.nodeStatus == .completed }.count
        let avgScore: Double = {
            guard !p.quizAttempts.isEmpty else { return 0 }
            let totalAcc = p.quizAttempts.reduce(0.0) { $0 + $1.accuracy }
            return totalAcc / Double(p.quizAttempts.count)
        }()

        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("STATS", icon: "chart.bar.fill")

            let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 8) {
                statTile(value: "\(p.quizAttempts.count)", label: "Quizzes", color: ChronosTheme.amber, icon: "list.bullet.rectangle.fill")
                statTile(value: avgScore.asPercentage, label: "Accuracy", color: ChronosTheme.success, icon: "scope")
                statTile(value: "\(p.bestScoreAllTime)/5", label: "Best Quiz", color: ChronosTheme.warning, icon: "star.fill")
                statTile(value: "\(p.bestStreak)d", label: "Best Streak", color: ChronosTheme.danger, icon: "flame.fill")
                statTile(value: "\(completed)/\(total)", label: "Mastered", color: ChronosTheme.info, icon: "checkmark.seal.fill")
                statTile(value: "\(p.perfectQuizCount)", label: "Perfect", color: ChronosTheme.success, icon: "trophy.fill")
                statTile(value: "\(p.inProgressCount)", label: "In Progress", color: ChronosTheme.amber, icon: "circle.dotted")
                statTile(value: p.totalQuizTimeFormatted, label: "Time Spent", color: ChronosTheme.textPrimary, icon: "timer")
                statTile(value: p.computedFavoriteTopic ?? "—", label: "Favorite", color: ChronosTheme.amber, icon: "heart.fill")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 20)
    }

    private func statTile(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .padding(5)
                .background(Circle().fill(color.opacity(0.18)))
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(ChronosTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ChronosTheme.background.opacity(0.5))
        )
    }

    // MARK: - XP Chart

    private func xpChartCard(profile p: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("LAST 7 DAYS", icon: "chart.line.uptrend.xyaxis")
            XPBarChartView(attempts: p.quizAttempts)
                .frame(height: 140)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 20)
    }

    // MARK: - Achievements

    private func achievementsCard(profile p: UserProfile) -> some View {
        let achievements = p.achievements
        let allDefs: [(String, String, String, String)] = [
            ("first_quiz",   "First Quiz",   "1.circle.fill",     "#F5B021"),
            ("perfect",      "Perfect Score","star.fill",         "#FFD700"),
            ("week_warrior", "Week Warrior", "flame.fill",        "#E84D3D"),
            ("graph_master", "Graph Master", "point.3.connected.trianglepath.fill", "#458CF2"),
            ("dp_destroyer", "DP Destroyer", "square.stack.3d.up.fill", "#9B59FF"),
            ("speed_demon",  "Speed Demon",  "bolt.fill",         "#00C8FF")
        ]
        let earned = Dictionary(uniqueKeysWithValues: achievements.map { ($0.id, $0) })

        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ACHIEVEMENTS", icon: "rosette")
            let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(allDefs, id: \.0) { def in
                    let ach = earned[def.0]
                    achievementTile(
                        title: def.1,
                        icon: def.2,
                        color: Color(hex: def.3) ?? ChronosTheme.amber,
                        earned: ach?.earnedAt != nil
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 20)
    }

    private func achievementTile(title: String, icon: String, color: Color, earned: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(earned ? color.opacity(0.20) : ChronosTheme.surfaceHigh)
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(earned ? color : ChronosTheme.textDisabled)
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(earned ? ChronosTheme.textPrimary : ChronosTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
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
}

// MARK: - Avatar Picker

struct AvatarPickerSheet: View {
    let currentAvatar: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text("Choose Avatar")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
                .padding(.top, 16)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 12)], spacing: 12) {
                ForEach(Constants.avatars, id: \.self) { emo in
                    Button {
                        onSelect(emo)
                        dismiss()
                    } label: {
                        Text(emo)
                            .font(.system(size: 36))
                            .frame(width: 64, height: 64)
                            .background(
                                Circle().fill(currentAvatar == emo
                                              ? ChronosTheme.amber.opacity(0.25)
                                              : ChronosTheme.surfaceHigh)
                            )
                            .overlay(
                                Circle().stroke(currentAvatar == emo
                                                ? ChronosTheme.amber
                                                : Color.clear, lineWidth: 2)
                            )
                    }
                }
            }
            .padding(.horizontal, 18)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChronosTheme.background.ignoresSafeArea())
    }
}

// MARK: - Color hex

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xff) / 255.0
        let g = Double((v >> 8) & 0xff) / 255.0
        let b = Double(v & 0xff) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
