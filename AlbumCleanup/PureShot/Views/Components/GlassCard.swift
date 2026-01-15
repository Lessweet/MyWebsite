import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  GlassCard - 液态玻璃卡片组件
//  iOS 26 Liquid Glass 设计语言
// ═══════════════════════════════════════════════════════════════

struct GlassCard<Content: View>: View {
    let content: Content

    var cornerRadius: CGFloat = Constants.Layout.cardCornerRadius
    var padding: CGFloat = 20

    @Environment(\.colorScheme) private var colorScheme

    init(
        cornerRadius: CGFloat = Constants.Layout.cardCornerRadius,
        padding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                GlassBackground(cornerRadius: cornerRadius)
            }
    }
}

// MARK: - Glass Background

struct GlassBackground: View {
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 毛玻璃效果
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            // 表面叠加色
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.white.opacity(0.7)
                )

            // 顶部高光
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.3 : 0.8),
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )

            // 边缘高光 (模拟液态透镜折射)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    Color.psAccent.opacity(0.1),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: 20,
            x: 0,
            y: 10
        )
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let groupCount: Int
    let totalPhotos: Int
    let spaceSavable: String
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                // 标题
                HStack {
                    Text("刚刚拍摄")
                        .font(.headline)
                        .foregroundStyle(Color.psTextPrimaryAdaptive)

                    Spacer()
                }

                // 发现信息
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("发现")
                        .font(.title3)
                        .foregroundStyle(Color.psTextSecondaryAdaptive)

                    Text("\(totalPhotos)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.psAccent)

                    Text("张")
                        .font(.title3)
                        .foregroundStyle(Color.psTextSecondaryAdaptive)

                    Spacer()
                }

                Text("相似照片")
                    .font(.title3)
                    .foregroundStyle(Color.psTextSecondaryAdaptive)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 空间信息
                HStack {
                    Text("可释放")
                        .font(.subheadline)
                        .foregroundStyle(Color.psTextSecondaryAdaptive)

                    Text(spaceSavable)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.psAccent)

                    Spacer()

                    // 箭头指示
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.psTextSecondaryAdaptive)
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Group Card

struct GroupCard: View {
    let group: PhotoGroup
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        GlassCard(padding: 16) {
            HStack(spacing: 12) {
                // 预览图
                if let thumbnail = group.bestPhoto?.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.psTextSecondaryAdaptive.opacity(0.2))
                        .frame(width: 60, height: 60)
                }

                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(group.photos.count) 张相似照片")
                        .font(.headline)
                        .foregroundStyle(Color.psTextPrimaryAdaptive)

                    Text(group.timeRangeDescription)
                        .font(.caption)
                        .foregroundStyle(Color.psTextSecondaryAdaptive)

                    HStack(spacing: 4) {
                        Text("可释放")
                            .font(.caption)
                            .foregroundStyle(Color.psTextSecondaryAdaptive)

                        Text(group.formattedSpaceSaved)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.psAccent)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.psTextSecondaryAdaptive)
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: 20) {
        ResultCard(
            groupCount: 3,
            totalPhotos: 12,
            spaceSavable: "41 MB",
            onTap: {}
        )
    }
    .padding()
    .background(Color.psBackgroundAdaptive)
}
