import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var apiKeyField: String = ""
    @State private var showKey: Bool = false
    @State private var testStatus: TestStatus = .idle
    @State private var showResetConfirm: Bool = false
    @State private var showModelPicker: Bool = false
    @State private var notificationsEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()
    @FocusState private var apiKeyFocused: Bool

    enum TestStatus { case idle, testing, success, failure }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                ChronosTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        profileCard
                        apiKeyCard
                        modelCard
                        notificationsCard
                        dataCard
                        aboutCard
                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { apiKeyFocused = false }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(ChronosTheme.amber)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { apiKeyFocused = false }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(ChronosTheme.amber)
                }
            }
            .alert("Reset All Progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { resetProgress() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete your XP, streaks, quiz history and achievements. This cannot be undone.")
            }
            .sheet(isPresented: $showModelPicker) {
                if let p = profile {
                    ModelPickerSheet(currentModelID: p.groqModel) { picked in
                        p.groqModel = picked.id
                        try? modelContext.save()
                    }
                    .presentationDetents([.large])
                }
            }
            .onAppear {
                if let key = KeychainService.shared.loadAPIKey() {
                    apiKeyField = key
                } else {
                    apiKeyField = Constants.defaultAPIKey
                }
                notificationsEnabled = UserDefaults.standard.bool(forKey: Constants.notificationsEnabledKey)
            }
        }
    }

    // MARK: - Profile

    private var profileCard: some View {
        Group {
            if let p = profile {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(ChronosTheme.amberGradient)
                            .frame(width: 56, height: 56)
                            .amberGlow(radius: 8, intensity: 0.4)
                        Text(p.avatar)
                            .font(.system(size: 30))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.username)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(ChronosTheme.textPrimary)
                        Text("Level \(ProgressService.shared.level(forXP: p.totalXP).level)  •  \(p.totalXP) XP")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(ChronosTheme.amber)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 18)
    }

    // MARK: - API key

    private var apiKeyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("GROQ API KEY", icon: "key.fill")
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(ChronosTheme.amber.opacity(0.7))
            }

            Text("A free key is pre-filled. Replace it with your own from console.groq.com/keys.")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(ChronosTheme.textTertiary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Group {
                    if showKey {
                        TextField("gsk_…", text: $apiKeyField)
                    } else {
                        SecureField("gsk_…", text: $apiKeyField)
                    }
                }
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(ChronosTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ChronosTheme.surfaceHigh)
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($apiKeyFocused)
                .submitLabel(.done)
                .onSubmit { apiKeyFocused = false }

                Button {
                    showKey.toggle()
                } label: {
                    Image(systemName: showKey ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ChronosTheme.amber)
                        .frame(width: 46, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(ChronosTheme.amber.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button { saveKey() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text("Save Key")
                    }
                }
                .secondaryButtonStyle()
                .frame(maxWidth: 120)

                Button {
                    Task { await testConnection() }
                } label: {
                    HStack(spacing: 6) {
                        if testStatus == .testing {
                            ProgressView().tint(ChronosTheme.amber)
                        } else {
                            Image(systemName: testIcon)
                                .foregroundStyle(testColor)
                        }
                        Text(testButtonText)
                    }
                }
                .secondaryButtonStyle()
                .frame(maxWidth: .infinity)
                .disabled(testStatus == .testing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 18)
    }

    // MARK: - Model picker

    private var modelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("AI MODEL", icon: "cpu.fill")

            if let p = profile {
                let model = Constants.groqModel(id: p.groqModel)
                Button {
                    showModelPicker = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(ChronosTheme.amber.opacity(0.20))
                                .frame(width: 42, height: 42)
                            Image(systemName: model.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(ChronosTheme.amber)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.displayName)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(ChronosTheme.textPrimary)
                            Text(model.provider + "  •  " + model.summary)
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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 18)
    }

    // MARK: - Notifications

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DAILY REMINDER", icon: "bell.badge.fill")

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Reminder")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(ChronosTheme.textPrimary)
                    Text("Time to practice DSA! 🧠")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(ChronosTheme.textTertiary)
                }
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .tint(ChronosTheme.amber)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        Task { await toggleNotifications(enabled: newValue) }
                    }
            }

            if notificationsEnabled {
                HStack {
                    Text("Reminder time")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(ChronosTheme.textSecondary)
                    Spacer()
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(ChronosTheme.amber)
                        .onChange(of: reminderTime) { _, _ in updateSchedule() }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 18)
    }

    // MARK: - Data

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DATA", icon: "trash.fill")

            Button {
                showResetConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Reset All Progress")
                }
            }
            .secondaryButtonStyle()
            .foregroundStyle(ChronosTheme.danger)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 18)
    }

    // MARK: - About

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("ABOUT", icon: "info.circle.fill")

            VStack(spacing: 0) {
                aboutRow(label: "Version", value: Constants.appVersion)
                Divider().background(ChronosTheme.surfaceBorder)
                aboutRow(label: "Provider", value: "Groq Cloud")
                Divider().background(ChronosTheme.surfaceBorder)
                aboutRow(label: "Models", value: "\(Constants.groqModels.count) available")
            }
            .padding(.top, 4)

            Text("\(Constants.appName) — \(Constants.appTagline)")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(ChronosTheme.textTertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 18)
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(ChronosTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
        }
        .padding(.vertical, 6)
    }

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

    // MARK: - Logic

    private func saveKey() {
        let trimmed = apiKeyField.trimmingCharacters(in: .whitespaces)
        do {
            try KeychainService.shared.saveAPIKey(trimmed)
        } catch {
            testStatus = .failure
        }
    }

    private func testConnection() async {
        saveKey()
        testStatus = .testing
        let modelID = profile?.groqModel
        do {
            let reply = try await GroqService.shared.testConnection(model: modelID)
            await MainActor.run {
                testStatus = reply.uppercased().contains("PONG") ? .success : .failure
            }
        } catch {
            await MainActor.run {
                testStatus = .failure
            }
        }
    }

    private func toggleNotifications(enabled: Bool) async {
        if enabled {
            let granted = await NotificationService.requestAuthorization()
            await MainActor.run {
                notificationsEnabled = granted
                UserDefaults.standard.set(granted, forKey: Constants.notificationsEnabledKey)
                if granted { updateSchedule() }
            }
        } else {
            NotificationService.cancelReminders()
            UserDefaults.standard.set(false, forKey: Constants.notificationsEnabledKey)
        }
    }

    private func updateSchedule() {
        guard notificationsEnabled else { return }
        let cal = Calendar.current
        let hour = cal.component(.hour, from: reminderTime)
        let minute = cal.component(.minute, from: reminderTime)
        NotificationService.scheduleDailyReminder(at: hour, minute: minute)
    }

    private func resetProgress() {
        guard let p = profile else { return }
        for t in p.topics { modelContext.delete(t) }
        for q in p.quizAttempts { modelContext.delete(q) }
        for a in p.achievements { modelContext.delete(a) }
        p.totalXP = 0
        p.currentStreak = 0
        p.bestStreak = 0
        p.lastQuizDate = nil
        p.favoriteTopic = nil
        try? modelContext.save()
        _ = RoadmapService.shared.seedTopicsIfNeeded(profile: p)
        try? modelContext.save()
    }

    // MARK: - Test button helpers

    private var testIcon: String {
        switch testStatus {
        case .idle:    return "antenna.radiowaves.left.and.right"
        case .testing: return "ellipsis"
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.octagon.fill"
        }
    }

    private var testColor: Color {
        switch testStatus {
        case .idle:    return ChronosTheme.amber
        case .testing: return ChronosTheme.amber
        case .success: return ChronosTheme.success
        case .failure: return ChronosTheme.danger
        }
    }

    private var testButtonText: String {
        switch testStatus {
        case .idle:    return "Test Connection"
        case .testing: return "Testing…"
        case .success: return "Success"
        case .failure: return "Failed"
        }
    }
}
