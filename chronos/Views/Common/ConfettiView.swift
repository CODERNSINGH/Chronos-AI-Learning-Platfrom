import SwiftUI

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    @State private var animationTask: Task<Void, Never>?

    struct Particle: Identifiable {
        let id = UUID()
        let xRatio: Double          // 0...1 of width
        let startX: CGFloat
        let endX: CGFloat
        let color: Color
        let rotation: Double
        let size: CGFloat
        let delay: Double
        let fallDuration: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    ConfettiPiece(particle: p, height: geo.size.height)
                }
            }
            .onAppear {
                spawn(in: geo.size)
            }
            .onDisappear {
                animationTask?.cancel()
            }
        }
        .allowsHitTesting(false)
    }

    private func spawn(in size: CGSize) {
        let colors: [Color] = [
            ChronosTheme.amber, ChronosTheme.amberBright, ChronosTheme.success,
            ChronosTheme.danger, ChronosTheme.info, Color.white, Color.purple
        ]
        var newParticles: [Particle] = []
        for _ in 0..<80 {
            let xRatio = Double.random(in: 0.05...0.95)
            let startX = CGFloat(xRatio) * size.width
            let endX = startX + CGFloat.random(in: -120...120)
            let p = Particle(
                xRatio: xRatio,
                startX: startX,
                endX: endX,
                color: colors.randomElement() ?? ChronosTheme.amber,
                rotation: Double.random(in: 0...720),
                size: CGFloat.random(in: 6...12),
                delay: Double.random(in: 0...0.4),
                fallDuration: Double.random(in: 1.6...2.6)
            )
            newParticles.append(p)
        }
        particles = newParticles
    }
}

private struct ConfettiPiece: View {
    let particle: ConfettiView.Particle
    let height: CGFloat

    @State private var animate: Bool = false

    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 1.6)
            .rotationEffect(.degrees(animate ? particle.rotation : 0))
            .position(
                x: animate ? particle.endX : particle.startX,
                y: animate ? height + 20 : -20
            )
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: particle.fallDuration).delay(particle.delay)) {
                    animate = true
                }
            }
    }
}
