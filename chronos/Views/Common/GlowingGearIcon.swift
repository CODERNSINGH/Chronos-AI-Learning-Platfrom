import SwiftUI

struct GlowingGearIcon: View {
    @State private var rotation: Double = 0
    var size: CGFloat = 96
    var color: Color = ChronosTheme.amber

    var body: some View {
        ZStack {
            // Outer gear ring
            Image(systemName: "gearshape.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(ChronosTheme.amberGradient)
                .rotationEffect(.degrees(rotation))
                .amberGlow(radius: 16, intensity: 0.9)

            // Clock face overlay
            ZStack {
                Circle()
                    .fill(ChronosTheme.background)
                    .frame(width: size * 0.62, height: size * 0.62)

                // Tick marks
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(color.opacity(0.85))
                        .frame(width: 1.5, height: i % 3 == 0 ? 5 : 3)
                        .offset(y: -size * 0.27)
                        .rotationEffect(.degrees(Double(i) * 30))
                }

                // Hour hand
                Rectangle()
                    .fill(color)
                    .frame(width: 2.5, height: size * 0.18)
                    .offset(y: -size * 0.09)
                    .rotationEffect(.degrees(rotation * 0.05))

                // Minute hand
                Rectangle()
                    .fill(color)
                    .frame(width: 1.8, height: size * 0.24)
                    .offset(y: -size * 0.12)
                    .rotationEffect(.degrees(rotation * 0.12))

                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
