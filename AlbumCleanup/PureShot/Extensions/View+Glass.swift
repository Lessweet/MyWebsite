import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  液态玻璃 (Liquid Glass) Modifier
//  iOS 26 设计语言 - 表面张力质感
// ═══════════════════════════════════════════════════════════════

extension View {

    /// 液态玻璃材质效果
    /// - Parameters:
    ///   - cornerRadius: 圆角半径
    ///   - blur: 模糊强度
    ///   - opacity: 背景透明度
    func liquidGlass(
        cornerRadius: CGFloat = 24,
        blur: CGFloat = 20,
        opacity: Double = 0.08
    ) -> some View {
        self.modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            blur: blur,
            backgroundOpacity: opacity
        ))
    }

    /// 液态透镜边缘效果 - 模拟水滴表面张力
    func liquidLensEdge() -> some View {
        self.modifier(LiquidLensEdgeModifier())
    }

    /// 选中态光波边框
    func selectionGlow(isSelected: Bool) -> some View {
        self.modifier(SelectionGlowModifier(isSelected: isSelected))
    }
}

// MARK: - Liquid Glass Modifier

struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let blur: CGFloat
    let backgroundOpacity: Double

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // 毛玻璃背景
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // 表面色叠加
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(backgroundOpacity)
                              : Color.black.opacity(backgroundOpacity * 0.5))

                    // 顶部高光线 - 模拟玻璃边缘折射
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Liquid Lens Edge Modifier

struct LiquidLensEdgeModifier: ViewModifier {
    @State private var breathingPhase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                // 边缘呼吸波动效果
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        Color.psAccent.opacity(0.2),
                        lineWidth: 2 + breathingPhase
                    )
                    .blur(radius: 1)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    breathingPhase = 1
                }
            }
    }
}

// MARK: - Selection Glow Modifier

struct SelectionGlowModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.psAccent, lineWidth: 3)
                        .shadow(color: Color.psAccent.opacity(0.5), radius: 8)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Shimmer Effect

extension View {
    /// 光泽扫过效果
    func shimmer(isActive: Bool) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    GeometryReader { geo in
                        Color.psAccent
                            .opacity(0.3)
                            .mask(
                                LinearGradient(
                                    colors: [.clear, .white, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geo.size.width * 0.5)
                                .offset(x: phase * geo.size.width * 1.5 - geo.size.width * 0.25)
                            )
                    }
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
            }
    }
}
