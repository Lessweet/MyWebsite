//
//  ContentView.swift
//  LiquidGlassDemo
//
//  同一张卡片：小卡片 ⇄ 大卡片

import SwiftUI

struct ContentView: View {
    @State private var expandedCardId: Int? = nil
    @State private var animProgress: CGFloat = 0
    @State private var cardFrames: [Int: CGRect] = [:]
    @State private var showSmallCard: Bool = true  // 控制小卡片是否显示
    @State private var showSecondCard: CGFloat = 0  // 第二张卡片动画进度
    @State private var showThirdCard: CGFloat = 0   // 第三张卡片动画进度
    @State private var showFourthCard: CGFloat = 0  // 第四张卡片动画进度
    @State private var scrollOffset: CGFloat = 0   // 滚动偏移量

    // 导航栏透明度：滚动超过阈值后淡出
    private var navBarOpacity: Double {
        let fadeDistance: CGFloat = 40  // 完全淡出需要的滚动距离
        // scrollOffset 初始为 0，上滑时变成负值
        if scrollOffset >= 0 {
            return 1.0  // 未滚动或下滑，完全显示
        } else if scrollOffset <= -fadeDistance {
            return 0.0  // 完全淡出
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
            "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400&h=533&fit=crop",
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
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: isLandscape ? 4 : 2)

            ZStack {
                // 纯黑色背景
                Color.black
                    .ignoresSafeArea()

                // 卡片网格 - 全屏滚动，内容穿透导航栏
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(cards) { card in
                            // 小卡片始终存在，通过 opacity 控制显示
                            SmallCard(card: card)
                                // 小卡片延迟显示，通过 showSmallCard 控制淡入
                                .opacity(expandedCardId == card.id ? (showSmallCard ? 1.0 : 0.0) : 1.0)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.onAppear {
                                            cardFrames[card.id] = geo.frame(in: .global)
                                        }
                                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                                            cardFrames[card.id] = newFrame
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
                    .padding(.top, 76)  // 为导航栏留出空间
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

                // 顶部渐变遮罩 - 实现柔和的边缘淡出效果
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

                    // 底部渐变遮罩
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

                // 顶部标题栏 - 浮动在内容上方，根据滚动淡入淡出
                VStack {
                    HStack {
                        Text("Gallery")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            // 搜索操作
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                        .glassEffect(.clear.interactive())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    // 根据滚动偏移量计算透明度：上滑淡出，下滑淡入
                    .opacity(navBarOpacity)

                    Spacer()
                }

                // 背景遮罩 - iOS 26 Liquid Glass 模糊效果
                if expandedCardId != nil {
                    Color.clear
                        .glassEffect(.regular, in: .rect(cornerRadius: 0))
                        .opacity(Double(animProgress))
                        .ignoresSafeArea()
                        .onTapGesture { closeCard() }
                }

                // 展开的卡片 - 在最上层
                if let cardId = expandedCardId,
                   let card = cards.first(where: { $0.id == cardId }),
                   let startFrame = cardFrames[cardId] {
                    ExpandedCard(
                        card: card,
                        startFrame: startFrame,
                        screenSize: screenSize,
                        isLandscape: isLandscape,
                        progress: animProgress,
                        secondCardProgress: showSecondCard,
                        thirdCardProgress: showThirdCard,
                        fourthCardProgress: showFourthCard,
                        onClose: { closeCard() }
                    )
                }
            }
        }
        .preferredColorScheme(.dark)  // 强制深色模式，UI 自动适配
    }

    private func expandCard(_ id: Int) {
        expandedCardId = id
        showSmallCard = false  // 展开时立即隐藏小卡片
        animProgress = 0
        showSecondCard = 0
        showThirdCard = 0
        showFourthCard = 0

        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            animProgress = 1
        }

        // 第一张卡片展开过程中，第二张卡片提前从下方滑入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showSecondCard = 1
            }
        }

        // 第三张卡片滑入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showThirdCard = 1
            }
        }

        // 第四张卡片滑入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showFourthCard = 1
            }
        }
    }

    private func closeCard() {
        // 所有卡片同时开始收起
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showFourthCard = 0
            showThirdCard = 0
            showSecondCard = 0
            animProgress = 0
        }

        // 小卡片延迟后开始淡入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeIn(duration: 0.25)) {
                showSmallCard = true
            }
        }

        // 等动画完全结束后再移除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            expandedCardId = nil
        }
    }
}

struct CardItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String
    let color: Color
    let imageURLs: [String]  // 同主题的多张图片
}

// 小卡片
struct SmallCard: View {
    let card: CardItem

    var body: some View {
        AsyncImage(url: URL(string: card.imageURLs[0]), transaction: Transaction(animation: .easeIn(duration: 0.3))) { phase in
            switch phase {
            case .empty:
                // 加载中 - 显示灰色占位
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            case .success(let image):
                // 加载成功 - 淡入显示图片
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            case .failure:
                // 加载失败 - 显示灰色回退
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            @unknown default:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            // 底部渐变遮罩 + 标题
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

// 展开的卡片 - 从原位置动画到屏幕中央
struct ExpandedCard: View {
    let card: CardItem
    let startFrame: CGRect
    let screenSize: CGSize
    let isLandscape: Bool
    let progress: CGFloat
    let secondCardProgress: CGFloat
    let thirdCardProgress: CGFloat
    let fourthCardProgress: CGFloat
    let onClose: () -> Void

    // 计算保持 3:4 比例的卡片尺寸
    private var cardSize: CGSize {
        let horizontalPadding: CGFloat = 24  // 左右各 12pt 边距
        let maxHeight = screenSize.height * 0.8  // 横屏时允许更大高度

        if isLandscape {
            // 横屏：一行 4 张卡片，3 个间距（每个 12pt）
            let totalSpacing: CGFloat = 12 * 3
            let availableWidth = screenSize.width - horizontalPadding - totalSpacing
            let singleCardWidth = availableWidth / 4
            let heightFromWidth = singleCardWidth * 4.0 / 3.0

            if heightFromWidth <= maxHeight {
                return CGSize(width: singleCardWidth, height: heightFromWidth)
            } else {
                let widthFromHeight = maxHeight * 3.0 / 4.0
                return CGSize(width: widthFromHeight, height: maxHeight)
            }
        } else {
            // 竖屏：一行 1 张卡片
            let maxWidth = screenSize.width - horizontalPadding
            let heightFromWidth = maxWidth * 4.0 / 3.0
            let maxHeightPortrait = screenSize.height * 0.5

            if heightFromWidth <= maxHeightPortrait {
                return CGSize(width: maxWidth, height: heightFromWidth)
            } else {
                let widthFromHeight = maxHeightPortrait * 3.0 / 4.0
                return CGSize(width: widthFromHeight, height: maxHeightPortrait)
            }
        }
    }

    var body: some View {
        let endWidth = cardSize.width
        let endHeight = cardSize.height
        let endX = screenSize.width / 2
        let cardSpacing: CGFloat = 12

        // 计算位置和尺寸与原始小卡片的接近程度（用于淡出）
        let endY = 24 + endHeight / 2
        let maxPositionDist = sqrt(pow(endX - startFrame.midX, 2) + pow(endY - startFrame.midY, 2))
        let currentX = startFrame.midX + (endX - startFrame.midX) * progress
        let currentY = startFrame.midY + (endY - startFrame.midY) * progress
        let currentPositionDist = sqrt(pow(currentX - startFrame.midX, 2) + pow(currentY - startFrame.midY, 2))
        let positionCloseness = maxPositionDist > 0 ? currentPositionDist / maxPositionDist : 0

        let currentWidth = startFrame.width + (endWidth - startFrame.width) * progress
        let currentHeight = startFrame.height + (endHeight - startFrame.height) * progress
        let maxSizeDiff = (endWidth - startFrame.width) + (endHeight - startFrame.height)
        let currentSizeDiff = (currentWidth - startFrame.width) + (currentHeight - startFrame.height)
        let sizeCloseness = maxSizeDiff > 0 ? currentSizeDiff / maxSizeDiff : 0

        let fadeThreshold: CGFloat = 0.05
        let shouldFade = positionCloseness < fadeThreshold && sizeCloseness < fadeThreshold
        let fadeOpacity = shouldFade ? max(positionCloseness, sizeCloseness) / fadeThreshold : 1.0

        // 主卡片在 ScrollView 中的目标位置（中心点）
        let targetY = 24 + endHeight / 2

        // 计算从小卡片位置到目标位置的偏移
        let offsetX = (startFrame.midX - endX) * (1 - progress)
        let offsetY = (startFrame.midY - targetY) * (1 - progress)

        // 横屏时使用 4 列布局，竖屏 1 列
        let columns = isLandscape
            ? Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
            : [GridItem(.flexible())]

        ZStack {
            // 可滚动的内容区域（包含所有卡片）
            ScrollView {
                LazyVGrid(columns: columns, spacing: cardSpacing) {
                    // 主卡片（第一张）- 跟随列表滚动，显示标题
                    ExpandedCardItem(
                        title: card.title,
                        imageURL: card.imageURLs[0],
                        showTitle: true
                    )
                    .scaleEffect(
                        x: currentWidth / endWidth,
                        y: currentHeight / endHeight,
                        anchor: .center
                    )
                    .opacity(Double(fadeOpacity))
                    .rotation3DEffect(
                        .degrees(Double(1 - progress) * 35.0),
                        axis: (x: 1.0, y: -1.0, z: 0.0),
                        perspective: 0.3
                    )
                    .modifier(LiquidEffect(progress: progress))
                    .offset(x: offsetX, y: offsetY)

                    // 第二张卡片 - 同主题图片，不显示标题
                    ExpandedCardItem(
                        title: "",
                        imageURL: card.imageURLs[1],
                        showTitle: false
                    )
                    .opacity(Double(secondCardProgress))
                    .offset(y: (1 - secondCardProgress) * 100)

                    // 第三张卡片 - 同主题图片，不显示标题
                    ExpandedCardItem(
                        title: "",
                        imageURL: card.imageURLs[2],
                        showTitle: false
                    )
                    .opacity(Double(thirdCardProgress))
                    .offset(y: (1 - thirdCardProgress) * 100)

                    // 第四张卡片 - 同主题图片，不显示标题
                    ExpandedCardItem(
                        title: "",
                        imageURL: card.imageURLs[3],
                        showTitle: false
                    )
                    .opacity(Double(fourthCardProgress))
                    .offset(y: (1 - fourthCardProgress) * 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 76)  // 为顶部渐变遮罩留出空间
            }

            // 顶部和底部渐变遮罩 - 统一样式
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

                // 底部渐变遮罩
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

            // 关闭按钮 - 右上角 X icon，使用原生 Liquid Glass 效果
            if progress > 0.3 {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            onClose()
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
                .opacity(Double(min(1.0, (progress - 0.3) * 3)))
            }
        }
    }
}

// 展开后的统一卡片样式
struct ExpandedCardItem: View {
    let title: String
    let imageURL: String
    var showTitle: Bool = true  // 是否显示标题

    var body: some View {
        AsyncImage(url: URL(string: imageURL), transaction: Transaction(animation: .easeIn(duration: 0.3))) { phase in
            switch phase {
            case .empty:
                // 加载中 - 显示灰色占位
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            case .success(let image):
                // 加载成功 - 淡入显示图片
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            case .failure:
                // 加载失败 - 显示灰色回退
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            @unknown default:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            if showTitle {
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
        }
        .overlay(alignment: .bottom) {
            if showTitle {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.bottom, 16)
            }
        }
    }
}

// 液态效果修饰器
struct LiquidEffect: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        if progress > 0.05 && progress < 0.95 {
            content
                .distortionEffect(
                    ShaderLibrary.liquidCurvature(
                        .boundingRect,
                        .float(progress)
                    ),
                    maxSampleOffset: CGSize(width: 100, height: 100)
                )
        } else {
            content
        }
    }
}

// 滚动偏移量 PreferenceKey
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ContentView()
}
