import SwiftUI

struct ProgressRingView: View {
    let progress: Double          // 0.0 ... 1.0
    let lineWidth: CGFloat
    let trackColor: Color
    let foregroundColor: Color
    var animated: Bool = true

    @State private var displayProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(max(displayProgress, 0), 1)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [foregroundColor.opacity(0.8), foregroundColor, foregroundColor.opacity(0.8)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(animated ? .easeOut(duration: 1.1) : .none, value: displayProgress)
        }
        .onAppear {
            displayProgress = animated ? 0 : progress
            if animated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    displayProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            displayProgress = newValue
        }
    }
}
