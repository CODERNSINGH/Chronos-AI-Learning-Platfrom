import SwiftUI
import SwiftData

// MARK: - Navigation payload for the quiz
struct QuizStartPayload: Identifiable, Hashable {
    let id = UUID()
    let topicID: String
    let topicName: String
    let difficulty: String
}

// MARK: - Category group used by the new roadmap layout

struct RoadmapCategory: Identifiable {
    let id: String          // category name
    let name: String
    let icon: String
    let accent: Color
    let topics: [CategoryTopic]

    struct CategoryTopic: Identifiable {
        let id: String
        let def: RoadmapDefinition
        let node: TopicNode?
    }

    var total: Int { topics.count }
    var completed: Int { topics.filter { ($0.node?.nodeStatus ?? .locked) == .completed }.count }
    var inProgress: Int { topics.filter { ($0.node?.nodeStatus ?? .locked) == .inProgress }.count }
    var progress: Double { total == 0 ? 0 : Double(completed) / Double(total) }
}

// MARK: - Roadmap screen

struct RoadmapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var selectedNode: TopicNode?
    @State private var quizPayload: QuizStartPayload?
    @State private var selectedFilter: RoadmapFilter
    @State private var appeared: Bool = false
    @State private var unlockToast: String? = nil

    init(initialFilter: RoadmapFilter = .all) {
        self._selectedFilter = State(initialValue: initialFilter)
    }

    private var profile: UserProfile? { profiles.first }

    enum RoadmapFilter: String, CaseIterable, Identifiable {
        case all          = "All"
        case available    = "Ready"
        case inProgress   = "In Progress"
        case completed    = "Completed"
        case locked       = "Locked"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all:        return "square.grid.2x2.fill"
            case .available:  return "play.circle.fill"
            case .inProgress: return "circle.dotted"
            case .completed:  return "checkmark.seal.fill"
            case .locked:     return "lock.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                ChronosTheme.backgroundGradient.ignoresSafeArea()
                gridBackground

                if let p = profile, !p.topics.isEmpty {
                    scrollContent(profile: p)
                } else {
                    ProgressView("Loading roadmap…")
                        .tint(ChronosTheme.amber)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("ROADMAP")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .tracking(3)
                    }
                    .foregroundStyle(ChronosTheme.amber)
                }
            }
            .navigationDestination(item: $selectedNode) { node in
                NodeDetailView(topicID: node.id, navigateToQuiz: $quizPayload)
            }
            .fullScreenCover(item: $quizPayload) { payload in
                QuizGenerationView(topic: payload)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) { appeared = true }
            }
        }
    }

    // MARK: - Scroll content

    private func scrollContent(profile p: UserProfile) -> some View {
        let categories = buildCategories(p: p)
        let suggested  = suggestedTopic(p: p, categories: categories)

        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 22) {
                    progressHeader(profile: p, suggested: suggested, jump: {
                        scrollToNext(proxy: proxy, suggested: suggested, profile: p)
                    })
                    if let s = suggested {
                        continueHeroCard(suggested: s)
                            .transition(.scale.combined(with: .opacity))
                    }
                    statsRow(profile: p)
                    filterChipsRow
                    categorySections(categories: categories)
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
            }
            .overlay(alignment: .top) {
                if let msg = unlockToast {
                    unlockToastBanner(msg)
                        .padding(.top, 8)
                        .padding(.horizontal, 18)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .id("unlockToast")
                }
            }
        }
    }

    private func scrollToNext(proxy: ScrollViewProxy, suggested: RoadmapCategory.CategoryTopic?, profile p: UserProfile) {
        Haptics.tap()
        guard let next = suggested, let n = next.node else { return }
        // Open the next available topic directly
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            selectedNode = n
        }
    }

    // MARK: - Subtle dot grid background

    private var gridBackground: some View {
        Canvas { ctx, size in
            let step: CGFloat = 28
            let color = Color.white.opacity(0.04)
            for x in stride(from: 0, to: size.width, by: step) {
                for y in stride(from: 0, to: size.height, by: step) {
                    let dot = Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2))
                    ctx.fill(dot, with: .color(color))
                }
            }
        }
        .ignoresSafeArea()
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Progress header (ring + greeting + jump)

    private func progressHeader(profile p: UserProfile, suggested: RoadmapCategory.CategoryTopic?, jump: @escaping () -> Void) -> some View {
        let completed = p.topics.filter { $0.nodeStatus == .completed }.count
        let total     = p.topics.count
        let progress  = total == 0 ? 0 : Double(completed) / Double(total)
        let level     = ProgressService.shared.level(forXP: p.totalXP).level

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR JOURNEY")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(ChronosTheme.textTertiary)
                    Text("Master DSA")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(ChronosTheme.textPrimary)
                    Text("Level \(level)  •  \(p.totalXP) XP")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(ChronosTheme.amber)
                }
                Spacer(minLength: 0)
                ZStack {
                    Circle()
                        .stroke(ChronosTheme.surface, lineWidth: 7)
                        .frame(width: 68, height: 68)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            ChronosTheme.amberGradient,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 68, height: 68)
                        .animation(.easeOut(duration: 0.8), value: progress)
                    VStack(spacing: 0) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(ChronosTheme.textPrimary)
                        Text("\(completed)/\(total)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(ChronosTheme.textTertiary)
                    }
                }
                .amberGlow(radius: 8, intensity: 0.4)
            }

            if suggested != nil {
                Button(action: jump) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Jump to Next Unlocked")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .tracking(0.5)
                Spacer()
                Text(suggested?.def.name ?? "")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textSecondary)
                    .lineLimit(1)
                    }
                    .foregroundStyle(ChronosTheme.amber)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(ChronosTheme.amber.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ChronosTheme.amber.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    // MARK: - Continue learning hero

    private func continueHeroCard(suggested: RoadmapCategory.CategoryTopic) -> some View {
        let status = suggested.node?.nodeStatus ?? .available
        return Button {
            if let n = suggested.node { selectedNode = n }
        } label: {
            ZStack(alignment: .topTrailing) {
                // Glow blob
                Circle()
                    .fill(suggested.def.topicAccent.opacity(0.35))
                    .frame(width: 180, height: 180)
                    .blur(radius: 60)
                    .offset(x: 80, y: -50)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                        Text(status == .completed ? "REVIEW" : "UP NEXT")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(2)
                    }
                    .foregroundStyle(suggested.def.topicAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(suggested.def.topicAccent.opacity(0.18))
                    )

                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(suggested.def.topicAccent.opacity(0.22))
                                .frame(width: 56, height: 56)
                            Image(systemName: suggested.def.topicIcon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(suggested.def.topicAccent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggested.def.name)
                                .font(.system(size: 19, weight: .black, design: .rounded))
                                .foregroundStyle(ChronosTheme.textPrimary)
                                .lineLimit(1)
                            Text(suggested.def.category)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(ChronosTheme.textSecondary)
                        }
                    }

                    Text(suggested.def.shortDescription)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(ChronosTheme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack {
                        DifficultyBadge(difficulty: suggested.def.difficulty)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Start Quiz")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(suggested.def.topicAccent)
                        )
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(ChronosTheme.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(suggested.def.topicAccent.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Stats row

    private func statsRow(profile p: UserProfile) -> some View {
        let completed = p.topics.filter { $0.nodeStatus == .completed }.count
        return HStack(spacing: 10) {
            statTile(
                value: "\(completed)/\(p.topics.count)",
                label: "Completed",
                icon: "checkmark.seal.fill",
                color: ChronosTheme.success
            )
            statTile(
                value: "\(p.currentStreak)",
                label: "Day Streak",
                icon: "flame.fill",
                color: ChronosTheme.amber
            )
            statTile(
                value: "\(p.totalXP)",
                label: "Total XP",
                icon: "bolt.fill",
                color: ChronosTheme.info
            )
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .padding(6)
                .background(Circle().fill(color.opacity(0.18)))
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
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
                .stroke(color.opacity(0.22), lineWidth: 1)
        )
    }

    // MARK: - Filter chips

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RoadmapFilter.allCases) { f in
                    chip(filter: f)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func chip(filter f: RoadmapFilter) -> some View {
        let isActive = selectedFilter == f
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                selectedFilter = f
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: f.icon)
                    .font(.system(size: 10, weight: .bold))
                Text(f.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isActive ? .white : ChronosTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? AnyShapeStyle(ChronosTheme.amberGradient) : AnyShapeStyle(ChronosTheme.surface))
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? .clear : ChronosTheme.surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category sections

    private func categorySections(categories: [RoadmapCategory]) -> some View {
        let predicate = matches(filter: selectedFilter)
        let filtered = categories.compactMap { cat -> RoadmapCategory? in
            let topics = cat.topics.filter(predicate)
            guard !topics.isEmpty else { return nil }
            return RoadmapCategory(
                id: cat.id, name: cat.name, icon: cat.icon, accent: cat.accent,
                topics: topics
            )
        }
        return LazyVStack(spacing: 18) {
            ForEach(filtered.indices, id: \.self) { idx in
                categorySection(cat: filtered[idx], index: idx)
            }
        }
    }

    private func categorySection(cat: RoadmapCategory, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryHeader(cat: cat)
            // Foundation fits 3-up; everything else is 2-up for legibility.
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: cat.id == "Foundation" ? 3 : 2)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(cat.topics) { t in
                    RoadmapNodeCard(
                        def: t.def,
                        status: t.node?.nodeStatus ?? .locked,
                        node: t.node,
                        onTap: {
                            Haptics.tap()
                            if (t.node?.nodeStatus ?? .locked) != .locked, let n = t.node {
                                selectedNode = n
                            }
                        },
                        onMarkComplete: {
                            markComplete(topicID: t.id)
                        },
                        onReset: {
                            resetProgress(topicID: t.id)
                        }
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.easeOut(duration: 0.45).delay(Double(index) * 0.05), value: appeared)
    }

    // MARK: - Mark complete / reset actions

    private func markComplete(topicID: String) {
        guard let p = profile,
              let node = p.topics.first(where: { $0.id == topicID }) else { return }
        let wasCompleted = node.nodeStatus == .completed
        if !wasCompleted {
            node.nodeStatus = .completed
            node.completedAt = Date()
            node.bestScore = max(node.bestScore, 5)
            node.attemptCount = max(node.attemptCount, 1)
            // Award XP equivalent to a perfect quiz
            let xp = ProgressService.shared.calculateXP(score: 5, total: 5, fastAnswers: 0, perfect: true)
            node.xpEarned += xp
            p.totalXP += xp
        }
        // Recompute unlocks
        let before = Set(p.topics.filter { $0.nodeStatus == .available || $0.nodeStatus == .inProgress }.map { $0.id })
        RoadmapService.shared.recomputeStatuses(profile: p)
        let after = Set(p.topics.filter { $0.nodeStatus == .available || $0.nodeStatus == .inProgress }.map { $0.id })
        let newly = after.subtracting(before)
        try? modelContext.save()
        if !newly.isEmpty {
            showUnlockToast("🎉 \(newly.count) new topic\(newly.count == 1 ? "" : "s") unlocked!")
        }
    }

    private func resetProgress(topicID: String) {
        guard let p = profile,
              let node = p.topics.first(where: { $0.id == topicID }) else { return }
        node.nodeStatus = .available
        node.completedAt = nil
        // Refund the XP earned by this node so totals stay consistent
        p.totalXP = max(0, p.totalXP - node.xpEarned)
        node.xpEarned = 0
        RoadmapService.shared.recomputeStatuses(profile: p)
        try? modelContext.save()
        Haptics.tap()
    }

    private func showUnlockToast(_ msg: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            unlockToast = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeInOut(duration: 0.3)) {
                unlockToast = nil
            }
        }
    }

    private func unlockToastBanner(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(ChronosTheme.amber)
            Text(msg)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ChronosTheme.amber.opacity(0.95))
        )
        .shadow(color: ChronosTheme.amber.opacity(0.5), radius: 12, y: 4)
    }

    private func categoryHeader(cat: RoadmapCategory) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(cat.accent.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: cat.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(cat.accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(cat.name.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(ChronosTheme.textPrimary)
                Text("\(cat.completed)/\(cat.total) mastered")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(ChronosTheme.textTertiary)
            }
            Spacer(minLength: 0)
            progressBadge(cat: cat)
        }
    }

    private func progressBadge(cat: RoadmapCategory) -> some View {
        ZStack {
            Circle()
                .stroke(ChronosTheme.surface, lineWidth: 3)
                .frame(width: 30, height: 30)
            Circle()
                .trim(from: 0, to: cat.progress)
                .stroke(cat.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 30, height: 30)
            Text("\(Int(cat.progress * 100))")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(ChronosTheme.textPrimary)
        }
    }

    // MARK: - Filtering / data assembly

    private func matches(filter f: RoadmapFilter) -> (RoadmapCategory.CategoryTopic) -> Bool {
        switch f {
        case .all:        return { _ in true }
        case .available:  return { $0.node?.nodeStatus == .available }
        case .inProgress: return { $0.node?.nodeStatus == .inProgress }
        case .completed:  return { $0.node?.nodeStatus == .completed }
        case .locked:     return { ($0.node?.nodeStatus ?? .locked) == .locked }
        }
    }

    private func buildCategories(p: UserProfile) -> [RoadmapCategory] {
        let map = Dictionary(uniqueKeysWithValues: p.topics.map { ($0.id, $0) })
        let grouped = Dictionary(grouping: RoadmapData.allTopics, by: \.category)
        var result: [RoadmapCategory] = []
        for (key, defList) in grouped {
            let accent = defList.first?.topicAccent ?? ChronosTheme.amber
            let icon   = categoryIcon(for: key)
            let topics = defList
                .sorted { (a: RoadmapDefinition, b: RoadmapDefinition) in
                    if a.isRoot != b.isRoot { return a.isRoot && !b.isRoot }
                    if a.isFoundation != b.isFoundation { return a.isFoundation && !b.isFoundation }
                    return a.id < b.id
                }
                .map { def in
                    RoadmapCategory.CategoryTopic(
                        id: def.id,
                        def: def,
                        node: map[def.id]
                    )
                }
            result.append(
                RoadmapCategory(
                    id: key, name: key, icon: icon, accent: accent, topics: topics
                )
            )
        }
        return result.sorted {
            ($0.topics.first?.def.categoryOrder ?? 99) < ($1.topics.first?.def.categoryOrder ?? 99)
        }
    }

    private func categoryIcon(for name: String) -> String {
        switch name {
        case "Foundation":                 return "circle.hexagongrid.fill"
        case "Arrays & Strings":           return "list.bullet.rectangle.portrait.fill"
        case "Sorting & Searching":        return "arrow.up.arrow.down.square.fill"
        case "Graph Algorithms":           return "point.3.connected.trianglepath.fill"
        case "Advanced Data Structures":   return "cube.fill"
        case "Dynamic Programming":        return "rectangle.split.3x3.fill"
        case "Paradigm":                   return "rectangle.split.3x3.fill"
        case "Root":                       return "crown.fill"
        default:                           return "book.fill"
        }
    }

    private func suggestedTopic(p: UserProfile, categories: [RoadmapCategory]) -> RoadmapCategory.CategoryTopic? {
        // Prefer an `available` topic, then `inProgress`. Among them, pick the lowest
        // categoryOrder so the user works bottom-up (foundation first).
        let all = categories.flatMap { $0.topics }
        let candidates = all
            .filter { ($0.node?.nodeStatus ?? .locked) == .available }
            .sorted { $0.def.categoryOrder < $1.def.categoryOrder }
        if let first = candidates.first { return first }
        let inProgress = all
            .filter { ($0.node?.nodeStatus ?? .locked) == .inProgress }
            .sorted { $0.def.categoryOrder < $1.def.categoryOrder }
        return inProgress.first
    }
}

// MARK: - Press scale style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
