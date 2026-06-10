import SwiftUI
import SwiftData

struct QuizResultsView: View {
    let result: QuizResultPayload
    let topic: QuizStartPayload

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var displayedXP: Int = 0
    @State private var showReview: Bool = false
    @State private var showLevelUp: Bool = false
    @State private var newLevel: Constants.Level? = nil

    init(result: QuizResultPayload, topic: QuizStartPayload) {
        self.result = result
        self.topic = topic
    }

    private var profile: UserProfile? { profiles.first }
    private var progressService = ProgressService.shared

    var body: some View {
        ZStack {
            ChronosTheme.backgroundGradient.ignoresSafeArea()

            if result.score >= 4 {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ScrollView {
                VStack(spacing: 18) {
                    headerSection
                    if result.topicCompleted { topicCompletedBanner }
                    if !result.newlyUnlocked.isEmpty { unlockBanner(result.newlyUnlocked) }
                    scoreRing
                    xpCard
                    statsRow
                    reviewSection
                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }

            VStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                        Text("Return to Roadmap")
                    }
                }
                .primaryButtonStyle()
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
                .background(
                    LinearGradient(colors: [Color.clear, ChronosTheme.background],
                                   startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("RESULTS")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(ChronosTheme.amber)
            }
        }
        .onAppear {
            animateXP()
            checkLevelUp()
        }
        .fullScreenCover(isPresented: $showLevelUp) {
            if let lvl = newLevel {
                LevelUpModal(newLevel: lvl) {
                    showLevelUp = false
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text(topic.topicName)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ChronosTheme.textTertiary)
            Text(celebrationText)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(result.score >= 4 ? ChronosTheme.amber : ChronosTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var scoreRing: some View {
        ZStack {
            ProgressRingView(
                progress: Double(result.score) / Double(max(result.total, 1)),
                lineWidth: 14,
                trackColor: ChronosTheme.surfaceHigh,
                foregroundColor: result.score >= 4 ? ChronosTheme.amber : ChronosTheme.success
            )
            .frame(width: 200, height: 200)
            .amberGlow(radius: 14, intensity: result.score >= 4 ? 0.4 : 0.0)
            VStack(spacing: 2) {
                Text("\(result.score)/\(result.total)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                Text("CORRECT")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(ChronosTheme.textTertiary)
                let accuracy = Double(result.score) / Double(max(result.total, 1))
                Text(accuracy.asPercentage + " accuracy")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.amber)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }

    private var xpCard: some View {
        VStack(spacing: 6) {
            Text("XP EARNED")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(ChronosTheme.amber)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("+\(displayedXP)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(ChronosTheme.amberGradient)
                    .contentTransition(.numericText())
                Text("XP")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.amber)
            }
            if result.fastAnswers > 0 || result.perfect {
                HStack(spacing: 6) {
                    if result.perfect {
                        bonusChip("Perfect Bonus", "+50", icon: "star.fill")
                    }
                    if result.fastAnswers > 0 {
                        bonusChip("Speed x\(result.fastAnswers)", "+\(result.fastAnswers * 10)", icon: "bolt.fill")
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle(padding: 18, radius: 20)
    }

    private func bonusChip(_ label: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold))
            Text(label).font(.system(size: 10, weight: .semibold, design: .rounded))
            Text(value).font(.system(size: 10, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(ChronosTheme.amber)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(ChronosTheme.amber.opacity(0.15)))
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(value: "\(result.fastAnswers)", label: "Fast", color: ChronosTheme.info, icon: "bolt.fill")
            statTile(value: "\(result.questions.count - result.score)", label: "Missed", color: ChronosTheme.danger, icon: "xmark.circle")
            statTile(value: "\(result.durationSeconds)s", label: "Time", color: ChronosTheme.success, icon: "timer")
        }
    }

    private func statTile(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .padding(5)
                .background(Circle().fill(color.opacity(0.18)))
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(ChronosTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ChronosTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.20), lineWidth: 1)
        )
    }

    // MARK: - Review

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    showReview.toggle()
                }
            } label: {
                HStack {
                    Text("REVIEW ANSWERS")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(ChronosTheme.amber)
                    Spacer()
                    Image(systemName: showReview ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ChronosTheme.amber)
                }
            }
            .buttonStyle(.plain)

            if showReview {
                VStack(spacing: 8) {
                    ForEach(result.questions) { q in
                        reviewRow(q)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 18)
    }

    private func reviewRow(_ q: QuizQuestion) -> some View {
        let userAnswer = result.userAnswers[q.id - 1] ?? "—"
        let correct = userAnswer == q.correctAnswer
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(correct ? ChronosTheme.success : ChronosTheme.danger)
                Text(q.question)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                    .lineLimit(3)
            }
            HStack {
                Text("Your: \(userAnswer.isEmpty ? "—" : userAnswer)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(correct ? ChronosTheme.success : ChronosTheme.danger)
                Spacer()
                Text("Correct: \(q.correctAnswer)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(ChronosTheme.amber)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ChronosTheme.background.opacity(0.5))
        )
    }

    // MARK: - Logic

    private var celebrationText: String {
        switch result.score {
        case 5:     return "Perfect! 🏆"
        case 4:     return "Amazing! 🌟"
        case 3:     return "Nice work! ✨"
        case 2:     return "Keep going 💪"
        default:    return "Practice makes perfect"
        }
    }

    // MARK: - Banners

    private var topicCompletedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ChronosTheme.success)
            VStack(alignment: .leading, spacing: 1) {
                Text("TOPIC MASTERED")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(ChronosTheme.success)
                Text(topic.topicName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ChronosTheme.success.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ChronosTheme.success.opacity(0.35), lineWidth: 1)
        )
    }

    private func unlockBanner(_ names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ChronosTheme.amber)
                Text(names.count == 1 ? "NEW TOPIC UNLOCKED" : "\(names.count) NEW TOPICS UNLOCKED")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(ChronosTheme.amber)
            }
            ForEach(names, id: \.self) { name in
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ChronosTheme.amber)
                    Text(name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(ChronosTheme.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ChronosTheme.amber.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ChronosTheme.amber.opacity(0.35), lineWidth: 1)
        )
    }

    private func animateXP() {
        let target = result.xpEarned
        var current = 0
        let steps = max(1, target / 30)
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            current += steps
            if current >= target {
                current = target
                timer.invalidate()
            }
            withAnimation(.linear(duration: 0.02)) {
                displayedXP = current
            }
        }
    }

    private func checkLevelUp() {
        guard let p = profile else { return }
        let current = progressService.level(forXP: p.totalXP)
        let oldTotal = p.totalXP - result.xpEarned
        let oldLevel = progressService.level(forXP: oldTotal)
        if current.level > oldLevel.level {
            newLevel = current
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                showLevelUp = true
            }
        }
    }
}
