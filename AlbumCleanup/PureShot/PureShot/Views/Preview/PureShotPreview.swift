import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  PureShotPreview - 照片清理预览效果
//  物理内爆 + 粒子汇聚灵动岛 + 奶油色呼吸扩展
// ═══════════════════════════════════════════════════════════════

struct PureShotPreview: View {
    @State private var isDeleted = false
    @State private var keptAssets = [1, 2]
    @State private var redundantAssets = [3, 4, 5, 6]

    // 粒子系统状态
    @State private var particles: [Particle] = []
    @State private var showDynamicIslandGlow = false

    // 记录每个照片的随机位置
    @State private var photoPositions: [Int: CGPoint] = [:]

    var body: some View {
        GeometryReader { geometry in
            let dynamicIslandCenter = CGPoint(x: geometry.size.width / 2, y: 60)

            ZStack {
                // 背景：MeshGradient 模拟液态环境
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ], colors: isDeleted ? [.white, .white, .white, .white, .white, .white, .white, .white, .white] :
                    [.white, .blue.opacity(0.1), .white, .blue.opacity(0.05), .white, .blue.opacity(0.1), .white, .white, .white])
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 2.0), value: isDeleted)

                // 灵动岛奶油色呼吸光晕
                DynamicIslandBreathGlow(isActive: $showDynamicIslandGlow)

                // 1. 待删除的照片：物理内爆消散
                ForEach(redundantAssets, id: \.self) { id in
                    let position = photoPositions[id] ?? randomPosition(in: geometry.size)

                    PhotoBubble(id: id)
                        .modifier(LiquidRefractionModifier(isEnabled: !isDeleted))
                        .position(position)
                        // 物理内爆效果
                        .scaleEffect(isDeleted ? 0 : 1.0)
                        .opacity(isDeleted ? 0 : 0.9)
                        .blur(radius: isDeleted ? 20 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6)
                            .delay(Double(id - 3) * 0.12), // 依次内爆，肥皂泡节奏
                            value: isDeleted
                        )
                        .onAppear {
                            // 记录位置用于粒子发射
                            photoPositions[id] = randomPosition(in: geometry.size)
                        }
                }

                // 2. 粒子系统：向灵动岛汇聚
                ForEach(particles) { particle in
                    ParticleView(particle: particle, targetY: dynamicIslandCenter.y)
                }

                // 3. 保留的照片：归位布局
                VStack {
                    Spacer()

                    let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: keptAssets.count > 1 ? 2 : 1)

                    LazyVGrid(columns: columns) {
                        ForEach(keptAssets, id: \.self) { id in
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.08), radius: 20)
                                .frame(height: 200)
                                .overlay(
                                    Text("Best Shot")
                                        .foregroundStyle(.secondary)
                                        .opacity(isDeleted ? 1 : 0.5)
                                )
                                .offset(y: isDeleted ? 0 : CGFloat.random(in: 80...200))
                                .scaleEffect(isDeleted ? 1.0 : 0.85)
                                .opacity(isDeleted ? 1 : 0.6)
                                .animation(
                                    .spring(response: 0.7, dampingFraction: 0.8)
                                    .delay(0.5),
                                    value: isDeleted
                                )
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer()
                }

                // 4. 底部操作按钮
                VStack {
                    Spacer()
                    Button(action: {
                        triggerImplosion(screenSize: geometry.size, dynamicIslandCenter: dynamicIslandCenter)
                    }) {
                        Text(isDeleted ? "已净化 ✓" : "保留 2 张，释放空间")
                            .font(.headline)
                            .foregroundStyle(isDeleted ? .green : .primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .disabled(isDeleted)
                    .padding(.bottom, 50)
                }
            }
        }
    }

    // MARK: - 触发内爆动画

    func triggerImplosion(screenSize: CGSize, dynamicIslandCenter: CGPoint) {
        triggerHaptic()

        // 1. 开始内爆
        withAnimation {
            isDeleted = true
        }

        // 2. 为每个被删除的照片生成粒子
        for (index, id) in redundantAssets.enumerated() {
            let delay = Double(index) * 0.12

            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.2) {
                // 获取照片位置
                let photoPos = photoPositions[id] ?? CGPoint(x: screenSize.width / 2, y: 400)

                // 生成 8-12 个粒子
                let particleCount = Int.random(in: 8...12)
                for i in 0..<particleCount {
                    let particle = Particle(
                        id: UUID(),
                        startPosition: photoPos,
                        targetPosition: dynamicIslandCenter,
                        delay: Double(i) * 0.03,
                        size: CGFloat.random(in: 3...8),
                        color: [Color.white, Color.white.opacity(0.8), Color(hex: 0xFFF8E7)].randomElement()!
                    )
                    particles.append(particle)
                }

                // 触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred(intensity: 0.5)
            }
        }

        // 3. 粒子汇聚完成后，灵动岛呼吸扩展
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                showDynamicIslandGlow = true
            }
            // 重触觉
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        // 4. 清理粒子
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            particles.removeAll()
        }
    }

    func randomPosition(in size: CGSize) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 60...(size.width - 60)),
            y: CGFloat.random(in: 150...500)
        )
    }

    func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 1.0)
    }
}

// MARK: - 照片气泡

struct PhotoBubble: View {
    let id: Int

    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 70, height: 70)
            .overlay {
                Text("📷")
                    .font(.system(size: 32))
            }
            .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

// MARK: - 粒子数据模型

struct Particle: Identifiable {
    let id: UUID
    let startPosition: CGPoint
    let targetPosition: CGPoint
    let delay: Double
    let size: CGFloat
    let color: Color
}

// MARK: - 粒子视图

struct ParticleView: View {
    let particle: Particle
    let targetY: CGFloat

    @State private var progress: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .blur(radius: 1)
            .position(currentPosition)
            .opacity(opacity)
            .onAppear {
                // 粒子飞向灵动岛的动画
                withAnimation(
                    .easeIn(duration: 0.6)
                    .delay(particle.delay)
                ) {
                    progress = 1
                }

                // 到达时消失
                withAnimation(
                    .easeOut(duration: 0.2)
                    .delay(particle.delay + 0.5)
                ) {
                    opacity = 0
                }
            }
    }

    var currentPosition: CGPoint {
        // 贝塞尔曲线路径
        let t = progress

        // 控制点：让粒子有弧形轨迹
        let controlX = (particle.startPosition.x + particle.targetPosition.x) / 2 + CGFloat.random(in: -50...50)
        let controlY = min(particle.startPosition.y, particle.targetPosition.y) - 100

        // 二次贝塞尔曲线
        let x = pow(1-t, 2) * particle.startPosition.x +
                2 * (1-t) * t * controlX +
                pow(t, 2) * particle.targetPosition.x

        let y = pow(1-t, 2) * particle.startPosition.y +
                2 * (1-t) * t * controlY +
                pow(t, 2) * particle.targetPosition.y

        return CGPoint(x: x, y: y)
    }
}

// MARK: - 灵动岛奶油色呼吸光晕

struct DynamicIslandBreathGlow: View {
    @Binding var isActive: Bool

    @State private var breathScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0

    // 奶油色
    let creamColor = Color(red: 1.0, green: 0.97, blue: 0.90)

    var body: some View {
        VStack {
            ZStack {
                // 外层大光晕
                Capsule()
                    .fill(creamColor.opacity(0.4))
                    .frame(width: 180, height: 55)
                    .blur(radius: 35)
                    .scaleEffect(breathScale * 1.8)
                    .opacity(glowOpacity * 0.5)

                // 中层光晕
                Capsule()
                    .fill(creamColor.opacity(0.6))
                    .frame(width: 150, height: 45)
                    .blur(radius: 25)
                    .scaleEffect(breathScale * 1.4)
                    .opacity(glowOpacity * 0.7)

                // 核心光晕
                Capsule()
                    .fill(creamColor)
                    .frame(width: 126, height: 37)
                    .blur(radius: 15)
                    .scaleEffect(breathScale)
                    .opacity(glowOpacity)

                // 白色高光
                Capsule()
                    .fill(Color.white)
                    .frame(width: 100, height: 28)
                    .blur(radius: 10)
                    .scaleEffect(breathScale * 0.9)
                    .opacity(glowOpacity * 0.8)
            }
            .padding(.top, 11)

            Spacer()
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startBreathAnimation()
            }
        }
    }

    func startBreathAnimation() {
        // 呼吸扩展动画
        withAnimation(.easeOut(duration: 0.3)) {
            glowOpacity = 1.0
            breathScale = 1.5
        }

        // 收缩
        withAnimation(.easeInOut(duration: 0.4).delay(0.3)) {
            breathScale = 1.2
        }

        // 再次扩展
        withAnimation(.easeInOut(duration: 0.3).delay(0.7)) {
            breathScale = 1.6
        }

        // 最终消散
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            breathScale = 2.0
            glowOpacity = 0
        }
    }
}

// MARK: - Shader 包装器

struct LiquidRefractionModifier: ViewModifier {
    var isEnabled: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.visualEffect { content, proxy in
                content.layerEffect(
                    ShaderLibrary.lensDistortion(
                        .float2(proxy.size),
                        .float(isEnabled ? 0.15 : 0.0)
                    ),
                    maxSampleOffset: .zero
                )
            }
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    PureShotPreview()
}
