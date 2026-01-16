import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  LightWaveScanEffect - Genie AI 风格光波扫描
//  使用 Metal Shader 实现折射扭曲效果
//  光源：灵动岛
//  形态：折射光波，水波纹扭曲
//  扩散：从灵动岛向下柔和扩散
// ═══════════════════════════════════════════════════════════════

struct LightWaveScanEffect: View {
    @Binding var isActive: Bool
    var onComplete: (() -> Void)?

    // 动画状态
    @State private var animationTime: CGFloat = 0
    @State private var waveY: CGFloat = 0           // 波前沿Y位置 (像素)
    @State private var intensity: CGFloat = 0       // 效果强度
    @State private var startDate: Date = .now

    var body: some View {
        GeometryReader { geometry in
            // 时间驱动动画
            TimelineView(.animation(minimumInterval: 1/60)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)

                // 光晕层 - 柔和的光照效果
                Rectangle()
                    .fill(Color.clear)
                    .overlay {
                        // 顶部光晕渐变
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.18 * intensity), location: 0),
                                .init(color: Color.white.opacity(0.10 * intensity), location: waveY / geometry.size.height * 0.4),
                                .init(color: Color.white.opacity(0.04 * intensity), location: waveY / geometry.size.height * 0.8),
                                .init(color: Color.clear, location: max(0.01, waveY / geometry.size.height))
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                    // Metal Shader: 波纹折射扭曲
                    .distortionEffect(
                        ShaderLibrary.softRipple(
                            .float(elapsed),
                            .float(waveY),
                            .float(3.0 * intensity)  // 扭曲幅度
                        ),
                        maxSampleOffset: CGSize(width: 10, height: 10)
                    )
                    // 波前沿高亮边缘
                    .overlay {
                        WaveEdgeGlow(waveY: waveY, intensity: intensity, screenHeight: geometry.size.height)
                    }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                resetAnimation()
            }
        }
    }

    private func startAnimation() {
        resetAnimation()
        startDate = .now

        let duration = Constants.Animation.lightWaveScanDuration

        // 第一阶段：灵动岛发光，波开始
        withAnimation(.easeOut(duration: 0.25)) {
            intensity = 1.0
            waveY = 150
        }

        // 第二阶段：光波向下扫描
        withAnimation(.easeOut(duration: duration).delay(0.2)) {
            waveY = 1200  // 扫描整个屏幕
        }

        // 第三阶段：光波消散
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.65) {
            withAnimation(.easeOut(duration: duration * 0.45)) {
                intensity = 0
            }
        }

        // 完成回调
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onComplete?()
        }
    }

    private func resetAnimation() {
        waveY = 0
        intensity = 0
        animationTime = 0
    }
}

// MARK: - Wave Edge Glow (波前沿光晕)

struct WaveEdgeGlow: View {
    let waveY: CGFloat
    let intensity: CGFloat
    let screenHeight: CGFloat

    var body: some View {
        Canvas { context, size in
            guard intensity > 0 && waveY > 0 else { return }

            // 波前沿的弧形高亮
            let edgePath = Path { path in
                path.move(to: CGPoint(x: 0, y: waveY))
                path.addQuadCurve(
                    to: CGPoint(x: size.width, y: waveY),
                    control: CGPoint(x: size.width / 2, y: waveY + 30)
                )
                path.addLine(to: CGPoint(x: size.width, y: waveY - 60))
                path.addQuadCurve(
                    to: CGPoint(x: 0, y: waveY - 60),
                    control: CGPoint(x: size.width / 2, y: waveY - 30)
                )
                path.closeSubpath()
            }

            // 柔和的白色边缘光
            let gradient = Gradient(colors: [
                Color.white.opacity(0),
                Color.white.opacity(0.15 * intensity),
                Color.white.opacity(0.08 * intensity),
                Color.white.opacity(0)
            ])

            context.fill(
                edgePath,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: size.width / 2, y: waveY - 60),
                    endPoint: CGPoint(x: size.width / 2, y: waveY + 30)
                )
            )

            context.addFilter(.blur(radius: 20))
        }
    }
}

// MARK: - Light Wave Gradient (保留兼容)

struct LightWaveGradient: View {
    var body: some View {
        EmptyView()
    }
}

// MARK: - Light Wave Glow (保留兼容)

struct LightWaveGlow: View {
    var body: some View {
        EmptyView()
    }
}

// MARK: - Dynamic Island Glow

struct DynamicIslandGlow: View {
    @Binding var isActive: Bool

    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack {
            ZStack {
                // 外层光晕 - 更大更柔和
                Capsule()
                    .fill(Color.psAccent.opacity(0.3))
                    .frame(width: 140, height: 45)
                    .blur(radius: 30)
                    .scaleEffect(glowScale * 1.5)
                    .opacity(glowOpacity * 0.6)

                // 中层光晕
                Capsule()
                    .fill(Color.psAccent.opacity(0.6))
                    .frame(width: 126, height: 37)
                    .blur(radius: 20)
                    .scaleEffect(glowScale * 1.2)
                    .opacity(glowOpacity * 0.8)

                // 核心光晕 - 最亮
                Capsule()
                    .fill(Color.psAccent)
                    .frame(width: 126, height: 37)
                    .blur(radius: 12)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)

                // 白色高光
                Capsule()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 100, height: 28)
                    .blur(radius: 8)
                    .scaleEffect(pulseScale)
                    .opacity(glowOpacity * 0.7)
            }

            Spacer()
        }
        .padding(.top, 11) // 灵动岛位置
        .allowsHitTesting(false)
        .onAppear {
            if isActive {
                startGlowAnimation()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startGlowAnimation()
            } else {
                glowOpacity = 0
                glowScale = 1.0
                pulseScale = 1.0
            }
        }
    }

    private func startGlowAnimation() {
        // 重置状态
        glowScale = 1.0
        pulseScale = 1.0
        glowOpacity = 0

        // 蓄力发光
        withAnimation(.easeOut(duration: 0.3)) {
            glowOpacity = 1.0
            glowScale = 1.8
            pulseScale = 1.3
        }

        // 脉冲效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.15)) {
                pulseScale = 1.5
            }
        }

        // 释放扩散
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                glowScale = 3.0
                glowOpacity = 0
                pulseScale = 2.0
            }
        }
    }
}

// MARK: - Scanning Text Animation

struct ScanningTextView: View {
    @Binding var isScanning: Bool

    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("正在扫描您的相册" + String(repeating: ".", count: dotCount))
            .font(.subheadline)
            .foregroundStyle(Color(hex: 0x8E8E93)) // 深色背景下使用浅色文字
            .onReceive(timer) { _ in
                if isScanning {
                    dotCount = (dotCount + 1) % 4
                }
            }
            .opacity(isScanning ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isScanning)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.psBackgroundAdaptive
            .ignoresSafeArea()

        LightWaveScanEffect(isActive: .constant(true))
    }
}
