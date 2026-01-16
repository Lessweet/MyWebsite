import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  LiquidGlassActionBar - 底部液态玻璃操作栏
//  iOS 26 原生 Liquid Glass 样式
//  左侧：保留按钮
//  右侧：删除按钮
// ═══════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct LiquidGlassActionBar: View {
    let keepCount: Int
    let deleteCount: Int
    let onConfirm: () -> Void

    var isDisabled: Bool {
        deleteCount == 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // 左侧 - 保留按钮
            Button {
                if !isDisabled {
                    HapticManager.shared.success()
                    onConfirm()
                }
            } label: {
                Text("保留 \(keepCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isDisabled ? Color.secondary : Color.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .glassEffect(
                isDisabled ? .regular : .regular.interactive(),
                in: Capsule()
            )
            .opacity(isDisabled ? 0.6 : 1.0)
            .disabled(isDisabled)

            Spacer()

            // 右侧 - 删除按钮（带交互效果）
            Button {
                if deleteCount > 0 {
                    HapticManager.shared.mediumTap()
                    onConfirm()
                }
            } label: {
                Text("删除 \(deleteCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(deleteCount > 0 ? Color.red : Color.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .glassEffect(deleteCount > 0 ? .regular.interactive() : .regular, in: Capsule())
            .opacity(deleteCount > 0 ? 1.0 : 0.6)
            .disabled(deleteCount == 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.bottom, Constants.Layout.bottomSafeArea)
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    ZStack {
        // 背景图片模拟
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack {
            Spacer()

            LiquidGlassActionBar(
                keepCount: 2,
                deleteCount: 5,
                onConfirm: {}
            )
        }
    }
}
