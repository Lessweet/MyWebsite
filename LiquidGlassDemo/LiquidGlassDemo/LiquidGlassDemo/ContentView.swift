//
//  ContentView.swift
//  LiquidGlassDemo
//
//  小卡片自身变形动画 - 无需重新加载图片

import SwiftUI

// MARK: - 液态效果配置
@Observable
class LiquidEffectConfig {
    // 缩放效果
    var scaleXIntensity: Double = 0.03      // X轴缩放强度 (0-0.1)
    var scaleYIntensity: Double = 0.02      // Y轴缩放强度 (0-0.1)

    // 3D旋转效果
    var rotationAngle: Double = 35.0        // 最大旋转角度 (0-60)
    var rotationAxisX: Double = 1.0         // 旋转轴 X (-1 到 1)
    var rotationAxisY: Double = -0.3        // 旋转轴 Y (-1 到 1)
    var perspective: Double = 0.4           // 透视强度 (0.1-1.0)

    // 动画参数
    var springResponse: Double = 0.55       // 弹簧响应时间 (0.2-1.0)
    var springDamping: Double = 0.8         // 弹簧阻尼 (0.5-1.0)

    // 效果开关
    var enableScale: Bool = true
    var enableRotation: Bool = true
}

// 共享图片缓存
@Observable
class ImageCache {
    var images: [String: Image] = [:]

    func setImage(_ image: Image, for url: String) {
        images[url] = image
    }

    func getImage(for url: String) -> Image? {
        return images[url]
    }
}

struct ContentView: View {
    @State private var expandedCardId: Int? = nil
    @State private var imageCache = ImageCache()
    @State private var effectConfig = LiquidEffectConfig()
    @State private var animProgress: CGFloat = 0
    @State private var cardFrames: [Int: CGRect] = [:]
    @State private var animationStartFrame: CGRect? = nil // 动画开始时的位置，固定不变
    @State private var showSecondCard: CGFloat = 0
    @State private var showThirdCard: CGFloat = 0
    @State private var showSettings: Bool = false
    @State private var showFourthCard: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0

    private var navBarOpacity: Double {
        let fadeDistance: CGFloat = 40
        if scrollOffset >= 0 {
            return 1.0
        } else if scrollOffset <= -fadeDistance {
            return 0.0
        } else {
            return 1.0 + Double(scrollOffset / fadeDistance)
        }
    }

    let cards: [CardItem] = [
        CardItem(id: 1, title: "Photos", icon: "photo.fill", color: .blue, imageURLs: [
            "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1454496522488-7a8e488e8606?w=400&h=533&fit=crop"
        ]),
        CardItem(id: 2, title: "Videos", icon: "video.fill", color: .purple, imageURLs: [
            "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1440404653325-ab127d49abc1?w=400&h=533&fit=crop"
        ]),
        CardItem(id: 3, title: "Documents", icon: "doc.fill", color: .orange, imageURLs: [
            "https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1542435503-956c469947f6?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400&h=533&fit=crop"
        ]),
        CardItem(id: 4, title: "Music", icon: "music.note", color: .pink, imageURLs: [
            "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&h=533&fit=crop"
        ]),
        CardItem(id: 5, title: "Albums", icon: "photo.on.rectangle", color: .cyan, imageURLs: [
            "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=400&h=533&fit=crop"
        ]),
        CardItem(id: 6, title: "Downloads", icon: "arrow.down.circle.fill", color: .green, imageURLs: [
            "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1448375240586-882707db888b?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400&h=533&fit=crop"
        ]),
        CardItem(id: 7, title: "Favorites", icon: "heart.fill", color: .red, imageURLs: [
            "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=400&h=533&fit=crop"
        ]),
        CardItem(id: 8, title: "Recents", icon: "clock.fill", color: .indigo, imageURLs: [
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=533&fit=crop",
            "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=533&fit=crop"
        ]),
    ]

    var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            let isLandscape = screenSize.width > screenSize.height
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: isLandscape ? 4 : 2)

            ZStack {
                Color.black.ignoresSafeArea()

                // 卡片网格
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(cards) { card in
                            // 始终渲染卡片，展开时用 opacity 隐藏
                            CardImageView(card: card, imageCache: imageCache)
                                .aspectRatio(3.0/4.0, contentMode: .fit)
                                .opacity(expandedCardId == card.id ? 0 : 1)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear {
                                                // 使用相对于主容器的坐标
                                                cardFrames[card.id] = geo.frame(in: .named("mainContainer"))
                                            }
                                            .onChange(of: geo.frame(in: .named("mainContainer"))) { _, newFrame in
                                                // 只在没有展开任何卡片时更新位置
                                                if expandedCardId == nil {
                                                    cardFrames[card.id] = newFrame
                                                }
                                            }
                                    }
                                )
                                .onTapGesture {
                                    if expandedCardId == nil {
                                        expandCard(card.id)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 76)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("scroll")).minY)
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .scrollEdgeEffectStyle(.soft, for: .top)
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                }
                .scrollDisabled(expandedCardId != nil)

                // 顶部渐变遮罩
                VStack {
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .allowsHitTesting(false)

                    Spacer()

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                    .allowsHitTesting(false)
                }
                .ignoresSafeArea()

                // 导航栏
                VStack {
                    HStack {
                        Text("Gallery")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(.primary)
                            .scaleEffect(x: 0.8, y: 1.0, anchor: .leading)

                        Spacer()

                        Button {
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                        .glassEffect(.clear.interactive())

                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                        .glassEffect(.clear.interactive())
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .opacity(navBarOpacity)

                    Spacer()
                }

                // 背景遮罩
                if expandedCardId != nil {
                    Color.clear
                        .glassEffect(.regular, in: .rect(cornerRadius: 0))
                        .opacity(Double(animProgress))
                        .ignoresSafeArea()
                        .onTapGesture { closeCard() }
                        .zIndex(500)
                }

                // 展开后的额外卡片（第2、3、4张）
                if let cardId = expandedCardId,
                   let card = cards.first(where: { $0.id == cardId }) {
                    ExpandedExtraCards(
                        card: card,
                        screenSize: screenSize,
                        isLandscape: isLandscape,
                        secondCardProgress: showSecondCard,
                        thirdCardProgress: showThirdCard,
                        fourthCardProgress: showFourthCard,
                        onClose: { closeCard() }
                    )
                    .opacity(Double(animProgress))
                    .zIndex(600)
                }

                // 关闭按钮 - 最高层级
                if expandedCardId != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                closeCard()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                            }
                            .glassEffect(.clear.interactive())
                            .padding(.trailing, 20)
                            .padding(.top, 16)
                        }
                        Spacer()
                    }
                    .opacity(Double(animProgress))
                    .zIndex(2000)
                }

                // 展开的主卡片 - 在最上层渲染
                if let cardId = expandedCardId,
                   let card = cards.first(where: { $0.id == cardId }),
                   let startFrame = animationStartFrame {
                    ExpandingMainCard(
                        card: card,
                        progress: animProgress,
                        startFrame: startFrame,
                        screenSize: screenSize,
                        isLandscape: isLandscape,
                        imageCache: imageCache,
                        config: effectConfig
                    )
                    .zIndex(1000)
                }

            }
            .coordinateSpace(name: "mainContainer")
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            EffectSettingsView(config: effectConfig)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func expandCard(_ id: Int) {
        // 保存动画开始时的位置（固定不变）
        animationStartFrame = cardFrames[id]
        expandedCardId = id
        animProgress = 0
        showSecondCard = 0
        showThirdCard = 0
        showFourthCard = 0

        withAnimation(.spring(response: effectConfig.springResponse, dampingFraction: effectConfig.springDamping)) {
            animProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showSecondCard = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showThirdCard = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showFourthCard = 1
            }
        }
    }

    private func closeCard() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
            showFourthCard = 0
            showThirdCard = 0
            showSecondCard = 0
            animProgress = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            expandedCardId = nil
            animationStartFrame = nil
        }
    }
}

struct CardItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String
    let color: Color
    let imageURLs: [String]
}

// 展开的主卡片 - 在 ZStack 最上层渲染
struct ExpandingMainCard: View, Animatable {
    let card: CardItem
    var progress: CGFloat
    let startFrame: CGRect
    let screenSize: CGSize
    let isLandscape: Bool
    let imageCache: ImageCache
    let config: LiquidEffectConfig

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    // 展开后的目标尺寸
    private var expandedSize: CGSize {
        let horizontalPadding: CGFloat = 40
        if isLandscape {
            let totalSpacing: CGFloat = 16 * 3
            let availableWidth = screenSize.width - horizontalPadding - totalSpacing
            let cardWidth = availableWidth / 4
            let cardHeight = cardWidth * 4.0 / 3.0
            return CGSize(width: cardWidth, height: cardHeight)
        } else {
            let cardWidth = screenSize.width - horizontalPadding
            let cardHeight = cardWidth * 4.0 / 3.0
            return CGSize(width: cardWidth, height: cardHeight)
        }
    }

    // 展开后的目标中心位置
    private var expandedCenter: CGPoint {
        if isLandscape {
            let horizontalPadding: CGFloat = 40
            let totalSpacing: CGFloat = 16 * 3
            let availableWidth = screenSize.width - horizontalPadding - totalSpacing
            let cardWidth = availableWidth / 4
            return CGPoint(x: 20 + cardWidth / 2, y: 76 + expandedSize.height / 2)
        } else {
            return CGPoint(x: screenSize.width / 2, y: 76 + expandedSize.height / 2)
        }
    }

    var body: some View {
        // 当前尺寸
        let currentWidth = startFrame.width + (expandedSize.width - startFrame.width) * progress
        let currentHeight = startFrame.height + (expandedSize.height - startFrame.height) * progress

        // 当前中心位置
        let currentX = startFrame.midX + (expandedCenter.x - startFrame.midX) * progress
        let currentY = startFrame.midY + (expandedCenter.y - startFrame.midY) * progress

        // 3D 旋转：抛物线曲线，中间最大
        let rotationAmount = config.enableRotation
            ? 4.0 * Double(progress) * Double(1.0 - progress) * config.rotationAngle
            : 0.0

        CardImageView(card: card, imageCache: imageCache)
            .frame(width: currentWidth, height: currentHeight)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            // 液态扭曲效果
            .modifier(LiquidDistortion(progress: progress, config: config))
            // 3D 旋转
            .rotation3DEffect(
                .degrees(rotationAmount),
                axis: (x: config.rotationAxisX, y: config.rotationAxisY, z: 0.0),
                perspective: config.perspective
            )
            // 绝对定位
            .position(x: currentX, y: currentY)
    }
}

// 卡片图片视图
struct CardImageView: View {
    let card: CardItem
    let imageCache: ImageCache

    private var imageURL: String {
        card.imageURLs[0]
    }

    var body: some View {
        ZStack {
            // 从缓存获取图片
            if let cachedImage = imageCache.getImage(for: imageURL) {
                cachedImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // 背景占位
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))

                // AsyncImage 用于加载图片
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .onAppear {
                                imageCache.setImage(image, for: imageURL)
                            }
                    default:
                        Color.clear
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(3.0/4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.black.opacity(0), Color.black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .overlay(alignment: .bottom) {
            Text(card.title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 16)
        }
    }
}

// 展开后的额外卡片（第2、3、4张）
struct ExpandedExtraCards: View {
    let card: CardItem
    let screenSize: CGSize
    let isLandscape: Bool
    let secondCardProgress: CGFloat
    let thirdCardProgress: CGFloat
    let fourthCardProgress: CGFloat
    let onClose: () -> Void

    private var expandedSize: CGSize {
        let horizontalPadding: CGFloat = 40
        if isLandscape {
            let totalSpacing: CGFloat = 16 * 3
            let availableWidth = screenSize.width - horizontalPadding - totalSpacing
            let cardWidth = availableWidth / 4
            let cardHeight = cardWidth * 4.0 / 3.0
            return CGSize(width: cardWidth, height: cardHeight)
        } else {
            let cardWidth = screenSize.width - horizontalPadding
            let cardHeight = cardWidth * 4.0 / 3.0
            return CGSize(width: cardWidth, height: cardHeight)
        }
    }

    var body: some View {
        let columns = isLandscape
            ? Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
            : [GridItem(.flexible())]

        ZStack {
            // 可滚动内容
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 20) {
                    // 占位：主卡片位置
                    Rectangle()
                        .fill(.clear)
                        .aspectRatio(3.0/4.0, contentMode: .fit)

                    // 第二张卡片
                    ExtraCardItem(imageURL: card.imageURLs[1])
                        .opacity(Double(secondCardProgress))
                        .offset(y: (1 - secondCardProgress) * 100)

                    // 第三张卡片
                    ExtraCardItem(imageURL: card.imageURLs[2])
                        .opacity(Double(thirdCardProgress))
                        .offset(y: (1 - thirdCardProgress) * 100)

                    // 第四张卡片
                    ExtraCardItem(imageURL: card.imageURLs[3])
                        .opacity(Double(fourthCardProgress))
                        .offset(y: (1 - fourthCardProgress) * 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 76)
            }

            // 渐变遮罩
            VStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)

                Spacer()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()

        }
    }
}

// 额外卡片
struct ExtraCardItem: View {
    let imageURL: String

    var body: some View {
        AsyncImage(url: URL(string: imageURL), transaction: Transaction(animation: .easeIn(duration: 0.3))) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            case .failure:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            @unknown default:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// 液态扭曲效果 - 使用 SwiftUI 变换模拟
struct LiquidDistortion: ViewModifier, Animatable {
    var progress: CGFloat
    let config: LiquidEffectConfig

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        if config.enableScale {
            // 抛物线强度：中间最大
            let intensity = 4.0 * progress * (1.0 - progress)

            // 模拟液态膨胀效果
            let scaleX = 1.0 + intensity * config.scaleXIntensity
            let scaleY = 1.0 + intensity * config.scaleYIntensity

            content
                .scaleEffect(x: scaleX, y: scaleY)
        } else {
            content
        }
    }
}

// 滚动偏移量
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 效果设置面板
struct EffectSettingsView: View {
    @Bindable var config: LiquidEffectConfig
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // 缩放效果
                Section {
                    Toggle("启用缩放效果", isOn: $config.enableScale)

                    VStack(alignment: .leading) {
                        Text("X轴缩放强度: \(config.scaleXIntensity, specifier: "%.3f")")
                        Slider(value: $config.scaleXIntensity, in: 0...0.1, step: 0.005)
                    }

                    VStack(alignment: .leading) {
                        Text("Y轴缩放强度: \(config.scaleYIntensity, specifier: "%.3f")")
                        Slider(value: $config.scaleYIntensity, in: 0...0.1, step: 0.005)
                    }
                } header: {
                    Label("缩放效果", systemImage: "arrow.up.left.and.arrow.down.right")
                }

                // 3D旋转效果
                Section {
                    Toggle("启用3D旋转", isOn: $config.enableRotation)

                    VStack(alignment: .leading) {
                        Text("旋转角度: \(config.rotationAngle, specifier: "%.0f")°")
                        Slider(value: $config.rotationAngle, in: 0...60, step: 1)
                    }

                    VStack(alignment: .leading) {
                        Text("旋转轴 X: \(config.rotationAxisX, specifier: "%.2f")")
                        Slider(value: $config.rotationAxisX, in: -1...1, step: 0.1)
                    }

                    VStack(alignment: .leading) {
                        Text("旋转轴 Y: \(config.rotationAxisY, specifier: "%.2f")")
                        Slider(value: $config.rotationAxisY, in: -1...1, step: 0.1)
                    }

                    VStack(alignment: .leading) {
                        Text("透视强度: \(config.perspective, specifier: "%.2f")")
                        Slider(value: $config.perspective, in: 0.1...1.0, step: 0.05)
                    }
                } header: {
                    Label("3D旋转效果", systemImage: "rotate.3d")
                }

                // 动画参数
                Section {
                    VStack(alignment: .leading) {
                        Text("弹簧响应: \(config.springResponse, specifier: "%.2f")s")
                        Slider(value: $config.springResponse, in: 0.2...1.0, step: 0.05)
                    }

                    VStack(alignment: .leading) {
                        Text("弹簧阻尼: \(config.springDamping, specifier: "%.2f")")
                        Slider(value: $config.springDamping, in: 0.5...1.0, step: 0.05)
                    }
                } header: {
                    Label("动画参数", systemImage: "waveform.path")
                }

                // 重置按钮
                Section {
                    Button("重置为默认值") {
                        resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("效果配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetToDefaults() {
        config.scaleXIntensity = 0.03
        config.scaleYIntensity = 0.02
        config.rotationAngle = 35.0
        config.rotationAxisX = 1.0
        config.rotationAxisY = -0.3
        config.perspective = 0.4
        config.springResponse = 0.55
        config.springDamping = 0.8
        config.enableScale = true
        config.enableRotation = true
    }
}

#Preview {
    ContentView()
}
