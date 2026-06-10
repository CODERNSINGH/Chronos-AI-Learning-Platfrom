import SwiftUI

struct RoadmapNodeCard: View {
    let def: RoadmapDefinition
    let status: NodeStatus
    let node: TopicNode?
    let onTap: () -> Void
    let onMarkComplete: (() -> Void)?
    let onReset: (() -> Void)?

    @State private var pulse: Bool = false

    init(def: RoadmapDefinition,
         status: NodeStatus,
         node: TopicNode?,
         onTap: @escaping () -> Void,
         onMarkComplete: (() -> Void)? = nil,
         onReset: (() -> Void)? = nil) {
        self.def = def
        self.status = status
        self.node = node
        self.onTap = onTap
        self.onMarkComplete = onMarkComplete
        self.onReset = onReset
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Top row: icon + status badge
                HStack(alignment: .top) {
                    ZStack {
                        // Pulsing outer ring for available
                        if status == .available {
                            Circle()
                                .stroke(def.topicAccent.opacity(pulse ? 0.0 : 0.65), lineWidth: 2)
                                .frame(width: 52, height: 52)
                                .scaleEffect(pulse ? 1.35 : 0.95)
                                .animation(
                                    .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                                    value: pulse
                                )
                        }

                        // Background
                        Circle()
                            .fill(backgroundFill)
                            .frame(width: 44, height: 44)

                        // Status ring
                        Circle()
                            .stroke(ringStroke, lineWidth: 1.5)
                            .frame(width: 44, height: 44)

                        // Icon
                        Image(systemName: status == .locked ? "lock.fill" : def.topicIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(iconColor)
                    }
                    .frame(width: 52, height: 52)

                    Spacer(minLength: 0)

                    statusBadge
                }

                // Name
                Text(def.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(status == .locked ? ChronosTheme.textDisabled : ChronosTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                // Bottom row: difficulty + XP
                HStack(spacing: 6) {
                    difficultyDot
                    Text(def.difficulty.capitalized)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ChronosTheme.textTertiary)

                    Spacer(minLength: 0)

                    if let n = node, n.xpEarned > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(n.xpEarned)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(ChronosTheme.amber)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(ChronosTheme.amber.opacity(0.15))
                        )
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ChronosTheme.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderStroke, lineWidth: 1)
            )
            .opacity(status == .locked ? 0.55 : 1.0)
        }
        .buttonStyle(NodeCardButtonStyle())
        .disabled(status == .locked)
        .contextMenu {
            // Always show "Open Details"
            Button {
                Haptics.tap()
                onTap()
            } label: {
                Label("Open Details", systemImage: "info.circle.fill")
            }

            // Mark complete for unlocked-but-not-finished topics
            if status == .available || status == .inProgress, let onMarkComplete {
                Divider()
                Button {
                    Haptics.success()
                    onMarkComplete()
                } label: {
                    Label("Mark as Complete", systemImage: "checkmark.seal.fill")
                }
                .tint(ChronosTheme.success)
            }

            // Reset for completed topics
            if status == .completed, let onReset {
                Divider()
                Button(role: .destructive) {
                    Haptics.tap()
                    onReset()
                } label: {
                    Label("Reset Progress", systemImage: "arrow.uturn.backward.circle.fill")
                }
            }

            // Locked indicator
            if status == .locked {
                Divider()
                Text("Complete the prerequisite topics to unlock.")
            }
        }
        .onAppear {
            if status == .available { pulse = true }
        }
    }

    // MARK: - Subviews

    private var statusBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: status.iconName)
                .font(.system(size: 8, weight: .bold))
            Text(status.shortLabel)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .textCase(.uppercase)
        }
        .foregroundStyle(badgeForeground)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(badgeBackground)
        )
    }

    private var difficultyDot: some View {
        Circle()
            .fill(difficultyColor)
            .frame(width: 6, height: 6)
            .overlay(
                Circle().stroke(difficultyColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 10, height: 10)
            )
    }

    // MARK: - Computed visuals

    private var backgroundFill: AnyShapeStyle {
        switch status {
        case .locked:
            return AnyShapeStyle(ChronosTheme.surface.opacity(0.6))
        case .available, .inProgress:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [def.topicAccent.opacity(0.22), def.topicAccent.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .completed:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [ChronosTheme.success.opacity(0.22), ChronosTheme.success.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var ringStroke: AnyShapeStyle {
        switch status {
        case .locked:     return AnyShapeStyle(ChronosTheme.textDisabled.opacity(0.4))
        case .available:  return AnyShapeStyle(def.topicAccent)
        case .inProgress: return AnyShapeStyle(def.topicAccent.opacity(0.7))
        case .completed:  return AnyShapeStyle(ChronosTheme.success)
        }
    }

    private var borderStroke: AnyShapeStyle {
        switch status {
        case .locked:     return AnyShapeStyle(ChronosTheme.surfaceBorder)
        case .available:  return AnyShapeStyle(def.topicAccent.opacity(0.35))
        case .inProgress: return AnyShapeStyle(def.topicAccent.opacity(0.25))
        case .completed:  return AnyShapeStyle(ChronosTheme.success.opacity(0.30))
        }
    }

    private var iconColor: Color {
        switch status {
        case .locked:     return ChronosTheme.textDisabled
        case .available:  return def.topicAccent
        case .inProgress: return def.topicAccent
        case .completed:  return ChronosTheme.success
        }
    }

    private var badgeForeground: Color {
        switch status {
        case .locked:     return ChronosTheme.textDisabled
        case .available:  return def.topicAccent
        case .inProgress: return def.topicAccent
        case .completed:  return ChronosTheme.success
        }
    }

    private var badgeBackground: Color {
        switch status {
        case .locked:     return ChronosTheme.surface
        case .available:  return def.topicAccent.opacity(0.18)
        case .inProgress: return def.topicAccent.opacity(0.18)
        case .completed:  return ChronosTheme.success.opacity(0.18)
        }
    }

    private var difficultyColor: Color {
        switch def.difficulty.lowercased() {
        case "easy":   return ChronosTheme.success
        case "medium": return ChronosTheme.warning
        case "hard":   return ChronosTheme.danger
        default:       return ChronosTheme.textTertiary
        }
    }
}

// MARK: - Status helpers

extension NodeStatus {
    var shortLabel: String {
        switch self {
        case .locked:     return "Locked"
        case .available:  return "Start"
        case .inProgress: return "Active"
        case .completed:  return "Done"
        }
    }
}

// MARK: - Press feedback

struct NodeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
