import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  LiquidGlassActionBar - 底部液态玻璃操作栏
//  确认删除时的底部操作栏，采用 iOS 26 液态玻璃质感
// ═══════════════════════════════════════════════════════════════

struct LiquidGlassActionBar: View {
    let keepCount: Int
    let deleteCount: Int
    let onConfirm: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var isButtonPressed = false
    @State private var keepCountAnimating = false
    @State private var deleteCountAnimating = false

    var isDisabled: Bool {
        deleteCount == 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // 操作栏内容
            HStack(spacing: 16) {
                // 左侧文字信息
                HStack(spacing: 4) {
                    Text("保留")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.psSurfaceAdaptive)

                    Text("\(keepCount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.psAccent)
                        .scaleEffect(keepCountAnimating ? 1.2 : 1.0)

                    Text("张")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.psSurfaceAdaptive)

                    Spacer()
                        .frame(width: 12)

                    Text("删除")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.psDestructive)

                    Text("\(deleteCount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.psDestructive)
                        .scaleEffect(deleteCountAnimating ? 1.2 : 1.0)

                    Text("张")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.psDestructive)
                }

                Spacer()

                // 确认按钮
                Button(action: {
                    if !isDisabled {
                        HapticManager.shared.mediumTap()
                        onConfirm()
                    }
                }) {
                    Text(isDisabled ? "无需删除" : "确认")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            isDisabled
                            ? Color.psSurfaceAdaptive.opacity(0.4)
                            : Color.psTextPrimaryAdaptive
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    isDisabled
                                    ? Color.psSurfaceAdaptive.opacity(0.1)
                                    : Color.psAccent
                                )
                                .shadow(
                                    color: isDisabled ? .clear : Color.psAccent.opacity(0.3),
                                    radius: 8,
                                    x: 0,
                                    y: 2
                                )
                        }
                }
                .scaleEffect(isButtonPressed ? 0.95 : 1.0)
                .disabled(isDisabled)
                .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                    withAnimation(.spring(response: 0.2)) {
                        isButtonPressed = pressing
                    }
                }, perform: {})
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(height: Constants.Layout.actionBarHeight)
        .background {
            ActionBarBackground()
        }
        .padding(.bottom, Constants.Layout.bottomSafeArea)
        .onChange(of: keepCount) { _, _ in
            withAnimation(.spring(response: 0.15)) {
                keepCountAnimating = true
            }
            HapticManager.shared.numberBounce()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.15)) {
                    keepCountAnimating = false
                }
            }
        }
        .onChange(of: deleteCount) { _, _ in
            withAnimation(.spring(response: 0.15)) {
                deleteCountAnimating = true
            }
            HapticManager.shared.numberBounce()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.15)) {
                    deleteCountAnimating = false
                }
            }
        }
    }
}

// MARK: - Action Bar Background

struct ActionBarBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 毛玻璃
            Rectangle()
                .fill(.ultraThinMaterial)

            // 背景叠加
            Rectangle()
                .fill(
                    colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.white.opacity(0.7)
                )

            // 顶部高光线
            VStack {
                Rectangle()
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.5))
                    .frame(height: 1)
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.psBackgroundAdaptive
            .ignoresSafeArea()

        VStack {
            Spacer()

            LiquidGlassActionBar(
                keepCount: 1,
                deleteCount: 6,
                onConfirm: {}
            )
        }
    }
}
