import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  DynamicIslandToast - 灵动岛液态提示条
//  从灵动岛液态溢出的通用提示条组件，使用 iOS 26 原生 Liquid Glass API
// ═══════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct DynamicIslandToast: View {
    let text: String
    var buttonText: String?
    var buttonAction: (() -> Void)?
    var autoDismiss: TimeInterval = 3.0

    @State private var isVisible = false
    @State private var isButtonPressed = false

    var body: some View {
        VStack {
            // 与灵动岛的液态连接
            liquidConnection

            // 提示条主体 - 使用原生 glassEffect
            HStack(spacing: 12) {
                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.psTextPrimaryAdaptive)
                    .lineLimit(1)

                Spacer()

                if let buttonText = buttonText {
                    Button(action: {
                        HapticManager.shared.mediumTap()
                        buttonAction?()
                    }) {
                        Text(buttonText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.psTextPrimaryAdaptive)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .glassEffect(
                        .regular.tint(Color.psAccent).interactive(),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
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
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: Constants.Layout.toastCornerRadius, style: .continuous)
            )

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

    // 液态连接效果 - 使用 glassEffect 实现液态感
    private var liquidConnection: some View {
        VStack(spacing: 0) {
            // 顶部小圆点 (模拟与灵动岛的连接)
            Circle()
                .frame(width: 8, height: 8)
                .glassEffect(.regular, in: Circle())

            // 连接线
            Rectangle()
                .frame(width: 3, height: 12)
                .glassEffect(.regular, in: Rectangle())
        }
    }
}

// Note: ToastBackground removed - using native .glassEffect() API

// MARK: - Completion Toast

@available(iOS 26.0, *)
struct CompletionToast: View {
    let deletedCount: Int
    let freedSpace: String
    let onDismiss: () -> Void

    var body: some View {
        DynamicIslandToast(
            text: "✓ Cleaned  Freed \(freedSpace)",
            buttonText: "Done",
            buttonAction: onDismiss,
            autoDismiss: 0 // 不自动消失
        )
    }
}

// MARK: - Scan Result Toast

@available(iOS 26.0, *)
struct ScanResultToast: View {
    let photoCount: Int
    let onView: () -> Void

    var body: some View {
        DynamicIslandToast(
            text: "Found \(photoCount) similar photos",
            buttonText: "View",
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
            text: "Keep 1  Delete 6",
            buttonText: "Confirm",
            buttonAction: {},
            autoDismiss: 0
        )
    }
}
