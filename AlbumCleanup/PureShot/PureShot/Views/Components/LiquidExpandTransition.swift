import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  LiquidExpandTransition - 液态展开转场
//  从照片卡片展开到详情页，带弯曲形变 + 弹性回拨
//  支持 hero 动画过渡到目标视图内容
// ═══════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct LiquidExpandTransition<Content: View>: View {
    let heroImage: UIImage?
    let startFrame: CGRect
    let onDismiss: () -> Void
    @ViewBuilder let content: () -> Content

    // 动画进度：0 = 缩略图，1 = 全屏，>1 = 过冲
    @State private var progress: CGFloat = 0
    @State private var hasTriggeredHaptic = false

    // 背景状态
    @State private var backgroundOpacity: CGFloat = 0

    // 内容显示状态
    @State private var showContent = false

    // Spring 动画参数
    private let springResponse: CGFloat = 0.55
    private let springDamping: CGFloat = 0.75

    // 弯曲强度
    private let bendIntensity: CGFloat = 0.8

    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let screenSize = geometry.size

            // 计算全屏 frame（考虑安全区域）
            let endFrame = CGRect(
                x: 0,
                y: -safeArea.top,
                width: screenSize.width,
                height: screenSize.height + safeArea.top + safeArea.bottom
            )

            // 插值计算当前 frame
            let clampedProgress = min(max(progress, 0), 1.2)
            let currentFrame = interpolateFrame(
                from: startFrame,
                to: endFrame,
                progress: min(clampedProgress, 1.0)
            )

            // 计算圆角（从缩略图圆角到 0）
            let currentCornerRadius = interpolateValue(
                from: 24,
                to: 0,
                progress: min(clampedProgress, 1.0)
            )

            ZStack {
                // MARK: - 背景层
                Color(uiColor: .systemBackground)
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()

                // MARK: - Hero 照片层（展开中显示）
                if !showContent, let image = heroImage {
                    heroPhotoLayer(
                        image: image,
                        currentFrame: currentFrame,
                        cornerRadius: currentCornerRadius,
                        screenSize: screenSize
                    )
                }

                // MARK: - 目标内容层（展开完成后显示）
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

    // MARK: - Hero Photo Layer

    private func heroPhotoLayer(
        image: UIImage,
        currentFrame: CGRect,
        cornerRadius: CGFloat,
        screenSize: CGSize
    ) -> some View {
        AnimatableProgressView(progress: progress) { animatedProgress in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: currentFrame.width, height: currentFrame.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .modifier(
                    LiquidExpandModifier(
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

    // MARK: - Animation Methods

    private func startExpandAnimation() {
        // 背景渐显
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1.0
        }

        // 照片展开动画（Spring 带过冲）
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            progress = 1.0
        }

        // 展开完成后显示内容
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

    // MARK: - Interpolation Helpers

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
                .background(ClearBackgroundView())
            }
    }
}

@available(iOS 26.0, *)
extension View {
    /// 添加液态展开导航能力
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
