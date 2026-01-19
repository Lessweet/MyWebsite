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

    let cards: [CardItem] = [
        CardItem(id: 1, title: "照片", icon: "photo.fill", color: .blue),
        CardItem(id: 2, title: "视频", icon: "video.fill", color: .purple),
        CardItem(id: 3, title: "文档", icon: "doc.fill", color: .orange),
        CardItem(id: 4, title: "音乐", icon: "music.note", color: .pink),
    ]

    var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size

            ZStack {
                // 卡片网格
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
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
                    .padding()
                }

                // 背景遮罩 - 在展开卡片下面
                if expandedCardId != nil {
                    Color.black
                        .opacity(Double(animProgress) * 0.5)
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
                        progress: animProgress,
                        onClose: { closeCard() }
                    )
                }
            }
        }
    }

    private func expandCard(_ id: Int) {
        expandedCardId = id
        showSmallCard = false  // 展开时立即隐藏小卡片
        animProgress = 0
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            animProgress = 1
        }
    }

    private func closeCard() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animProgress = 0
        }
        // 小卡片延迟 0.05 秒后开始淡入，用 0.25 秒完成
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
}

// 小卡片
struct SmallCard: View {
    let card: CardItem

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: card.icon)
                .font(.system(size: 40))
                .foregroundStyle(.white)
            Text(card.title)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(card.color.gradient)
        )
    }
}

// 展开的卡片 - 从原位置动画到屏幕中央
struct ExpandedCard: View {
    let card: CardItem
    let startFrame: CGRect
    let screenSize: CGSize
    let progress: CGFloat
    let onClose: () -> Void

    var body: some View {
        let endWidth = screenSize.width - 40
        let endHeight = screenSize.height * 0.85
        let endX = screenSize.width / 2
        let endY = screenSize.height / 2

        let currentWidth = startFrame.width + (endWidth - startFrame.width) * progress
        let currentHeight = startFrame.height + (endHeight - startFrame.height) * progress
        let currentX = startFrame.midX + (endX - startFrame.midX) * progress
        let currentY = startFrame.midY + (endY - startFrame.midY) * progress
        let currentRadius = 24 + (20 * progress)

        // 计算位置和尺寸与原始小卡片的接近程度
        let maxPositionDist = sqrt(pow(endX - startFrame.midX, 2) + pow(endY - startFrame.midY, 2))
        let currentPositionDist = sqrt(pow(currentX - startFrame.midX, 2) + pow(currentY - startFrame.midY, 2))
        let positionCloseness = maxPositionDist > 0 ? currentPositionDist / maxPositionDist : 0

        let maxSizeDiff = (endWidth - startFrame.width) + (endHeight - startFrame.height)
        let currentSizeDiff = (currentWidth - startFrame.width) + (currentHeight - startFrame.height)
        let sizeCloseness = maxSizeDiff > 0 ? currentSizeDiff / maxSizeDiff : 0

        // 当位置和尺寸都接近原始值时才开始淡出（阈值 5%）
        let fadeThreshold: CGFloat = 0.05
        let shouldFade = positionCloseness < fadeThreshold && sizeCloseness < fadeThreshold
        let fadeOpacity = shouldFade ? max(positionCloseness, sizeCloseness) / fadeThreshold : 1.0

        VStack(spacing: 12) {
            Spacer()

            Image(systemName: card.icon)
                .font(.system(size: 40 + progress * 40))
                .foregroundStyle(.white)

            Text(card.title)
                .font(progress > 0.15 ? Font.largeTitle.bold() : Font.headline)
                .foregroundStyle(.white)
                .opacity(progress < 0.1 ? Double(max(0, 1.0 - progress * 10.0)) : 1.0)

            if progress > 0.3 {
                Text("3D 液态展开效果")
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(Double(progress - 0.3) * 1.5)
            }

            Spacer()

            if progress > 0.5 {
                Button("关闭") { onClose() }
                    .font(.headline)
                    .foregroundStyle(card.color)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(.white, in: Capsule())
                    .opacity(Double(progress - 0.5) * 2)
            }

            Spacer().frame(height: 40)
        }
        .frame(width: currentWidth, height: currentHeight)
        .background(
            RoundedRectangle(cornerRadius: currentRadius)
                .fill(card.color.gradient)
        )
        .position(x: currentX, y: currentY)
        // 收缩末尾淡出，当位置和尺寸都接近原始小卡片时才淡出
        .opacity(Double(fadeOpacity))
        // 3D 倾斜
        .rotation3DEffect(
            .degrees(Double(1 - progress) * 35.0),
            axis: (x: 1.0, y: -1.0, z: 0.0),
            perspective: 0.3
        )
        // 液态弯曲
        .modifier(LiquidEffect(progress: progress))
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

#Preview {
    ContentView()
}
