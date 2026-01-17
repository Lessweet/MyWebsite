import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  LiquidGlassActionBar - 底部液态玻璃操作栏
//  iOS 26 原生 Liquid Glass 样式
//  单个居中删除按钮，尺寸更大
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
        HStack {
            Spacer()

            // 居中操作按钮
            Button {
                if deleteCount > 0 {
                    HapticManager.shared.mediumTap()
                    onConfirm()
                }
            } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Delete \(deleteCount)")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .tint(.red)  // 使用 tint 让红色也能适配

                    Text("Keep \(keepCount)")
                        .font(.system(size: 14, weight: .medium))
                    // 不设置 foregroundStyle，让系统自动适配
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 16)
            }
            .glassEffect(.regular.interactive(), in: Capsule())
            .opacity(deleteCount > 0 ? 1.0 : 0.6)
            .disabled(deleteCount == 0)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.bottom, Constants.Layout.bottomSafeArea / 4)
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
