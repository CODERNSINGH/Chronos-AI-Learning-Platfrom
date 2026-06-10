import SwiftUI

struct LevelUpModal: View {
    let newLevel: Constants.Level
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    @State private var ringRotation: Double = 0

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
                    .rotationEffect(.degrees(ringRotation))

                    VStack(spacing: 4) {
                        Text("LV")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(ChronosTheme.textTertiary)
                        Text("\(newLevel.level)")
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

                    Text(newLevel.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(ChronosTheme.amberBright)
                        .multilineTextAlignment(.center)
                }

                Text("You are getting closer to becoming a Chronos Champion.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(ChronosTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button(action: onDismiss) {
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
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                scale = 1
                opacity = 1
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
    }
}
