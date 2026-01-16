import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  FluidMotion - 流体运动计算
//  非线性动画、惯性形变、弹性回弹
// ═══════════════════════════════════════════════════════════════

// MARK: - Custom Animation Curves

extension Animation {
    /// 照片移动动画 - easeInOutQuart
    static var photoMove: Animation {
        .timingCurve(0.76, 0, 0.24, 1, duration: 0.35)
    }

    /// 弹性落定动画
    static var bounceSettle: Animation {
        .spring(response: 0.4, dampingFraction: 0.85)
    }

    /// 液态变形动画
    static var liquidMorph: Animation {
        .spring(response: 0.5, dampingFraction: 0.7)
    }

    /// 柔和淡入淡出
    static var softFade: Animation {
        .easeInOut(duration: 0.25)
    }

    /// 快速响应
    static var snappy: Animation {
        .spring(response: 0.25, dampingFraction: 0.9)
    }
}

// MARK: - Fluid Drag Modifier

struct FluidDragModifier: ViewModifier {
    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    let onDragEnd: (CGSize) -> Void

    func body(content: Content) -> some View {
        content
            .offset(offset)
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .animation(.bounceSettle, value: offset)
            .animation(.snappy, value: isDragging)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        // 带阻尼的拖拽
                        let dampedX = dampedValue(value.translation.width)
                        let dampedY = dampedValue(value.translation.height)
                        offset = CGSize(width: dampedX, height: dampedY)
                    }
                    .onEnded { value in
                        isDragging = false
                        onDragEnd(value.translation)
                        withAnimation(.bounceSettle) {
                            offset = .zero
                        }
                    }
            )
    }

    private func dampedValue(_ value: CGFloat) -> CGFloat {
        let sign = value >= 0 ? 1.0 : -1.0
        let absValue = abs(value)
        // 使用 sqrt 函数创建阻尼效果
        return sign * sqrt(absValue) * 5
    }
}

// MARK: - Vertical Scroll Wheel

struct VerticalScrollWheel<Content: View>: View {
    let items: [AnyHashable]
    @Binding var selectedIndex: Int
    let content: (Int) -> Content

    @State private var scrollOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let itemHeight: CGFloat = 100
    private let visibleItems = 5

    var body: some View {
        GeometryReader { geometry in
            let centerY = geometry.size.height / 2

            ZStack {
                ForEach(Array(items.enumerated()), id: \.offset) { index, _ in
                    let distance = CGFloat(index - selectedIndex)
                    let offset = distance * itemHeight + dragOffset
                    let scale = scaleForOffset(offset)
                    let opacity = opacityForOffset(offset)
                    let blur = blurForOffset(offset)

                    content(index)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .blur(radius: blur)
                        .offset(y: offset)
                        .zIndex(index == selectedIndex ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: centerY)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        let threshold = itemHeight / 2

                        var newIndex = selectedIndex

                        if value.translation.height > threshold || velocity > 100 {
                            newIndex = max(0, selectedIndex - 1)
                        } else if value.translation.height < -threshold || velocity < -100 {
                            newIndex = min(items.count - 1, selectedIndex + 1)
                        }

                        withAnimation(.bounceSettle) {
                            selectedIndex = newIndex
                        }

                        HapticManager.shared.selectionChanged()
                    }
            )
        }
    }

    // 平铺布局：所有照片统一显示，不再基于距离缩放
    private func scaleForOffset(_ offset: CGFloat) -> CGFloat {
        return 1.0
    }

    private func opacityForOffset(_ offset: CGFloat) -> Double {
        return 1.0
    }

    private func blurForOffset(_ offset: CGFloat) -> CGFloat {
        return 0
    }
}

// MARK: - Inertia Deformation

struct InertiaDeformationModifier: ViewModifier {
    let velocity: CGVector
    let maxDeformation: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                x: 1 + clampedDeformation(velocity.dx),
                y: 1 - clampedDeformation(velocity.dy) * 0.5
            )
    }

    private func clampedDeformation(_ value: CGFloat) -> CGFloat {
        let normalized = value / 1000 // 标准化速度
        return min(maxDeformation / 100, max(-maxDeformation / 100, normalized))
    }
}

// MARK: - Ripple Effect

struct RippleEffect: ViewModifier {
    let isActive: Bool
    let color: Color

    @State private var rippleScale: CGFloat = 0.3
    @State private var rippleOpacity: Double = 0

    func body(content: Content) -> some View {
        content
            .background {
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    playRipple()
                }
            }
    }

    private func playRipple() {
        rippleScale = 0.3
        rippleOpacity = 0.8

        withAnimation(.easeOut(duration: 0.4)) {
            rippleScale = 1.5
            rippleOpacity = 0
        }
    }
}

// MARK: - View Extensions

extension View {
    func fluidDrag(onDragEnd: @escaping (CGSize) -> Void) -> some View {
        self.modifier(FluidDragModifier(onDragEnd: onDragEnd))
    }

    func ripple(isActive: Bool, color: Color = .psAccent) -> some View {
        self.modifier(RippleEffect(isActive: isActive, color: color))
    }

    /// 应用液态滚动弯曲效果
    /// 当视图滑动到屏幕边缘时产生向内收缩的弯曲效果
    func liquidScrollEffect() -> some View {
        self.modifier(LiquidScrollModifier())
    }
}

// MARK: - Liquid Scroll Modifier (液态滚动弯曲效果)
// 使用纯 SwiftUI 实现广角镜头/吸入感的 Bezier 曲线边缘
// 卡片在屏幕中间时是正常矩形，滑到边缘时自动变弯，产生果冻般的流动感

struct LiquidScrollModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(LiquidCurvatureEffect())
    }
}

// MARK: - Liquid Curve Shape (液态弯曲形状)
// 使用 Bezier 曲线创建动态弯曲的矩形边缘
// 实现"吸入感"效果：边缘向中心收缩，越靠近边缘弯曲度越高

struct LiquidCurveShape: Shape {
    /// 弯曲强度 (0-1)，0 = 直边，1 = 最大弯曲
    var curvature: CGFloat
    /// 弯曲方向：正数 = 顶部收窄（卡片在屏幕上方），负数 = 底部收窄（卡片在屏幕下方）
    var direction: CGFloat
    /// 圆角半径
    var cornerRadius: CGFloat = 24

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(curvature, direction) }
        set {
            curvature = newValue.first
            direction = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // 最大收缩量为宽度的 20%
        let maxShrink = width * curvature * 0.20

        // 根据方向计算顶部和底部的收缩量
        // direction > 0: 顶部收窄（向上弯曲）
        // direction < 0: 底部收窄（向下弯曲）
        let topShrink = direction > 0 ? maxShrink * abs(direction) : 0
        let bottomShrink = direction < 0 ? maxShrink * abs(direction) : 0

        // 计算四个角的实际位置
        let topLeft = CGPoint(x: topShrink, y: 0)
        let topRight = CGPoint(x: width - topShrink, y: 0)
        let bottomRight = CGPoint(x: width - bottomShrink, y: height)
        let bottomLeft = CGPoint(x: bottomShrink, y: height)

        // 开始绘制路径 - 从顶部左侧开始（加上圆角偏移）
        path.move(to: CGPoint(x: topLeft.x + cornerRadius, y: topLeft.y))

        // 顶部边缘 - 直线
        path.addLine(to: CGPoint(x: topRight.x - cornerRadius, y: topRight.y))

        // 右上角圆角
        path.addQuadCurve(
            to: CGPoint(x: topRight.x, y: topRight.y + cornerRadius),
            control: topRight
        )

        // 右边缘 - 使用三次 Bezier 曲线创建平滑的弯曲效果
        // 控制点向外凸出，创建"膨胀"的边缘效果
        let rightBulge = curvature * width * 0.08 // 边缘外凸量
        path.addCurve(
            to: CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadius),
            control1: CGPoint(x: topRight.x + rightBulge, y: height * 0.35),
            control2: CGPoint(x: bottomRight.x + rightBulge, y: height * 0.65)
        )

        // 右下角圆角
        path.addQuadCurve(
            to: CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y),
            control: bottomRight
        )

        // 底部边缘 - 直线
        path.addLine(to: CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y))

        // 左下角圆角
        path.addQuadCurve(
            to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius),
            control: bottomLeft
        )

        // 左边缘 - 使用三次 Bezier 曲线创建平滑的弯曲效果
        let leftBulge = curvature * width * 0.08 // 边缘外凸量
        path.addCurve(
            to: CGPoint(x: topLeft.x, y: topLeft.y + cornerRadius),
            control1: CGPoint(x: bottomLeft.x - leftBulge, y: height * 0.65),
            control2: CGPoint(x: topLeft.x - leftBulge, y: height * 0.35)
        )

        // 左上角圆角
        path.addQuadCurve(
            to: CGPoint(x: topLeft.x + cornerRadius, y: topLeft.y),
            control: topLeft
        )

        path.closeSubpath()
        return path
    }
}

// ═══════════════════════════════════════════════════════════════
// 液态弯曲效果修饰器
// 使用 Metal Shader + visualEffect 实现 iOS 26 风格的液态滚动
//
// 视觉预期：
// - 滑动中：整个照片列表作为一个整体弯曲，中央最宽，上下边缘收窄
// - 减速中：弯曲随速度减弱自然恢复，不用等到完全停止
// - 静止时：所有照片都是完美的高质感圆角卡片，无任何扭曲
// - 关键改进：弯曲强度跟随滚动速度，减速时自然恢复到直线
// ═══════════════════════════════════════════════════════════════
private struct LiquidCurvatureEffect: ViewModifier {
    // 观察全局参数，确保 SwiftUI 追踪变化
    private var params = LiquidBendParameters.shared

    // 平滑后的速度值，用于弯曲计算
    @State private var smoothedSpeed: CGFloat = 0

    func body(content: Content) -> some View {
        // 在 body 中访问参数，让 SwiftUI 追踪这些 @Observable 属性
        let scrollSpeed = params.scrollSpeed
        let isScrolling = params.isScrolling
        let isDecelerating = params.isDecelerating
        let intensity = params.intensity
        let scaleEffect = params.scaleEffect
        let opacityEffect = params.opacityEffect

        // 计算有效速度
        // - 滚动中：保底 0.8 + 速度加成
        // - 停止：使用平滑恢复的 smoothedSpeed
        let effectiveSpeed: CGFloat = {
            if isScrolling {
                // 滚动中：保底值确保有效果
                return max(0.8, scrollSpeed)
            } else {
                // 已停止：使用平滑动画值恢复
                return smoothedSpeed
            }
        }()

        content
            .visualEffect { view, proxy in
                let frame = proxy.frame(in: .global)
                let size = proxy.size

                let screenHeight = UIScreen.main.bounds.height
                let screenCenterY = screenHeight / 2

                // ═══════════════════════════════════════════════════════
                // 全局弯曲场：沙漏形状
                // - 弯曲强度只由速度决定
                // - Shader 内部根据像素在屏幕的Y位置计算收缩量
                // - 屏幕中心最窄，上下边缘正常宽度
                // ═══════════════════════════════════════════════════════

                // 弯曲强度 = 基础强度 × 速度因子
                let strength = Float(intensity * effectiveSpeed)

                // shader 在有弯曲时启用
                let isEffectActive = effectiveSpeed > 0.01

                return view
                    .distortionEffect(
                        ShaderLibrary.liquidBendGlobal(
                            .float2(size.width, size.height),  // 视图尺寸
                            .float(strength),                   // 弯曲强度（只由速度决定）
                            .float(frame.minY),                 // 卡片顶部在屏幕上的 Y 坐标
                            .float(screenHeight),               // 屏幕高度
                            .float(screenCenterY)               // 屏幕中心 Y 坐标
                        ),
                        maxSampleOffset: CGSize(width: 200, height: 100),
                        isEnabled: isEffectActive
                    )
            }
            // 监听滚动停止，使用弹簧动画平滑恢复最后一点弯曲
            .onChange(of: isScrolling) { _, newValue in
                if !newValue {
                    // 完全停止时，非常缓慢柔和地恢复弯曲
                    withAnimation(.easeInOut(duration: 1.6)) {
                        smoothedSpeed = 0
                    }
                }
            }
            // 减速过程中实时跟踪速度
            .onChange(of: scrollSpeed) { _, newSpeed in
                if params.isDecelerating {
                    // 减速中：平滑跟随速度变化
                    smoothedSpeed = newSpeed
                } else if params.isScrolling {
                    // 主动滚动中：记录当前速度
                    smoothedSpeed = newSpeed
                }
            }
    }
}

// MARK: - Liquid Bend View Modifier (完整液态弯曲效果)
// 结合 clipShape 和 visualEffect 实现完整的液态边缘效果

struct LiquidBendModifier: ViewModifier {
    /// 弯曲强度 (0-1)
    let curvature: CGFloat
    /// 弯曲方向
    let direction: CGFloat

    func body(content: Content) -> some View {
        content
            .clipShape(LiquidCurveShape(curvature: curvature, direction: direction))
    }
}

extension View {
    /// 应用液态弯曲裁剪效果
    /// - Parameters:
    ///   - curvature: 弯曲强度 (0-1)
    ///   - direction: 弯曲方向，负数向上弯，正数向下弯
    func liquidBend(curvature: CGFloat, direction: CGFloat = 0) -> some View {
        self.modifier(LiquidBendModifier(curvature: curvature, direction: direction))
    }
}
