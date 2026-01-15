import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  PureShot 极简色彩系统 - 6 色 + 透明度变体
//  禁止蓝紫色渐变，使用 Cream（奶油白）和深邃灰
// ═══════════════════════════════════════════════════════════════

extension Color {

    // ─────────────────────────────────────────────────────────────
    //  1. 背景色 (Background)
    //  Light: #FAFAFA (近白)  Dark: #0A0A0A (近黑)
    // ─────────────────────────────────────────────────────────────
    static let psBackground = Color("Background", bundle: nil)

    static var psBackgroundAdaptive: Color {
        Color(light: Color(hex: 0xFAFAFA), dark: Color(hex: 0x0A0A0A))
    }

    // ─────────────────────────────────────────────────────────────
    //  2. 表面色 (Surface) - 卡片、浮层
    //  Light: #FFFFFF  Dark: #1C1C1E
    // ─────────────────────────────────────────────────────────────
    static let psSurface = Color("Surface", bundle: nil)

    static var psSurfaceAdaptive: Color {
        Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1C1C1E))
    }

    // ─────────────────────────────────────────────────────────────
    //  3. 主文字 (Text Primary)
    //  Light: #1A1A1A  Dark: #F5F5F5
    // ─────────────────────────────────────────────────────────────
    static let psTextPrimary = Color("TextPrimary", bundle: nil)

    static var psTextPrimaryAdaptive: Color {
        Color(light: Color(hex: 0x1A1A1A), dark: Color(hex: 0xF5F5F5))
    }

    // ─────────────────────────────────────────────────────────────
    //  4. 次级文字 (Text Secondary)
    //  Light: #6B6B6B  Dark: #8E8E93
    // ─────────────────────────────────────────────────────────────
    static let psTextSecondary = Color("TextSecondary", bundle: nil)

    static var psTextSecondaryAdaptive: Color {
        Color(light: Color(hex: 0x6B6B6B), dark: Color(hex: 0x8E8E93))
    }

    // ─────────────────────────────────────────────────────────────
    //  5. 强调色 (Accent) - Cream 奶油色 ⭐ 品牌色
    //  统一: #F5E6D3 (Cream)
    //  用途: 光波、高亮、选中态、品牌标识
    // ─────────────────────────────────────────────────────────────
    static let psAccent = Color(hex: 0xF5E6D3)

    // ─────────────────────────────────────────────────────────────
    //  6. 警示色 (Destructive) - 删除操作
    //  统一: #FF6B6B (柔和红)
    //  用途: 删除数量、警示信息
    // ─────────────────────────────────────────────────────────────
    static let psDestructive = Color(hex: 0xFF6B6B)
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Opacity Variants

extension Color {
    /// 透明度变体 - 用于光波效果
    /// 100% 实体/焦点元素 | 80% 强调/高亮 | 40% 中等/过渡态 | 15% 微弱/背景光晕

    var highlight: Color { self.opacity(0.8) }
    var medium: Color { self.opacity(0.4) }
    var subtle: Color { self.opacity(0.15) }
}
