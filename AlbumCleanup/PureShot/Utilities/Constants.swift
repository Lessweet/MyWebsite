import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  Constants - 全局常量定义
//  动画参数、布局尺寸、相似度阈值
// ═══════════════════════════════════════════════════════════════

enum Constants {

    // MARK: - Animation Timing

    enum Animation {
        /// 光波扫描总时长
        static let lightWaveScanDuration: Double = 1.0

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

        /// 纵向布局照片间距
        static let verticalPhotoSpacing: CGFloat = 16

        /// 底部操作栏高度
        static let actionBarHeight: CGFloat = 56

        /// 底部安全区
        static let bottomSafeArea: CGFloat = 34

        /// 灵动岛提示条高度
        static let toastHeight: CGFloat = 48

        /// 灵动岛提示条圆角
        static let toastCornerRadius: CGFloat = 22
    }

    // MARK: - Photo Size Scale (纵向布局尺寸递减)

    enum PhotoScale {
        /// 焦点位置 (中心)
        static let focus: CGFloat = 1.0

        /// ±1 位置
        static let near1: CGFloat = 0.70

        /// ±2 位置
        static let near2: CGFloat = 0.50

        /// ±3 位置
        static let near3: CGFloat = 0.35

        /// ±4 位置
        static let near4: CGFloat = 0.25

        /// 更远位置
        static let far: CGFloat = 0.20

        /// 根据距离获取缩放比例
        static func scale(for distance: Int) -> CGFloat {
            switch abs(distance) {
            case 0: return focus
            case 1: return near1
            case 2: return near2
            case 3: return near3
            case 4: return near4
            default: return far
            }
        }

        /// 根据距离获取透明度
        static func opacity(for distance: Int) -> Double {
            switch abs(distance) {
            case 0: return 1.0
            case 1: return 0.9
            case 2: return 0.75
            case 3: return 0.55
            case 4: return 0.35
            default: return 0.20
            }
        }

        /// 根据距离获取模糊值
        static func blur(for distance: Int) -> CGFloat {
            switch abs(distance) {
            case 0, 1: return 0
            case 2: return 1
            case 3: return 2
            case 4: return 3
            default: return 4
            }
        }
    }

    // MARK: - Similarity Engine

    enum Similarity {
        /// 相似度阈值 (0-1)，大于此值视为相似照片
        static let threshold: Float = 0.95

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

enum DeviceCapability {
    /// 是否支持高性能动画 (A17+ 芯片)
    static var supportsHighPerformance: Bool {
        // 简化判断：iPhone 15 Pro 及以上
        let identifier = UIDevice.current.modelIdentifier
        let highPerformanceModels = ["iPhone16,1", "iPhone16,2", "iPhone17,1", "iPhone17,2"]
        return highPerformanceModels.contains(identifier)
    }

    /// 是否为省电模式
    static var isLowPowerMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /// 当前动画质量等级
    static var animationQuality: AnimationQuality {
        if isLowPowerMode { return .low }
        if supportsHighPerformance { return .high }
        return .medium
    }

    enum AnimationQuality {
        case high   // 完整动画
        case medium // 简化动画
        case low    // 基础动画
    }
}

// MARK: - UIDevice Extension

extension UIDevice {
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
