//
//  ContentView.swift
//  LiquidGlassDemo
//

import SwiftUI

struct ContentView: View {
    @State private var expandedCard: CardItem? = nil
    @State private var cardFrames: [Int: CGRect] = [:]
    @State private var animProgress: CGFloat = 0

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
                            SmallCard(card: card)
                                // 小卡片：展开时淡出，收缩末尾淡入
                                .opacity(expandedCard?.id == card.id ? Double(1 - animProgress) : 1.0)
                                .background(
                                    GeometryReader { cardGeo in
                                        Color.clear.preference(
                                            key: CardFrameKey.self,
                                            value: [card.id: cardGeo.frame(in: .global)]
                                        )
                                    }
                                )
                                .onTapGesture {
                                    expandedCard = card
                                    animProgress = 0
                                    withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                                        animProgress = 1
                                    }
                                }
                        }
                    }
                    .padding()
                }
                .onPreferenceChange(CardFrameKey.self) { frames in
                    cardFrames = frames
                }

                // 遮罩 + 展开的卡片
                if let card = expandedCard {
                    // 背景遮罩
                    Color.black
                        .opacity(Double(animProgress) * 0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                animProgress = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                expandedCard = nil
                            }
                        }

                    // 展开的卡片
                    ExpandedCard(
                        card: card,
                        startFrame: cardFrames[card.id] ?? .zero,
                        screenSize: screenSize,
                        progress: animProgress,
                        onClose: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                animProgress = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                expandedCard = nil
                            }
                        }
                    )
                }
            }
        }
    }
}

// PreferenceKey 用于收集卡片位置
struct CardFrameKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
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
        // 计算插值
        let endWidth = screenSize.width - 40
        let endHeight = screenSize.height * 0.85
        let endX = screenSize.width / 2
        let endY = screenSize.height / 2

        let currentWidth = startFrame.width + (endWidth - startFrame.width) * progress
        let currentHeight = startFrame.height + (endHeight - startFrame.height) * progress
        let currentX = startFrame.midX + (endX - startFrame.midX) * progress
        let currentY = startFrame.midY + (endY - startFrame.midY) * progress
        let currentRadius = 24 + (20 * progress)

        VStack(spacing: 16) {
            Spacer()

            Image(systemName: card.icon)
                .font(.system(size: 40 + progress * 40))
                .foregroundStyle(.white)

            // 小文字快速消失，大文字快速出现
            Text(card.title)
                .font(progress > 0.2 ? Font.largeTitle.bold() : Font.headline)
                .foregroundStyle(.white)
                .opacity(progress < 0.1 ? Double(1 - progress * 5) : 1.0)
                .scaleEffect(progress < 0.2 ? 1.0 : 1.0 + Double(progress - 0.2) * 0.2)

            if progress > 0.2 {
                Text("3D 液态展开效果")
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(Double(progress - 0.2) * 1.25)
            }

            Spacer()

            if progress > 0.4 {
                Button("关闭") { onClose() }
                    .font(.headline)
                    .foregroundStyle(card.color)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(.white, in: Capsule())
                    .opacity(Double(progress - 0.4) * 1.7)
            }

            Spacer().frame(height: 40)
        }
        .frame(width: currentWidth, height: currentHeight)
        .background(
            RoundedRectangle(cornerRadius: currentRadius)
                .fill(card.color.gradient)
        )
        .position(x: currentX, y: currentY)
        // 收缩末尾淡出，与小卡片衔接
        .opacity(progress < 0.15 ? Double(progress / 0.15) : 1.0)
        // 3D 倾斜
        .rotation3DEffect(
            .degrees(Double(1 - progress) * 35.0),
            axis: (x: 1.0, y: -1.0, z: 0.0),
            perspective: 0.3
        )
        // 液态弯曲 - 只在展开过程中应用
        .modifier(LiquidEffect(progress: progress))
    }
}

// 液态效果修饰器 - 只在动画过程中应用
struct LiquidEffect: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        if progress < 0.95 && progress > 0.05 {
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
