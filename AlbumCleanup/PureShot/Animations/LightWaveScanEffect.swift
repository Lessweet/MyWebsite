import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  LightWaveScanEffect - 光波扫描动画
//  从灵动岛释放，向下推进扫描整个屏幕
// ═══════════════════════════════════════════════════════════════

struct LightWaveScanEffect: View {
    @Binding var isActive: Bool
    var onComplete: (() -> Void)?

    @State private var wavePosition: CGFloat = 0
    @State private var waveOpacity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 光波主体
                LightWaveGradient()
                    .frame(height: 120)
                    .offset(y: wavePosition * geometry.size.height - 60)
                    .opacity(waveOpacity)

                // 光晕残影
                LightWaveGlow()
                    .frame(height: 200)
                    .offset(y: wavePosition * geometry.size.height - 150)
                    .opacity(waveOpacity * 0.5)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                resetAnimation()
            }
        }
    }

    private func startAnimation() {
        wavePosition = 0
        waveOpacity = 0

        // 光波出现
        withAnimation(.easeOut(duration: 0.2)) {
            waveOpacity = 1
        }

        // 光波下推
        withAnimation(.easeInOut(duration: Constants.Animation.lightWaveScanDuration)) {
            wavePosition = 1.2 // 超出屏幕底部
        }

        // 光波消散
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Animation.lightWaveScanDuration * 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                waveOpacity = 0
            }
        }

        // 完成回调
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Animation.lightWaveScanDuration) {
            onComplete?()
        }
    }

    private func resetAnimation() {
        wavePosition = 0
        waveOpacity = 0
    }
}

// MARK: - Light Wave Gradient

struct LightWaveGradient: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.psAccent.opacity(0.0), location: 0),
                .init(color: Color.psAccent.opacity(0.15), location: 0.2),
                .init(color: Color.psAccent.opacity(0.4), location: 0.4),
                .init(color: Color.psAccent.opacity(0.8), location: 0.5), // 核心最亮
                .init(color: Color.psAccent.opacity(0.4), location: 0.6),
                .init(color: Color.psAccent.opacity(0.15), location: 0.8),
                .init(color: Color.psAccent.opacity(0.0), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .blur(radius: 8)
    }
}

// MARK: - Light Wave Glow

struct LightWaveGlow: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.psAccent.opacity(0.0), location: 0),
                .init(color: Color.psAccent.opacity(0.1), location: 0.5),
                .init(color: Color.psAccent.opacity(0.0), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .blur(radius: 20)
    }
}

// MARK: - Dynamic Island Glow

struct DynamicIslandGlow: View {
    @Binding var isActive: Bool

    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0

    var body: some View {
        VStack {
            // 灵动岛光晕
            Capsule()
                .fill(Color.psAccent)
                .frame(width: 126, height: 37) // 灵动岛尺寸
                .blur(radius: 15)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)

            Spacer()
        }
        .padding(.top, 11) // 灵动岛位置
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                // 蓄力发光
                withAnimation(.easeOut(duration: 0.2)) {
                    glowOpacity = 0.8
                    glowScale = 1.5
                }

                // 释放
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        glowScale = 2.0
                        glowOpacity = 0
                    }
                }
            } else {
                glowOpacity = 0
                glowScale = 1.0
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
            .foregroundStyle(Color.psTextSecondaryAdaptive)
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
