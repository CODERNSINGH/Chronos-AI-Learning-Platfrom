import SwiftUI
import SwiftData

/// Screenshot tour router — picks a view based on the `-chronos-screen <name>` launch
/// argument so we can take consistent screenshots of every feature without tapping.
struct ScreenshotTourView: View {
    let screen: String
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showModelPicker = false
    @State private var showAvatarPicker = false
    @State private var showLevelUp = false
    @State private var showResetConfirm = false
    @State private var showNodeDetail = false
    @State private var showModelPickerFromSettings = false
    @State private var showNotifications = true

    var body: some View {
        ZStack {
            switch screen {
            case "onboarding":
                OnboardingView(onComplete: {})
                    .sheet(isPresented: $showModelPicker) {
                        ModelPickerSheet(currentModelID: Constants.defaultGroqModel) { _ in }
                            .presentationDetents([.large])
                    }
                    .onAppear {
                        seedOnboardingData()
                    }
                    .overlay(alignment: .bottom) {
                        Button {
                            showModelPicker = true
                        } label: {
                            Text("OPEN MODEL PICKER (tour)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(ChronosTheme.amber)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(ChronosTheme.amber.opacity(0.15)))
                        }
                        .opacity(0.0) // Hidden helper for tour only
                    }

            case "model_picker_onboarding":
                OnboardingView(onComplete: {})
                    .overlay(Color.black.opacity(0.6).ignoresSafeArea())
                    .overlay {
                        ModelPickerSheet(currentModelID: Constants.defaultGroqModel) { _ in }
                    }

            case "home":
                HomeView()
                    .onAppear { seedRichData() }

            case "home_empty":
                HomeView()
                    .onAppear { seedEmptyData() }

            case "roadmap":
                TourRoadmapWrapper(initialFilter: "all")
                    .onAppear { seedRichData() }

            case "roadmap_in_progress":
                TourRoadmapWrapper(initialFilter: "inProgress")
                    .onAppear { seedRichData() }

            case "roadmap_completed":
                TourRoadmapWrapper(initialFilter: "completed")
                    .onAppear { seedRichData() }

            case "roadmap_locked":
                TourRoadmapWrapper(initialFilter: "locked")
                    .onAppear { seedRichData() }

            case "node_detail":
                TourNodeDetailWrapper(topicID: "found_bigo", isCompleted: false)
                    .onAppear { seedRichData() }

            case "node_detail_completed":
                TourNodeDetailWrapper(topicID: "found_arrays", isCompleted: true)
                    .onAppear { seedRichData() }

            case "quiz_generation":
                QuizGenerationLoadingView()
                    .onAppear { seedRichData() }

            case "quiz_play":
                TourQuizPlayView(state: .idle)
                    .onAppear { seedRichData() }

            case "quiz_play_answered":
                TourQuizPlayView(state: .answered)
                    .onAppear { seedRichData() }

            case "quiz_results":
                TourQuizResultsView(score: 5)
                    .onAppear { seedRichData() }

            case "quiz_results_partial":
                TourQuizResultsView(score: 3)
                    .onAppear { seedRichData() }

            case "level_up":
                TourLevelUpView()
                    .onAppear { seedRichData() }

            case "profile":
                ProfileView()
                    .onAppear { seedRichData() }

            case "avatar_picker":
                ProfileView()
                    .overlay(Color.black.opacity(0.6).ignoresSafeArea())
                    .overlay {
                        if let p = profiles.first {
                            AvatarPickerSheet(currentAvatar: p.avatar) { _ in }
                                .presentationDetents([.medium])
                        } else {
                            AvatarPickerSheet(currentAvatar: "🦊") { _ in }
                                .presentationDetents([.medium])
                        }
                    }
                    .onAppear { seedRichData() }

            case "settings":
                SettingsView()
                    .onAppear { seedRichData() }

            case "model_picker_settings":
                SettingsView()
                    .overlay(Color.black.opacity(0.6).ignoresSafeArea())
                    .overlay {
                        ModelPickerSheet(currentModelID: Constants.defaultGroqModel) { _ in }
                    }
                    .onAppear { seedRichData() }

            default:
                Text("Unknown screen: \(screen)")
                    .foregroundStyle(.white)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Mock data seeding

    private func seedOnboardingData() {
        // Wipe everything so the user sees a clean onboarding.
        for p in profiles {
            modelContext.delete(p)
        }
        try? modelContext.save()
    }

    private func seedEmptyData() {
        wipeStore()
        let profile = UserProfile(
            username: "Chronos Learner",
            avatar: "🦊",
            totalXP: 0,
            currentStreak: 0,
            bestStreak: 0,
            hasCompletedOnboarding: true,
            groqModel: Constants.defaultGroqModel
        )
        modelContext.insert(profile)
        _ = RoadmapService.shared.seedTopicsIfNeeded(profile: profile)
        try? modelContext.save()
    }

    private func seedRichData() {
        // Wipe and rebuild with rich demo data so screenshots are populated.
        wipeStore()

        let profile = UserProfile(
            username: "Narendra",
            avatar: "🦊",
            totalXP: 1240,
            currentStreak: 7,
            bestStreak: 12,
            lastQuizDate: Date(),
            favoriteTopic: "Arrays & Strings",
            hasCompletedOnboarding: true,
            createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 30),
            groqModel: Constants.defaultGroqModel
        )
        modelContext.insert(profile)

        let nodes = RoadmapService.shared.seedTopicsIfNeeded(profile: profile)

        // Mark several topics in various states
        let completedIDs = ["found_bigo", "found_arrays", "arrays_strings", "arrays_two_pointer", "arrays_sliding"]
        let inProgressIDs = ["found_recursion", "sorting"]
        for n in nodes {
            if completedIDs.contains(n.id) {
                n.nodeStatus = .completed
                n.completedAt = Date().addingTimeInterval(-Double.random(in: 86_400...86_400 * 14))
                n.bestScore = 5
                n.attemptCount = Int.random(in: 1...3)
                n.xpEarned = 80
            } else if inProgressIDs.contains(n.id) {
                n.nodeStatus = .inProgress
                n.unlockedAt = Date().addingTimeInterval(-86_400)
                n.attemptCount = 1
                n.bestScore = 3
                n.xpEarned = 40
            }
        }
        RoadmapService.shared.recomputeStatuses(profile: profile)

        // Add QuizAttempts (for the recent activity list and XP chart)
        let now = Date()
        for offset in 0..<8 {
            let id = completedIDs[offset % completedIDs.count]
            let attempt = QuizAttempt(
                topicID: id,
                topicName: nodes.first(where: { $0.id == id })?.name ?? "Topic",
                score: [5, 4, 5, 3, 5, 4, 5, 4][offset],
                totalQuestions: 5,
                xpEarned: [80, 60, 80, 40, 80, 60, 80, 60][offset],
                date: now.addingTimeInterval(-Double(offset) * 86_400),
                durationSeconds: [42, 67, 35, 90, 28, 55, 40, 75][offset],
                answers: [0: "A", 1: "B", 2: "C", 3: "A", 4: "B"]
            )
            attempt.profile = profile
            profile.quizAttempts.append(attempt)
        }

        // Add Achievements (4 earned, 2 locked)
        let earned = [
            ("first_quiz",   "First Quiz",    "1.circle.fill",                    "#F5B021"),
            ("perfect",      "Perfect Score", "star.fill",                        "#FFD700"),
            ("week_warrior", "Week Warrior",  "flame.fill",                       "#E84D3D"),
            ("graph_master", "Graph Master",  "point.3.connected.trianglepath.fill", "#458CF2")
        ]
        for (id, title, icon, hex) in earned {
            let ach = Achievement(
                id: id,
                title: title,
                achievementDescription: title,
                iconName: icon,
                colorHex: hex,
                earnedAt: Date().addingTimeInterval(-Double.random(in: 86_400...86_400 * 7))
            )
            ach.profile = profile
            profile.achievements.append(ach)
        }

        try? modelContext.save()
    }

    private func wipeStore() {
        for p in profiles {
            modelContext.delete(p)
        }
        try? modelContext.save()
    }
}

// MARK: - Tour wrapper for Roadmap with initial filter

private struct TourRoadmapWrapper: View {
    let initialFilter: String
    var body: some View {
        switch initialFilter {
        case "all":         RoadmapView(initialFilter: .all)
        case "available":   RoadmapView(initialFilter: .available)
        case "inProgress":  RoadmapView(initialFilter: .inProgress)
        case "completed":   RoadmapView(initialFilter: .completed)
        case "locked":      RoadmapView(initialFilter: .locked)
        default:            RoadmapView(initialFilter: .all)
        }
    }
}

extension Notification.Name {
    static let chronosTourSetRoadmapFilter = Notification.Name("chronosTourSetRoadmapFilter")
}

// MARK: - Tour wrapper for NodeDetail

private struct TourNodeDetailWrapper: View {
    let topicID: String
    let isCompleted: Bool
    @State private var navigateToQuiz: QuizStartPayload?
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            NodeDetailView(
                topicID: topicID,
                navigateToQuiz: $navigateToQuiz
            )
        }
    }
}

// MARK: - Quiz Generation (loading) standalone

struct QuizGenerationLoadingView: View {
    @State private var progress: Double = 0.45
    var body: some View {
        ZStack {
            ChronosTheme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    ProgressRingView(
                        progress: progress,
                        lineWidth: 8,
                        trackColor: ChronosTheme.amber.opacity(0.12),
                        foregroundColor: ChronosTheme.amber,
                        animated: false
                    )
                    .frame(width: 180, height: 180)
                    VStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(ChronosTheme.amber)
                            .amberGlow(radius: 14, intensity: 0.7)
                        Text("Crafting Quiz")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(ChronosTheme.textSecondary)
                            .padding(.top, 4)
                    }
                }
                VStack(spacing: 6) {
                    Text("Arrays & Strings")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(ChronosTheme.textPrimary)
                    Text("Asking Llama 3 to design 5 questions just for you…")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(ChronosTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Tour wrapper for QuizPlayView

struct TourQuizPlayView: View {
    enum PlayState { case idle, answered }
    let state: PlayState

    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: String? = nil
    @State private var hasAnswered: Bool = false
    @State private var timeRemaining: Int = 42

    private let questions: [QuizQuestion] = [
        QuizQuestion(
            id: 1,
            question: "What is the time complexity of accessing an element in an array by index?",
            options: ["A) O(1)", "B) O(n)", "C) O(log n)", "D) O(n log n)"],
            correctAnswer: "A) O(1)",
            explanation: "Arrays store elements in contiguous memory, so the offset of any element can be computed directly from its index, giving constant-time access.",
            difficulty: "easy"
        )
    ]

    var body: some View {
        ZStack {
            ChronosTheme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                progressBar
                Spacer().frame(height: 18)
                ScrollView {
                    VStack(spacing: 14) {
                        questionCard
                        optionsList
                        if hasAnswered {
                            explanationCard.transition(.opacity)
                        }
                        Spacer().frame(height: 100)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            VStack {
                Spacer()
                bottomButton
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.clear, ChronosTheme.background.opacity(0.95)],
                            startPoint: .top, endPoint: .bottom
                        ).ignoresSafeArea()
                    )
            }
        }
        .onAppear {
            if state == .answered {
                selectedOption = "B) O(n)"
                hasAnswered = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ChronosTheme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(ChronosTheme.surface))
            }
            Spacer()
            VStack(spacing: 0) {
                Text("Arrays & Strings")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                Text("Question 1 of 5")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(ChronosTheme.textTertiary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .bold))
                Text("\(timeRemaining)s")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(ChronosTheme.amber)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule().fill(ChronosTheme.surface))
            .overlay(
                Capsule().stroke(ChronosTheme.amber.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6).fill(ChronosTheme.surfaceHigh)
                RoundedRectangle(cornerRadius: 6)
                    .fill(ChronosTheme.amberGradient)
                    .frame(width: geo.size.width * CGFloat(Double(hasAnswered ? 1 : 0) / 5.0))
            }
        }
        .frame(height: 8)
        .padding(.top, 12)
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DifficultyBadge(difficulty: "easy")
                Spacer()
                Text("Q1/5")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(ChronosTheme.textTertiary)
            }
            Text(questions[0].question)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 20)
    }

    private var optionsList: some View {
        VStack(spacing: 10) {
            ForEach(questions[0].options, id: \.self) { option in
                optionButton(option)
            }
        }
    }

    private func optionButton(_ option: String) -> some View {
        let isSelected = selectedOption == option
        let isCorrect = option == questions[0].correctAnswer
        let showResult = hasAnswered
        let bg: Color = {
            if !showResult { return isSelected ? ChronosTheme.amber.opacity(0.18) : ChronosTheme.surface }
            if isCorrect    { return ChronosTheme.success.opacity(0.22) }
            if isSelected   { return ChronosTheme.danger.opacity(0.22) }
            return ChronosTheme.surface
        }()
        let border: Color = {
            if !showResult { return isSelected ? ChronosTheme.amber : ChronosTheme.surfaceBorder }
            if isCorrect    { return ChronosTheme.success }
            if isSelected   { return ChronosTheme.danger }
            return ChronosTheme.surfaceBorder
        }()
        return HStack(spacing: 12) {
            Text(String(option.first!).uppercased())
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(showResult && isCorrect ? ChronosTheme.success :
                                 (showResult && isSelected ? ChronosTheme.danger : ChronosTheme.amber))
                .frame(width: 30, height: 30)
                .background(Circle().fill(ChronosTheme.background.opacity(0.4)))
            Text(String(option.dropFirst(3)))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
            Spacer()
            if showResult && isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(ChronosTheme.success)
            } else if showResult && isSelected && !isCorrect {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(ChronosTheme.danger)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(bg))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(border, lineWidth: 1.5))
    }

    private var explanationCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(ChronosTheme.amber)
                .padding(.top, 2)
            Text(questions[0].explanation)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(ChronosTheme.textSecondary)
                .lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ChronosTheme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ChronosTheme.amber.opacity(0.30), lineWidth: 1)
        )
    }

    private var bottomButton: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Text("Next Question")
                Image(systemName: "arrow.right")
            }
        }
        .primaryButtonStyle()
        .opacity(hasAnswered ? 1 : 0.4)
        .disabled(!hasAnswered)
    }
}

// MARK: - Tour wrapper for QuizResultsView

struct TourQuizResultsView: View {
    let score: Int
    @Environment(\.dismiss) private var dismiss
    @State private var displayedXP: Int = 0

    private let questions: [QuizQuestion] = [
        QuizQuestion(id: 1, question: "What is the time complexity of accessing an array element by index?",
                     options: ["A) O(1)", "B) O(n)", "C) O(log n)", "D) O(n log n)"],
                     correctAnswer: "A) O(1)",
                     explanation: "Arrays use contiguous memory, so element access is O(1).",
                     difficulty: "easy"),
        QuizQuestion(id: 2, question: "Two-pointer technique is most useful for:",
                     options: ["A) Sorted arrays", "B) Hash tables", "C) Linked lists only", "D) Stacks"],
                     correctAnswer: "A) Sorted arrays",
                     explanation: "Two pointers shine on sorted arrays where you can move them based on comparisons.",
                     difficulty: "medium"),
        QuizQuestion(id: 3, question: "Sliding window pattern reduces complexity by:",
                     options: ["A) Reusing previous computation", "B) Sorting the array", "C) Using recursion", "D) Using extra space"],
                     correctAnswer: "A) Reusing previous computation",
                     explanation: "Sliding window reuses the work done in the previous window.",
                     difficulty: "medium"),
        QuizQuestion(id: 4, question: "Which of these is NOT a sliding-window problem?",
                     options: ["A) Max subarray sum", "B) Longest substring without repeating", "C) Binary search", "D) Minimum window substring"],
                     correctAnswer: "C) Binary search",
                     explanation: "Binary search uses divide & conquer, not sliding window.",
                     difficulty: "hard"),
        QuizQuestion(id: 5, question: "Kadane's algorithm solves:",
                     options: ["A) Maximum subarray sum", "B) Shortest path", "C) Sorting", "D) String matching"],
                     correctAnswer: "A) Maximum subarray sum",
                     explanation: "Kadane's algorithm finds the contiguous subarray with the largest sum in O(n).",
                     difficulty: "medium")
    ]

    private var xp: Int { score * 20 + (score == 5 ? 50 : 0) }
    private var perfect: Bool { score == 5 }
    private var userAnswers: [Int: String] {
        var a: [Int: String] = [:]
        for i in 0..<questions.count {
            a[i] = i < score ? questions[i].correctAnswer : questions[i].options[1]
        }
        return a
    }
    private var celebration: String {
        switch score {
        case 5: return "Perfect! 🏆"
        case 4: return "Amazing! 🌟"
        case 3: return "Nice work! ✨"
        case 2: return "Keep going 💪"
        default: return "Practice makes perfect"
        }
    }

    var body: some View {
        ZStack {
            ChronosTheme.backgroundGradient.ignoresSafeArea()
            if score >= 4 {
                ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            }
            ScrollView {
                VStack(spacing: 18) {
                    header
                    if score == 5 { topicCompletedBanner }
                    if score >= 4 { unlockBanner }
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
                Button { dismiss() } label: {
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
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Arrays & Strings")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ChronosTheme.textTertiary)
            Text(celebration)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(score >= 4 ? ChronosTheme.amber : ChronosTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var scoreRing: some View {
        ZStack {
            ProgressRingView(
                progress: Double(score) / 5.0,
                lineWidth: 14,
                trackColor: ChronosTheme.surfaceHigh,
                foregroundColor: score >= 4 ? ChronosTheme.amber : ChronosTheme.success
            )
            .frame(width: 200, height: 200)
            .amberGlow(radius: 14, intensity: score >= 4 ? 0.4 : 0.0)
            VStack(spacing: 2) {
                Text("\(score)/5")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                Text("CORRECT")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(ChronosTheme.textTertiary)
                Text("\(Int((Double(score) / 5.0) * 100))% accuracy")
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
                Text("XP")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.amber)
            }
            if perfect {
                HStack(spacing: 6) {
                    bonusChip("Perfect Bonus", "+50", icon: "star.fill")
                    bonusChip("Speed x2", "+20", icon: "bolt.fill")
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
            statTile(value: "\(min(2, 5 - score))", label: "Fast", color: ChronosTheme.info, icon: "bolt.fill")
            statTile(value: "\(5 - score)", label: "Missed", color: ChronosTheme.danger, icon: "xmark.circle")
            statTile(value: "\([42, 67, 35, 90, 28][score % 5])s", label: "Time", color: ChronosTheme.success, icon: "timer")
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
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(ChronosTheme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.20), lineWidth: 1))
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("REVIEW ANSWERS")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(ChronosTheme.amber)
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ChronosTheme.amber)
            }
            VStack(spacing: 8) {
                ForEach(questions) { q in
                    reviewRow(q)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 18)
    }

    private func reviewRow(_ q: QuizQuestion) -> some View {
        let userAnswer = userAnswers[q.id - 1] ?? "—"
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
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(ChronosTheme.background.opacity(0.5)))
    }

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
                Text("Arrays & Strings")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(ChronosTheme.success.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(ChronosTheme.success.opacity(0.35), lineWidth: 1))
    }

    private var unlockBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ChronosTheme.amber)
                Text("2 NEW TOPICS UNLOCKED")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(ChronosTheme.amber)
            }
            ForEach(["Two-Pointer Technique", "Sliding Window"], id: \.self) { name in
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
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(ChronosTheme.amber.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(ChronosTheme.amber.opacity(0.35), lineWidth: 1))
    }

    private func animateXP() {
        let target = xp
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
}

// MARK: - Tour wrapper for LevelUpModal

struct TourLevelUpView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    ProgressRingView(
                        progress: 1,
                        lineWidth: 6,
                        trackColor: ChronosTheme.amber.opacity(0.15),
                        foregroundColor: ChronosTheme.amber
                    )
                    .frame(width: 180, height: 180)
                    VStack(spacing: 4) {
                        Text("LV")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(ChronosTheme.textTertiary)
                        Text("5")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(ChronosTheme.amber)
                            .amberGlow(radius: 14, intensity: 0.9)
                    }
                }
                VStack(spacing: 8) {
                    Text("LEVEL UP!")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(ChronosTheme.textPrimary)
                        .tracking(2)
                    Text("Graph Explorer")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(ChronosTheme.amberBright)
                        .multilineTextAlignment(.center)
                }
                Text("You are getting closer to becoming a Chronos Champion.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(ChronosTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button { dismiss() } label: {
                    Text("Continue")
                }
                .primaryButtonStyle()
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 36)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ChronosTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(ChronosTheme.amber.opacity(0.4), lineWidth: 1.5)
            )
            .padding(.horizontal, 32)
        }
    }
}
