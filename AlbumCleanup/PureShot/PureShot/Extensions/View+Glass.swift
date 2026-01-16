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
