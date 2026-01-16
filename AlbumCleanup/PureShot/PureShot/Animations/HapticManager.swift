import UIKit
import CoreHaptics

// ═══════════════════════════════════════════════════════════════
//  HapticManager - 触觉反馈管理
//  模拟水珠碰撞的 Q 弹震动，提供治愈系触感
// ═══════════════════════════════════════════════════════════════

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        prepareHaptics()
    }

    // MARK: - Setup

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }

        // 预热生成器
        impactLight.prepare()
        impactMedium.prepare()
        impactSoft.prepare()
        selection.prepare()
    }

    // MARK: - Simple Haptics

    /// 轻触确认 - 用于选中照片
    func lightTap() {
        impactLight.impactOccurred(intensity: 0.6)
    }

    /// 中等触感 - 用于确认按钮
    func mediumTap() {
        impactMedium.impactOccurred(intensity: 0.8)
    }

    /// 柔和触感 - 用于操作栏出现
    func softTap() {
        impactSoft.impactOccurred(intensity: 0.5)
    }

    /// 选择反馈 - 用于切换选项
    func selectionChanged() {
        selection.selectionChanged()
    }

    /// 成功通知 - 用于清理完成
    func success() {
        notification.notificationOccurred(.success)
    }

    /// 警告通知
    func warning() {
        notification.notificationOccurred(.warning)
    }

    // MARK: - Custom Haptic Patterns

    /// 光波扫描触感 - 渐强渐弱
    func lightWaveScan() {
        guard let engine = engine else {
            impactLight.impactOccurred()
            return
        }

        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 0.8
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            impactLight.impactOccurred()
        }
    }

    /// 选中光波扩散 - 双击感
    func selectionRipple() {
        guard let engine = engine else {
            impactLight.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impactLight.impactOccurred()
            }
            return
        }

        do {
            let events: [CHHapticEvent] = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0.1
                )
            ]

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            impactLight.impactOccurred()
        }
    }

    /// 液态融化触感 - 连续轻柔震动
    func liquidDissolve(duration: TimeInterval = 0.6) {
        guard let engine = engine else {
            // 降级方案：使用简单的连续触感
            Task {
                let interval = Constants.Haptic.dissolveInterval
                let count = Int(duration / interval)
                for i in 0..<count {
                    let intensity = 1.0 - (Double(i) / Double(count))
                    impactSoft.impactOccurred(intensity: intensity * 0.5)
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
            }
            return
        }

        do {
            var events: [CHHapticEvent] = []
            let stepCount = 12
            let stepDuration = duration / Double(stepCount)

            for i in 0..<stepCount {
                let intensity = Float(1.0 - (Double(i) / Double(stepCount))) * 0.6
                let sharpness = Float(0.2 + (Double(i) / Double(stepCount)) * 0.3)

                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: Double(i) * stepDuration
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            impactSoft.impactOccurred()
        }
    }

    /// 水滴碰撞 Q 弹感 - 用于融合完成
    func dropletBounce() {
        guard let engine = engine else {
            impactMedium.impactOccurred()
            return
        }

        do {
            let events: [CHHapticEvent] = [
                // 主碰撞
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ],
                    relativeTime: 0
                ),
                // 第一次回弹
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ],
                    relativeTime: 0.08
                ),
                // 第二次回弹
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0.14
                )
            ]

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            impactMedium.impactOccurred()
        }
    }

    /// 数字变化弹跳
    func numberBounce() {
        impactLight.impactOccurred(intensity: 0.4)
    }
}
