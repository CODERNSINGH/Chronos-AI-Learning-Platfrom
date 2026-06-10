import SwiftUI
import SwiftData

struct NodeDetailView: View {
    let topicID: String
    @Binding var navigateToQuiz: QuizStartPayload?
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showAIQuiz: Bool = false
    @State private var markedLearned: Bool = false

    private var profile: UserProfile? { profiles.first }
    private var def: RoadmapDefinition? { RoadmapData.topic(withID: topicID) }
    private var node: TopicNode? { profile?.topics.first { $0.id == topicID } }

    var body: some View {
        ZStack {
            ChronosTheme.backgroundGradient.ignoresSafeArea()

            if let def = def {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(def: def)
                        learnCard(def: def)
                        summaryCard(def: def)
                        codeCard(def: def)
                        if let node = node {
                            progressCard(node: node)
                        }
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }

                bottomBar(def: def)
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(def?.name ?? "")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textPrimary)
            }
        }
        .onAppear {
            if let node = node {
                markedLearned = node.nodeStatus == .completed
            }
        }
    }

    // MARK: - Sections

    private func header(def: RoadmapDefinition) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                DifficultyBadge(difficulty: def.difficulty)
                Text(def.category)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(ChronosTheme.surface))
            }

            Text(def.name)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)

            Text(def.shortDescription)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(ChronosTheme.textSecondary)
        }
    }

    private func learnCard(def: RoadmapDefinition) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT YOU'LL LEARN")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(ChronosTheme.amber)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(def.learnBullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(ChronosTheme.amber)
                            .padding(.top, 2)
                        Text(bullet)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(ChronosTheme.textPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 18)
    }

    private func summaryCard(def: RoadmapDefinition) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONCEPT SUMMARY")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(ChronosTheme.amber)
            Text(def.conceptSummary.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(ChronosTheme.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 18)
    }

    private func codeCard(def: RoadmapDefinition) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CODE EXAMPLE")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(ChronosTheme.amber)
                Spacer()
                Text(def.codeExample.language.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(ChronosTheme.surface))
            }
            Text(def.codeExample.caption)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ChronosTheme.textTertiary)
            CodeBlockView(code: def.codeExample.code, language: def.codeExample.language)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18, radius: 18)
    }

    private func progressCard(node: TopicNode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR PROGRESS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(ChronosTheme.amber)
            HStack(spacing: 20) {
                miniStat(value: "\(node.attemptCount)", label: "Attempts")
                miniStat(value: "\(node.bestScore)/5", label: "Best")
                miniStat(value: "\(node.xpEarned)", label: "XP")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, radius: 16)
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(ChronosTheme.amber)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(ChronosTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom bar

    private func bottomBar(def: RoadmapDefinition) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                Button {
                    Haptics.thud()
                    let payload = QuizStartPayload(
                        topicID: def.id,
                        topicName: def.name,
                        difficulty: def.difficulty
                    )
                    navigateToQuiz = payload
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text(markedLearned ? "Redo AI Quiz" : "Generate AI Quiz")
                    }
                }
                .primaryButtonStyle()

                Button {
                    toggleLearned()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: markedLearned ? "checkmark.seal.fill" : "checkmark.seal")
                        Text(markedLearned ? "Marked as Learned" : "Mark as Learned")
                    }
                }
                .secondaryButtonStyle()
                .foregroundStyle(markedLearned ? ChronosTheme.success : ChronosTheme.amber)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                Rectangle()
                    .fill(ChronosTheme.background.opacity(0.95))
                    .blur(radius: 0.3)
                    .ignoresSafeArea()
            )
        }
    }

    private func toggleLearned() {
        guard let node = node, let p = profile else { return }
        if markedLearned {
            Haptics.tap()
            node.nodeStatus = .available
            node.completedAt = nil
            p.totalXP = max(0, p.totalXP - node.xpEarned)
            node.xpEarned = 0
            markedLearned = false
        } else {
            Haptics.success()
            let wasAvailable = node.nodeStatus == .available
            node.nodeStatus = .completed
            node.completedAt = Date()
            // Award XP equivalent to a perfect quiz if not already earned via quiz
            if node.xpEarned == 0 {
                let xp = ProgressService.shared.calculateXP(score: 5, total: 5, fastAnswers: 0, perfect: true)
                node.xpEarned = xp
                p.totalXP += xp
            }
            markedLearned = true
            _ = wasAvailable // silence unused warning
        }
        let before = Set(p.topics.filter { $0.nodeStatus == .available || $0.nodeStatus == .inProgress }.map { $0.id })
        RoadmapService.shared.recomputeStatuses(profile: p)
        let after = Set(p.topics.filter { $0.nodeStatus == .available || $0.nodeStatus == .inProgress }.map { $0.id })
        let newly = after.subtracting(before)
        try? modelContext.save()
        if !newly.isEmpty {
            // The new view will pick this up via @Query; the toast is purely
            // for the user feeling of progress.
            Haptics.success()
        }
    }
}

// MARK: - Code block

struct CodeBlockView: View {
    let code: String
    let language: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(highlighted)
                .font(.system(size: 12.5, weight: .regular, design: .monospaced))
                .foregroundStyle(ChronosTheme.textPrimary)
                .padding(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.04, green: 0.05, blue: 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ChronosTheme.amber.opacity(0.15), lineWidth: 1)
        )
    }

    private var highlighted: AttributedString {
        var attr = AttributedString(code)
        let nsString = code as NSString

        func apply(pattern: String, color: Color) {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: nsString.length))
            for m in matches {
                let prefix = nsString.substring(to: m.range.location)
                let startIdx = attr.index(attr.startIndex, offsetByCharacters: prefix.count)
                let endIdx = attr.index(startIdx, offsetByCharacters: m.range.length)
                if startIdx < attr.endIndex, endIdx <= attr.endIndex {
                    attr[startIdx..<endIdx].foregroundColor = color
                }
            }
        }

        let keywords = ["func", "let", "var", "if", "else", "return", "while", "for", "in",
                        "struct", "class", "mutating", "guard", "true", "false", "nil", "where",
                        "repeat", "switch", "case", "default", "init", "self", "static", "enum"]
        for kw in keywords {
            apply(pattern: "\\b\(kw)\\b", color: ChronosTheme.amber)
        }
        apply(pattern: "\\b\\d+\\b", color: Color(red: 0.4, green: 0.85, blue: 0.95))
        apply(pattern: "\"[^\"]*\"", color: Color(red: 0.85, green: 0.5, blue: 0.85))
        apply(pattern: "//[^\\n]*", color: ChronosTheme.textTertiary)
        return attr
    }
}
