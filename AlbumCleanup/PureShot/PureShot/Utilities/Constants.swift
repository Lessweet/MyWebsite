import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  Constants - 全局常量定义
//  动画参数、布局尺寸、相似度阈值
// ═══════════════════════════════════════════════════════════════

enum Constants {

    // MARK: - Animation Timing

    enum Animation {
        /// 光波扫描总时长
        static let lightWaveScanDuration: Double = 1.8

        /// 照片涌入动画时长
        static let photoSurgeInDuration: Double = 0.35

        /// 液态融化动画时长
        static let liquidDissolveDuration: Double = 0.6

        /// 选中光波扩散时长
        static let selectionRippleDuration: Double = 0.2

        /// 弹跳动画 Spring 参数
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.85

        /// 底部操作栏滑入时长
        static let actionBarSlideDuration: Double = 0.35

        /// 文字扫光间隔
        static let textRevealInterval: Double = 0.05
    }

    // MARK: - Layout

    enum Layout {
        /// 屏幕边距
        static let horizontalPadding: CGFloat = 20

        /// 卡片圆角
        static let cardCornerRadius: CGFloat = 24

        /// 照片圆角
        static let photoCornerRadius: CGFloat = 16

        /// 纵向平铺布局照片间距
        static let flatListPhotoSpacing: CGFloat = 12

        /// 底部操作栏高度
        static let actionBarHeight: CGFloat = 56

        /// 底部安全区
        static let bottomSafeArea: CGFloat = 34

        /// 灵动岛提示条高度
        static let toastHeight: CGFloat = 48

        /// 灵动岛提示条圆角
        static let toastCornerRadius: CGFloat = 22
    }

    // MARK: - Liquid Scroll Effect (液态滚动效果参数)

    enum LiquidScroll {
        /// 边缘形变最大幅度
        static let maxDeformation: CGFloat = 8.0

        /// 形变系数 (滚动速度 × 系数)
        static let deformationFactor: CGFloat = 0.05

        /// 恢复动画时长
        static let recoveryDuration: Double = 0.2

        /// 恢复动画阻尼
        static let recoveryDamping: CGFloat = 0.7

        /// 涟漪强度系数
        static let rippleFactor: CGFloat = 0.02

        /// 涟漪衰减时长
        static let rippleDecay: Double = 0.15
    }

    // MARK: - Similarity Engine

    enum Similarity {
        /// 相似度阈值 (0-1)，大于此值视为相似照片
        /// Vision 框架特征距离通常在 0-20 之间
        /// 0.5 = 距离 7.5 以内视为相似
        static let threshold: Float = 0.5

        /// 时间聚类窗口 (秒)，5分钟内的照片可能聚类
        static let timeWindowSeconds: TimeInterval = 300

        /// 位置聚类半径 (米)
        static let locationRadiusMeters: Double = 100

        /// 下采样尺寸 (用于特征提取)
        static let downsampleSize: CGSize = CGSize(width: 224, height: 224)

        /// 最大并行处理数
        static let maxConcurrentTasks: Int = 4
    }

    // MARK: - Haptic Patterns

    enum Haptic {
        /// 选中照片
        static let selectionIntensity: Float = 0.6

        /// 取消选中
        static let deselectionIntensity: Float = 0.3

        /// 确认删除
        static let confirmIntensity: Float = 0.8

        /// 液态融化持续震动间隔
        static let dissolveInterval: TimeInterval = 0.05
    }
}

// MARK: - Device Detection

@MainActor
enum DeviceCapability {
    /// 是否支持高性能动画 (A17+ 芯片)
    static var supportsHighPerformance: Bool {
        // 简化判断：iPhone 15 Pro 及以上
        let identifier = UIDevice.current.modelIdentifier
        let highPerformanceModels = ["iPhone16,1", "iPhone16,2", "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4"]
        return highPerformanceModels.contains(identifier)
    }

    /// 是否为省电模式
    nonisolated static var isLowPowerMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /// 当前动画质量等级
    static var animationQuality: AnimationQuality {
        if isLowPowerMode { return .low }
        if supportsHighPerformance { return .high }
        return .medium
    }

    enum AnimationQuality: Sendable {
        case high   // 完整动画
        case medium // 简化动画
        case low    // 基础动画
    }
}

// MARK: - UIDevice Extension

extension UIDevice {
    @MainActor
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
