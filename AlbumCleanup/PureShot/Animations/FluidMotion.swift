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

    private func scaleForOffset(_ offset: CGFloat) -> CGFloat {
        let distance = abs(offset) / itemHeight
        return Constants.PhotoScale.scale(for: Int(distance))
    }

    private func opacityForOffset(_ offset: CGFloat) -> Double {
        let distance = abs(offset) / itemHeight
        return Constants.PhotoScale.opacity(for: Int(distance))
    }

    private func blurForOffset(_ offset: CGFloat) -> CGFloat {
        let distance = abs(offset) / itemHeight
        return Constants.PhotoScale.blur(for: Int(distance))
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
}
