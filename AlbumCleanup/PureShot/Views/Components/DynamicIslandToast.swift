import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  DynamicIslandToast - 灵动岛液态提示条
//  从灵动岛液态溢出的通用提示条组件
// ═══════════════════════════════════════════════════════════════

struct DynamicIslandToast: View {
    let text: String
    var buttonText: String?
    var buttonAction: (() -> Void)?
    var autoDismiss: TimeInterval = 3.0

    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false
    @State private var isButtonPressed = false

    var body: some View {
        VStack {
            // 与灵动岛的液态连接
            liquidConnection

            // 提示条主体
            HStack(spacing: 12) {
                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.psSurfaceAdaptive)
                    .lineLimit(1)

                Spacer()

                if let buttonText = buttonText {
                    Button(action: {
                        HapticManager.shared.mediumTap()
                        buttonAction?()
                    }) {
                        Text(buttonText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.psSurfaceAdaptive)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.psSurfaceAdaptive.opacity(0.15))
                            }
                    }
                    .scaleEffect(isButtonPressed ? 0.95 : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                        withAnimation(.spring(response: 0.2)) {
                            isButtonPressed = pressing
                        }
                    }, perform: {})
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                ToastBackground()
            }
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.toastCornerRadius, style: .continuous))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8) // 距离灵动岛
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isVisible = true
            }
            HapticManager.shared.lightTap()

            // 自动消失
            if autoDismiss > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + autoDismiss) {
                    withAnimation(.easeIn(duration: 0.25)) {
                        isVisible = false
                    }
                    HapticManager.shared.softTap()
                }
            }
        }
    }

    // 液态连接效果 (简化版)
    private var liquidConnection: some View {
        VStack(spacing: 0) {
            // 顶部小圆点 (模拟与灵动岛的连接)
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 8, height: 8)

            // 连接线
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.15), Color(white: 0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: 12)
        }
        .opacity(0.8)
    }
}

// MARK: - Toast Background

struct ToastBackground: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.Layout.toastCornerRadius, style: .continuous)
                .fill(Color(white: 0.12).opacity(0.95))

            // 边缘高光
            RoundedRectangle(cornerRadius: Constants.Layout.toastCornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Completion Toast

struct CompletionToast: View {
    let deletedCount: Int
    let freedSpace: String
    let onDismiss: () -> Void

    var body: some View {
        DynamicIslandToast(
            text: "✓ 已清理  释放 \(freedSpace)",
            buttonText: "完成",
            buttonAction: onDismiss,
            autoDismiss: 0 // 不自动消失
        )
    }
}

// MARK: - Scan Result Toast

struct ScanResultToast: View {
    let photoCount: Int
    let onView: () -> Void

    var body: some View {
        DynamicIslandToast(
            text: "发现 \(photoCount) 张相似照片",
            buttonText: "查看",
            buttonAction: onView,
            autoDismiss: 0
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.psBackgroundAdaptive
            .ignoresSafeArea()

        DynamicIslandToast(
            text: "保留 1 张  删除 6 张",
            buttonText: "确认",
            buttonAction: {},
            autoDismiss: 0
        )
    }
}
