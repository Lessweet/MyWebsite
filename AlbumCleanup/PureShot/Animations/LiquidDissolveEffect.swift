import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  LiquidDissolveEffect - 液态熔化分解动画
//  照片像水一样液态化融化消失
// ═══════════════════════════════════════════════════════════════

struct LiquidDissolveEffect: ViewModifier {
    let isDissolving: Bool
    var duration: Double = Constants.Animation.liquidDissolveDuration

    @State private var dissolveProgress: CGFloat = 0
    @State private var dropletsOpacity: Double = 1

    func body(content: Content) -> some View {
        ZStack {
            // 原始内容 (逐渐消失)
            content
                .opacity(1 - dissolveProgress)
                .blur(radius: dissolveProgress * 4)
                .scaleEffect(1 - dissolveProgress * 0.2, anchor: .top)
                .mask {
                    // 从下往上溶解的遮罩
                    GeometryReader { geo in
                        Rectangle()
                            .frame(height: geo.size.height * (1 - dissolveProgress * 0.8))
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                }

            // 液滴效果
            if dissolveProgress > 0.1 {
                DropletsView(progress: dissolveProgress)
                    .opacity(dropletsOpacity)
            }
        }
        .onChange(of: isDissolving) { _, newValue in
            if newValue {
                startDissolve()
            }
        }
    }

    private func startDissolve() {
        dissolveProgress = 0
        dropletsOpacity = 1

        // 主溶解动画
        withAnimation(.easeOut(duration: duration)) {
            dissolveProgress = 1
        }

        // 液滴消散
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.7) {
            withAnimation(.easeOut(duration: duration * 0.3)) {
                dropletsOpacity = 0
            }
        }
    }
}

// MARK: - Droplets View

struct DropletsView: View {
    let progress: CGFloat

    @State private var droplets: [LiquidDroplet] = []

    struct LiquidDroplet: Identifiable {
        let id = UUID()
        var x: CGFloat
        var startY: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var delay: Double
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(droplets) { droplet in
                Circle()
                    .fill(Color.psTextSecondaryAdaptive.opacity(0.5))
                    .frame(width: droplet.size, height: droplet.size)
                    .position(
                        x: geo.size.width / 2 + droplet.x,
                        y: droplet.startY + progress * droplet.speed * geo.size.height
                    )
                    .blur(radius: progress * 2)
                    .opacity(max(0, 1 - progress * 1.5))
            }
        }
        .onAppear {
            generateDroplets()
        }
    }

    private func generateDroplets() {
        droplets.removeAll()

        for i in 0..<12 {
            let droplet = LiquidDroplet(
                x: CGFloat.random(in: -80...80),
                startY: CGFloat.random(in: 20...100),
                size: CGFloat.random(in: 4...16),
                speed: CGFloat.random(in: 0.3...0.8),
                delay: Double(i) * 0.03
            )
            droplets.append(droplet)
        }
    }
}

// MARK: - View Extension

extension View {
    func liquidDissolve(isDissolving: Bool, duration: Double = Constants.Animation.liquidDissolveDuration) -> some View {
        self.modifier(LiquidDissolveEffect(isDissolving: isDissolving, duration: duration))
    }
}

// MARK: - Particle System for Canvas

struct LiquidParticleSystem {
    var particles: [LiquidParticle] = []

    struct LiquidParticle {
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var opacity: Double
        var life: Double
    }

    mutating func emit(from rect: CGRect, count: Int = 20) {
        for _ in 0..<count {
            let particle = LiquidParticle(
                position: CGPoint(
                    x: CGFloat.random(in: rect.minX...rect.maxX),
                    y: CGFloat.random(in: rect.midY...rect.maxY)
                ),
                velocity: CGVector(
                    dx: CGFloat.random(in: -20...20),
                    dy: CGFloat.random(in: 30...80)
                ),
                size: CGFloat.random(in: 3...10),
                opacity: Double.random(in: 0.4...0.8),
                life: 1.0
            )
            particles.append(particle)
        }
    }

    mutating func update(deltaTime: Double) {
        for i in particles.indices.reversed() {
            // 更新位置
            particles[i].position.x += particles[i].velocity.dx * deltaTime
            particles[i].position.y += particles[i].velocity.dy * deltaTime

            // 重力
            particles[i].velocity.dy += 100 * deltaTime

            // 阻尼
            particles[i].velocity.dx *= 0.98
            particles[i].velocity.dy *= 0.98

            // 生命周期
            particles[i].life -= deltaTime
            particles[i].opacity = particles[i].life * 0.8

            // 移除死亡粒子
            if particles[i].life <= 0 {
                particles.remove(at: i)
            }
        }
    }
}

// MARK: - Canvas Particle View

struct LiquidParticleCanvas: View {
    @State private var particleSystem = LiquidParticleSystem()
    @State private var lastUpdate = Date()

    let emitRect: CGRect
    let isActive: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date
                let deltaTime = now.timeIntervalSince(lastUpdate)

                // 更新粒子系统
                DispatchQueue.main.async {
                    particleSystem.update(deltaTime: deltaTime)
                    lastUpdate = now
                }

                // 绘制粒子
                for particle in particleSystem.particles {
                    let rect = CGRect(
                        x: particle.position.x - particle.size / 2,
                        y: particle.position.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    context.fill(
                        Circle().path(in: rect),
                        with: .color(Color.psTextSecondaryAdaptive.opacity(particle.opacity))
                    )
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                particleSystem.emit(from: emitRect)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.psAccent.opacity(0.3))
            .frame(width: 150, height: 150)
            .liquidDissolve(isDissolving: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.psBackgroundAdaptive)
}
