import SwiftUI
import SwiftData

struct QuizGenerationView: View {
    let topic: QuizStartPayload
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var generationState: GenerationState = .loading
    @State private var questions: [QuizQuestion] = []
    @State private var progress: Double = 0
    @State private var errorMessage: String = ""
    @State private var pendingResult: QuizResultPayload?

    private var profile: UserProfile? { profiles.first }

    enum GenerationState { case loading, error, ready, playing, finished }

    var body: some View {
        NavigationStack {
            ZStack {
                ChronosTheme.backgroundGradient.ignoresSafeArea()

                switch generationState {
                case .loading:  loadingView
                case .error:    errorView
                case .ready:    readyView
                case .playing:  if !questions.isEmpty {
                    QuizPlayView(
                        topic: topic,
                        questions: questions,
                        onFinish: { result in
                            pendingResult = result
                            generationState = .finished
                        }
                    )
                }
                case .finished: if let r = pendingResult {
                    QuizResultsView(result: r, topic: topic)
                }
                }
            }
        }
        .task { await start() }
    }

    // MARK: - Loading

    private var loadingView: some View {
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
                Text(topic.topicName)
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
        .transition(.opacity)
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(ChronosTheme.danger)
            VStack(spacing: 6) {
                Text("Couldn't generate quiz")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(ChronosTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            Spacer()
            VStack(spacing: 10) {
                Button {
                    Task { await start() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                }
                .primaryButtonStyle()
                Button("Close") { dismiss() }
                    .secondaryButtonStyle()
            }
            .padding(.horizontal, 22)
        }
        .transition(.opacity)
    }

    // MARK: - Ready (briefly shown, auto-transitions to quiz)

    private var readyView: some View {
        VStack {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(ChronosTheme.success)
            Text("Quiz Ready!")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
            Spacer()
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Logic

    private func start() async {
        generationState = .loading
        errorMessage = ""
        questions = []
        progress = 0
        animateProgress()

        guard KeychainService.shared.hasKey else {
            await MainActor.run {
                errorMessage = "Please add your Groq API key in Settings before generating a quiz."
                generationState = .error
            }
            return
        }

        do {
            let q = try await GroqService.shared.generateQuiz(
                forTopic: topic.topicName,
                model: profile?.groqModel
            )
            await MainActor.run {
                self.questions = q
                self.progress = 1
                self.generationState = .ready
            }
            // Auto-advance to playing after a short pause
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.35)) {
                    self.generationState = .playing
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                self.generationState = .error
            }
        }
    }

    private func animateProgress() {
        progress = 0
        let target: Double = 0.85
        let step: Double = target / 25
        Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { timer in
            if progress >= target {
                timer.invalidate()
            } else {
                progress += step
            }
        }
    }
}
