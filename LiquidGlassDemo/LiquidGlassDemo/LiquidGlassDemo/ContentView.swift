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
                            // 未展开的卡片
                            if expandedCardId != card.id {
                                SmallCard(card: card)
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
                                    .onTapGesture { expandCard(card.id) }
                            } else {
                                // 占位符
                                Color.clear.frame(height: 140)
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
        animProgress = 0
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            animProgress = 1
        }
    }

    private func closeCard() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animProgress = 0
        }
        // 等动画完全结束后再移除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
