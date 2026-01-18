import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  View+Glass - iOS 26 原生 Liquid Glass 效果扩展
//  按照 README 规范：全部使用原生 .glassEffect() API
//  不自定义毛玻璃参数、圆角、阴影、边框
// ═══════════════════════════════════════════════════════════════

// MARK: - Native Glass Effect Convenience Extensions

@available(iOS 26.0, *)
extension View {

    /// 应用标准液态玻璃效果 (使用原生 API)
    /// - Parameter cornerRadius: 圆角半径
    func liquidGlass(cornerRadius: CGFloat = 24) -> some View {
        self.glassEffect(
            .regular,
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }

    /// 应用带品牌色调的液态玻璃 (使用原生 API)
    func liquidGlassTinted(cornerRadius: CGFloat = 24) -> some View {
        self.glassEffect(
            .regular.tint(Color.psAccent),
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }

    /// 应用可交互的液态玻璃 (按钮/控件，使用原生 API)
    func liquidGlassInteractive(cornerRadius: CGFloat = 24) -> some View {
        self.glassEffect(
            .regular.tint(Color.psAccent).interactive(),
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }

    /// 应用胶囊形液态玻璃 (使用原生 API)
    func liquidGlassCapsule() -> some View {
        self.glassEffect(.regular, in: Capsule())
    }

    /// 应用胶囊形品牌色液态玻璃 (使用原生 API)
    func liquidGlassCapsuleTinted() -> some View {
        self.glassEffect(
            .regular.tint(Color.psAccent).interactive(),
            in: Capsule()
        )
    }

    /// 应用圆形液态玻璃 (使用原生 API)
    func liquidGlassCircle() -> some View {
        self.glassEffect(.regular, in: Circle())
    }
}

// MARK: - Selection State (使用原生样式)

extension View {
    /// 选中态边框 - 使用简单的原生边框样式
    func selectionBorder(isSelected: Bool, cornerRadius: CGFloat = 16) -> some View {
        self.overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.psAccent, lineWidth: 3)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Note: CheckMark and DissolvingPhotoView are defined in PhotoThumbnail.swift
// Note: CompletionToast is defined in DynamicIslandToast.swift
// Note: ResultCard and GroupCard are defined in GlassCard.swift

// ═══════════════════════════════════════════════════════════════
//  Liquid Expand Navigation - 液态展开导航
//  从照片卡片展开到详情页，带弯曲形变 + 弹性回拨
// ═══════════════════════════════════════════════════════════════

// MARK: - Liquid Expand Navigation Extension

@available(iOS 26.0, *)
extension View {
    /// 添加液态展开导航能力（展开后显示目标内容）
    func liquidExpandNavigation<Destination: View>(
        isPresented: Binding<Bool>,
        heroImage: UIImage?,
        sourceFrame: CGRect,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        self.modifier(
            LiquidExpandNavigationModifier(
                isPresented: isPresented,
                heroImage: heroImage,
                sourceFrame: sourceFrame,
                destination: destination
            )
        )
    }
}

// MARK: - Liquid Expand Navigation Modifier

@available(iOS 26.0, *)
struct LiquidExpandNavigationModifier<Destination: View>: ViewModifier {
    @Binding var isPresented: Bool
    let heroImage: UIImage?
    let sourceFrame: CGRect
    @ViewBuilder let destination: () -> Destination

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                LiquidExpandTransition(
                    heroImage: heroImage,
                    startFrame: sourceFrame,
                    onDismiss: {
                        isPresented = false
                    },
                    content: destination
                )
                .background(LiquidExpandClearBackground())
            }
    }
}

// MARK: - Liquid Expand Transition

@available(iOS 26.0, *)
struct LiquidExpandTransition<Content: View>: View {
    let heroImage: UIImage?
    let startFrame: CGRect
    let onDismiss: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var progress: CGFloat = 0
    @State private var hasTriggeredHaptic = false
    @State private var backgroundOpacity: CGFloat = 0
    @State private var showContent = false

    private let springResponse: CGFloat = 0.55
    private let springDamping: CGFloat = 0.75
    private let bendIntensity: CGFloat = 0.8

    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let screenSize = geometry.size

            let endFrame = CGRect(
                x: 0,
                y: -safeArea.top,
                width: screenSize.width,
                height: screenSize.height + safeArea.top + safeArea.bottom
            )

            let clampedProgress = min(max(progress, 0), 1.2)
            let currentFrame = interpolateFrame(
                from: startFrame,
                to: endFrame,
                progress: min(clampedProgress, 1.0)
            )

            let currentCornerRadius = interpolateValue(
                from: 24,
                to: 0,
                progress: min(clampedProgress, 1.0)
            )

            ZStack {
                Color(uiColor: .systemBackground)
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()

                if !showContent, let image = heroImage {
                    heroPhotoLayer(
                        image: image,
                        currentFrame: currentFrame,
                        cornerRadius: currentCornerRadius
                    )
                }

                if showContent {
                    content()
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                startExpandAnimation()
            }
        }
    }

    private func heroPhotoLayer(
        image: UIImage,
        currentFrame: CGRect,
        cornerRadius: CGFloat
    ) -> some View {
        LiquidExpandAnimatableView(progress: progress) { animatedProgress in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: currentFrame.width, height: currentFrame.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .modifier(
                    LiquidExpandEffectModifier(
                        progress: animatedProgress,
                        bendIntensity: bendIntensity,
                        onOvershootPeak: {
                            if !hasTriggeredHaptic {
                                triggerOvershootHaptic()
                                hasTriggeredHaptic = true
                            }
                        }
                    )
                )
                .position(
                    x: currentFrame.midX,
                    y: currentFrame.midY
                )
        }
    }

    private func startExpandAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1.0
        }

        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            progress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                showContent = true
            }
        }
    }

    private func triggerOvershootHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }

    private func interpolateFrame(from: CGRect, to: CGRect, progress: CGFloat) -> CGRect {
        let p = max(0, min(1, progress))
        return CGRect(
            x: from.origin.x + (to.origin.x - from.origin.x) * p,
            y: from.origin.y + (to.origin.y - from.origin.y) * p,
            width: from.width + (to.width - from.width) * p,
            height: from.height + (to.height - from.height) * p
        )
    }

    private func interpolateValue(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
        let p = max(0, min(1, progress))
        return from + (to - from) * p
    }
}

// MARK: - Animatable Progress View

struct LiquidExpandAnimatableView<Content: View>: View, Animatable {
    var progress: CGFloat
    let content: (CGFloat) -> Content

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        content(progress)
    }
}

// MARK: - Liquid Expand Effect Modifier

@available(iOS 26.0, *)
struct LiquidExpandEffectModifier: ViewModifier {
    let progress: CGFloat
    let bendIntensity: CGFloat
    let onOvershootPeak: () -> Void

    @State private var lastProgress: CGFloat = 0
    @State private var wasIncreasing = true

    func body(content: Content) -> some View {
        content
            .visualEffect { view, proxy in
                view.distortionEffect(
                    ShaderLibrary.liquidExpand(
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(Float(progress)),
                        .float(Float(bendIntensity))
                    ),
                    maxSampleOffset: .init(width: 100, height: 100)
                )
                .colorEffect(
                    ShaderLibrary.bendBrightness(
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(Float(progress))
                    )
                )
            }
            .onChange(of: progress) { oldValue, newValue in
                let isIncreasing = newValue > oldValue
                if wasIncreasing && !isIncreasing && newValue > 1.0 {
                    onOvershootPeak()
                }
                wasIncreasing = isIncreasing
                lastProgress = newValue
            }
    }
}

// MARK: - Clear Background for FullScreenCover

struct LiquidExpandClearBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = LiquidExpandClearBackgroundUIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private class LiquidExpandClearBackgroundUIView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            superview?.superview?.backgroundColor = .clear
        }
    }
}
