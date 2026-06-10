import SwiftUI
import SwiftData

// Payload passed to results view
struct QuizResultPayload: Identifiable {
    let id = UUID()
    let questions: [QuizQuestion]
    let userAnswers: [Int: String]
    let score: Int
    let total: Int
    let xpEarned: Int
    let durationSeconds: Int
    let fastAnswers: Int
    let perfect: Bool
    let newlyUnlocked: [String]   // topic names unlocked by this attempt
    let topicCompleted: Bool      // true if THIS topic flipped to .completed
}

struct QuizPlayView: View {
    let topic: QuizStartPayload
    let questions: [QuizQuestion]
    let onFinish: (QuizResultPayload) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var currentIndex: Int = 0
    @State private var selectedOption: String? = nil
    @State private var hasAnswered: Bool = false
    @State private var userAnswers: [Int: String] = [:]
    @State private var questionStartTime: Date = .now
    @State private var timeRemaining: Int = Constants.secondsPerQuestion
    @State private var timer: Timer?
    @State private var fastAnswersCount: Int = 0
    @State private var startTotal: Date = .now
    @State private var showQuitConfirm: Bool = false

    private var profile: UserProfile? { profiles.first }
    private var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        ZStack {
            ChronosTheme.backgroundGradient.ignoresSafeArea()

            if let q = currentQuestion {
                VStack(spacing: 0) {
                    topBar
                    progressBar
                    Spacer().frame(height: 18)
                    ScrollView {
                        VStack(spacing: 14) {
                            questionCard(q)
                            optionsList(q)
                            if hasAnswered {
                                explanationCard(q)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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
                            LinearGradient(colors: [Color.clear, ChronosTheme.background.opacity(0.95)],
                                           startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea()
                        )
                }
            } else {
                ProgressView()
            }
        }
        .onAppear { startQuestion() }
        .onDisappear { stopTimer() }
        .alert("Quit Quiz?", isPresented: $showQuitConfirm) {
            Button("Quit", role: .destructive) {
                stopTimer()
                dismiss()
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Your progress on this quiz will be lost.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                stopTimer()
                showQuitConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ChronosTheme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(ChronosTheme.surface))
            }
            Spacer()
            VStack(spacing: 0) {
                Text(topic.topicName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                Text("Question \(currentIndex + 1) of \(questions.count)")
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
            .foregroundStyle(timeRemaining <= 10 ? ChronosTheme.danger : ChronosTheme.amber)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule().fill(ChronosTheme.surface))
            .overlay(
                Capsule().stroke(timeRemaining <= 10 ? ChronosTheme.danger.opacity(0.5) : ChronosTheme.amber.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(ChronosTheme.surfaceHigh)
                RoundedRectangle(cornerRadius: 6)
                    .fill(ChronosTheme.amberGradient)
                    .frame(width: geo.size.width * CGFloat(Double(currentIndex + (hasAnswered ? 1 : 0)) / Double(questions.count)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentIndex)
            }
        }
        .frame(height: 8)
        .padding(.top, 12)
    }

    // MARK: - Question

    private func questionCard(_ q: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DifficultyBadge(difficulty: q.difficulty)
                Spacer()
                Text("Q\(currentIndex + 1)/\(questions.count)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(ChronosTheme.textTertiary)
            }
            Text(q.question)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 20)
    }

    private func optionsList(_ q: QuizQuestion) -> some View {
        VStack(spacing: 10) {
            ForEach(q.options, id: \.self) { option in
                optionButton(option, question: q)
            }
        }
    }

    private func optionButton(_ option: String, question q: QuizQuestion) -> some View {
        let isSelected = selectedOption == option
        let isCorrect = option == q.correctAnswer
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

        return Button {
            guard !hasAnswered else { return }
            selectOption(option)
        } label: {
            HStack(spacing: 12) {
                Text(letter(for: option))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(showResult && isCorrect ? ChronosTheme.success :
                                     (showResult && isSelected ? ChronosTheme.danger : ChronosTheme.amber))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(ChronosTheme.background.opacity(0.4)))

                Text(optionText(option))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)

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
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func explanationCard(_ q: QuizQuestion) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(ChronosTheme.amber)
                .padding(.top, 2)
            Text(q.explanation)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(ChronosTheme.textSecondary)
                .lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ChronosTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ChronosTheme.amber.opacity(0.30), lineWidth: 1)
        )
    }

    private var bottomButton: some View {
        Button {
            goToNext()
        } label: {
            HStack(spacing: 6) {
                Text(currentIndex == questions.count - 1 ? "Finish Quiz" : "Next Question")
                Image(systemName: currentIndex == questions.count - 1 ? "checkmark" : "arrow.right")
            }
        }
        .primaryButtonStyle()
        .opacity(hasAnswered ? 1 : 0.4)
        .disabled(!hasAnswered)
    }

    // MARK: - Logic

    private func startQuestion() {
        selectedOption = nil
        hasAnswered = false
        questionStartTime = .now
        timeRemaining = Constants.secondsPerQuestion
        startTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timeUp()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timeUp() {
        stopTimer()
        guard !hasAnswered else { return }
        selectedOption = nil
        userAnswers[currentIndex] = ""
        hasAnswered = true
    }

    private func selectOption(_ option: String) {
        selectedOption = option
        userAnswers[currentIndex] = option
        hasAnswered = true
        stopTimer()
        let elapsed = Date().timeIntervalSince(questionStartTime)
        if elapsed < 5 { fastAnswersCount += 1 }
    }

    private func goToNext() {
        if currentIndex >= questions.count - 1 {
            finishQuiz()
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex += 1
        }
        startQuestion()
    }

    private func finishQuiz() {
        stopTimer()
        let score = questions.indices.reduce(0) { acc, i in
            userAnswers[i] == questions[i].correctAnswer ? acc + 1 : acc
        }
        let duration = Int(Date().timeIntervalSince(startTotal))
        let perfect = (score == questions.count)
        let xp = ProgressService.shared.calculateXP(
            score: score,
            total: questions.count,
            fastAnswers: fastAnswersCount,
            perfect: perfect
        )

        var unlockedNames: [String] = []
        var topicCompleted = false

        if let p = profile {
            let result = ProgressService.shared.recordQuizCompletion(
                profile: p,
                topicID: topic.topicID,
                topicName: topic.topicName,
                score: score,
                total: questions.count,
                xpEarned: xp,
                duration: duration,
                answers: userAnswers
            )
            _ = ProgressService.shared.checkAndUnlockAchievements(profile: p)
            try? modelContext.save()
            unlockedNames = result.newlyUnlocked.map { $0.name }
            topicCompleted = result.topicCompletedThisAttempt
        }

        let payload = QuizResultPayload(
            questions: questions,
            userAnswers: userAnswers,
            score: score,
            total: questions.count,
            xpEarned: xp,
            durationSeconds: duration,
            fastAnswers: fastAnswersCount,
            perfect: perfect,
            newlyUnlocked: unlockedNames,
            topicCompleted: topicCompleted
        )
        onFinish(payload)
    }

    // MARK: - Helpers

    private func letter(for option: String) -> String {
        guard let first = option.first else { return "•" }
        return String(first).uppercased()
    }

    private func optionText(_ option: String) -> String {
        if option.count > 3, option[option.index(option.startIndex, offsetBy: 2)] == ")" {
            return String(option.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        }
        return option
    }
}
