import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var apiKey: String = Constants.defaultAPIKey
    @State private var username: String = "Chronos Learner"
    @State private var avatar: String = "🦊"
    @State private var selectedModel: GroqModel = Constants.groqModel(id: Constants.defaultGroqModel)
    @State private var showModelPicker: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isSaving: Bool = false
    @State private var appeared: Bool = false
    @FocusState private var focusedField: Field?

    enum Field { case username, apiKey }

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            ChronosTheme.backgroundGradient.ignoresSafeArea()

            // Decorative blurred orbs
            Circle()
                .fill(ChronosTheme.amber.opacity(0.22))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: -120, y: -260)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 1.0).delay(0.1), value: appeared)

            Circle()
                .fill(ChronosTheme.amberDeep.opacity(0.20))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 180, y: 320)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 1.0).delay(0.2), value: appeared)

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 24)

                    heroHeader
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.easeOut(duration: 0.5), value: appeared)

                    Spacer().frame(height: 4)

                    profileCard
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                    modelCard
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                    apiKeyCard
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                    if showError {
                        errorBanner
                    }

                    actionButtons
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 22)
            }
        }
        .preferredColorScheme(.dark)
        .contentShape(Rectangle())
        .onTapGesture { focusedField = nil }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.amber)
            }
        }
        .sheet(isPresented: $showModelPicker) {
            ModelPickerSheet(currentModelID: selectedModel.id) { picked in
                selectedModel = picked
            }
            .presentationDetents([.large])
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        VStack(spacing: 12) {
            GlowingGearIcon(size: 100)
            VStack(spacing: 6) {
                Text("CHRONOS")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .tracking(8)
                    .foregroundStyle(ChronosTheme.amberGradient)
                    .amberGlow(radius: 12, intensity: 0.6)
                Text(Constants.appTagline)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(ChronosTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Profile card

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("YOUR PROFILE", icon: "person.crop.circle.fill")

            HStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Text(avatar)
                        .font(.system(size: 36))
                        .frame(width: 64, height: 64)
                        .background(
                            Circle()
                                .fill(LinearGradient(
                                    colors: [ChronosTheme.surfaceHigh, ChronosTheme.surface],
                                    startPoint: .top, endPoint: .bottom
                                ))
                        )
                        .overlay(
                            Circle().stroke(ChronosTheme.amber.opacity(0.4), lineWidth: 1.5)
                        )
                }
                TextField("Your name", text: $username)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(ChronosTheme.surfaceHigh)
                    )
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .apiKey }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Constants.avatars, id: \.self) { emo in
                        Button {
                            avatar = emo
                        } label: {
                            Text(emo)
                                .font(.system(size: 24))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(avatar == emo
                                              ? ChronosTheme.amber.opacity(0.25)
                                              : ChronosTheme.surfaceHigh)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(avatar == emo
                                                ? ChronosTheme.amber
                                                : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 20)
    }

    // MARK: - Model card

    private var modelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("AI MODEL", icon: "cpu.fill")

            Button {
                showModelPicker = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(ChronosTheme.amber.opacity(0.20))
                            .frame(width: 42, height: 42)
                        Image(systemName: selectedModel.icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(ChronosTheme.amber)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedModel.displayName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(ChronosTheme.textPrimary)
                            .lineLimit(1)
                        Text(selectedModel.provider + "  •  " + selectedModel.summary)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(ChronosTheme.textTertiary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ChronosTheme.amber)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ChronosTheme.surfaceHigh)
                )
            }
            .buttonStyle(.plain)

            Text("Choose the LLM that powers your quiz generation. Pick from 15 Groq-hosted models.")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(ChronosTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 20)
    }

    // MARK: - API key card

    private var apiKeyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("GROQ API KEY", icon: "key.fill")
                Spacer()
                Text("PRE-FILLED")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(ChronosTheme.success)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(ChronosTheme.success.opacity(0.18)))
            }

            Text("A free key is provided. Stored securely in iOS Keychain. Replace it with your own from console.groq.com/keys.")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(ChronosTheme.textTertiary)
                .lineLimit(3)

            SecureField("gsk_…", text: $apiKey)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(ChronosTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ChronosTheme.surfaceHigh)
                )
                .focused($focusedField, equals: .apiKey)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 20)
    }

    // MARK: - Error

    private var errorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ChronosTheme.danger)
            Text(errorMessage)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(ChronosTheme.danger)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ChronosTheme.danger.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ChronosTheme.danger.opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: startJourney) {
                HStack(spacing: 8) {
                    if isSaving { ProgressView().tint(.white) }
                    Image(systemName: "sparkles")
                    Text(isSaving ? "Setting up…" : "Start Journey")
                }
            }
            .primaryButtonStyle()
            .disabled(isSaving)

            Button(action: skip) {
                Text("Skip — enter API key later")
            }
            .secondaryButtonStyle()
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
        }
        .foregroundStyle(ChronosTheme.amber)
    }

    // MARK: - Save

    private func startJourney() {
        isSaving = true
        showError = false

        if !apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            do {
                try KeychainService.shared.saveAPIKey(apiKey.trimmingCharacters(in: .whitespaces))
            } catch {
                showError = true
                errorMessage = "Couldn't save API key to Keychain."
                isSaving = false
                return
            }
        }

        createProfile()
    }

    private func skip() {
        isSaving = true
        createProfile()
    }

    private func createProfile() {
        let cleanName = username.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Chronos Learner"
            : username
        let profile = UserProfile(
            username: cleanName,
            avatar: avatar,
            groqModel: selectedModel.id
        )
        modelContext.insert(profile)
        try? modelContext.save()

        _ = RoadmapService.shared.seedTopicsIfNeeded(profile: profile)
        try? modelContext.save()

        isSaving = false
        onComplete()
    }
}
