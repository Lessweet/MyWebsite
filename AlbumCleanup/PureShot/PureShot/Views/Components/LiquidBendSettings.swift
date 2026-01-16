import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  LiquidBendSettings - 液态弯曲效果参数调节器
//  使用 iOS 26 原生 Liquid Glass 样式
// ═══════════════════════════════════════════════════════════════

// MARK: - 全局参数存储

@Observable
class LiquidBendParameters {
    static let shared = LiquidBendParameters()

    /// 是否正在滚动/拖动 - 只有在交互时才产生扭曲
    var isScrolling: Bool = false

    /// 是否正在减速惯性滚动（手指已离开，但还在滑动）
    var isDecelerating: Bool = false

    /// 滚动速度 (归一化 0-1) - 速度越快弯曲越强，减速时弯曲自然减弱
    var scrollSpeed: Double = 0

    /// 弯曲强度 (0-2) - 控制液态收缩的程度
    var intensity: Double = 0.4

    /// 触发区域比例 (0.05-0.3) - 屏幕边缘多大范围内开始变形
    /// 0.15 表示屏幕上下各15%的区域会触发变形，中间70%不变形
    var triggerZone: Double = 0.15

    /// 缩放效果强度 (0-0.3) - 接近边缘时的缩小程度
    var scaleEffect: Double = 0.05

    /// 透明度效果强度 (0-0.5) - 接近边缘时的淡出程度
    var opacityEffect: Double = 0.15

    private init() {}

    func reset() {
        intensity = 0.4
        triggerZone = 0.15
        scaleEffect = 0.05
        opacityEffect = 0.15
    }
}

// MARK: - 紧凑型参数调节面板（右上角内联显示）

@available(iOS 26.0, *)
struct LiquidBendSettingsPanel: View {
    @Bindable var params = LiquidBendParameters.shared

    var body: some View {
        VStack(spacing: 12) {
            // 标题
            HStack {
                Text("Liquid Bend")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        params.reset()
                    }
                } label: {
                    Text("Reset")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
            }

            Divider()
                .opacity(0.3)

            // 参数滑块
            CompactSlider(title: "Intensity", value: $params.intensity, range: 0...2)
            CompactSlider(title: "Zone", value: $params.triggerZone, range: 0.05...0.3)
            CompactSlider(title: "Scale", value: $params.scaleEffect, range: 0...0.3)
            CompactSlider(title: "Opacity", value: $params.opacityEffect, range: 0...0.5)
        }
        .padding(16)
        .frame(width: 200)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - 紧凑型滑块

@available(iOS 26.0, *)
struct CompactSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.secondary)
            }

            Slider(value: $value, in: range)
                .tint(Color.accentColor)
                .scaleEffect(y: 0.8)
        }
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            HStack {
                Spacer()
                LiquidBendSettingsPanel()
                    .padding()
            }
            Spacer()
        }
    }
}
