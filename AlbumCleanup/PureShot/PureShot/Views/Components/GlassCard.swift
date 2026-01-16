import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  GlassCard - iOS 26 原生 Liquid Glass 卡片组件
//  使用 .glassEffect() API
// ═══════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct GlassCard<Content: View>: View {
    let content: Content

    var cornerRadius: CGFloat = Constants.Layout.cardCornerRadius
    var padding: CGFloat = 20
    var style: Glass = .regular

    init(
        cornerRadius: CGFloat = Constants.Layout.cardCornerRadius,
        padding: CGFloat = 20,
        style: Glass = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .glassEffect(
                style,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

// MARK: - Tinted Glass Card (品牌色)

@available(iOS 26.0, *)
struct TintedGlassCard<Content: View>: View {
    let content: Content

    var cornerRadius: CGFloat = Constants.Layout.cardCornerRadius
    var padding: CGFloat = 20

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
            .glassEffect(
                .regular.tint(Color.psAccent),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

// MARK: - Interactive Glass Card (可点击)

@available(iOS 26.0, *)
struct InteractiveGlassCard<Content: View>: View {
    let content: Content
    let action: () -> Void

    var cornerRadius: CGFloat = Constants.Layout.cardCornerRadius
    var padding: CGFloat = 20

    @State private var isPressed = false

    init(
        cornerRadius: CGFloat = Constants.Layout.cardCornerRadius,
        padding: CGFloat = 20,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.action = action
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .glassEffect(
                .regular.interactive(),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2), value: isPressed)
            .onTapGesture {
                action()
            }
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

// MARK: - Result Card

@available(iOS 26.0, *)
struct ResultCard: View {
    let groupCount: Int
    let totalPhotos: Int
    let spaceSavable: String
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(Color.psAccent.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "photo.stack")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.psAccent)
            }

            // 中间信息
            VStack(alignment: .leading, spacing: 6) {
                // 主标题：相似照片数量
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("相似照片")
                        .font(.headline)
                        .foregroundStyle(Color.psTextPrimaryAdaptive)

                    Text("\(totalPhotos)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.psAccent)

                    Text("张")
                        .font(.headline)
                        .foregroundStyle(Color.psTextPrimaryAdaptive)
                }

                // 副标题：可释放空间
                HStack(spacing: 4) {
                    Text("可释放")
                        .font(.subheadline)
                        .foregroundStyle(Color.psTextSecondaryAdaptive)

                    Text(spaceSavable)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.psAccent)
                }
            }

            Spacer()

            // 箭头指示
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.psTextSecondaryAdaptive)
        }
        .padding(16)
        .glassEffect(
            .regular.interactive(),
            in: RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous)
        )
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

@available(iOS 26.0, *)
struct GroupCard: View {
    let group: PhotoGroup
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
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
        .padding(16)
        .glassEffect(
            .regular.interactive(),
            in: RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous)
        )
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
