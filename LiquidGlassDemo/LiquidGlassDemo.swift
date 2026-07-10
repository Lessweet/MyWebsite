// LiquidGlassDemo.swift
// iOS 26 Liquid Glass 3D Morph Transition Demo
// 最小可行验证 - 卡片展开动效

import SwiftUI

// MARK: - 主入口
@main
struct LiquidGlassDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - 主视图
struct ContentView: View {
    @State private var selectedCard: CardItem?
    @Namespace private var transitionNamespace

    let cards: [CardItem] = [
        CardItem(id: 1, title: "照片", icon: "photo.fill", color: .blue),
        CardItem(id: 2, title: "视频", icon: "video.fill", color: .purple),
        CardItem(id: 3, title: "文档", icon: "doc.fill", color: .orange),
    ]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height
                let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: isLandscape ? 4 : 2)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(cards) { card in
                            CardView(card: card, namespace: transitionNamespace)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        selectedCard = card
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Liquid Glass Demo")
            .fullScreenCover(item: $selectedCard) { card in
                DetailView(card: card, namespace: transitionNamespace) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedCard = nil
                    }
                }
            }
        }
    }
}

// MARK: - 数据模型
struct CardItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String
    let color: Color
}

// MARK: - 卡片视图 (源视图)
struct CardView: View {
    let card: CardItem
    let namespace: Namespace.ID

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(card.color.gradient)
            .aspectRatio(3.0/4.0, contentMode: .fit)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: card.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(.white)

                    Text(card.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            // iOS 26: Liquid Glass 效果
            #if swift(>=6.0)
            .glassEffect()
            #endif
            // 标记为过渡源
            .matchedTransitionSource(id: card.id, in: namespace)
    }
}

// MARK: - 详情视图 (目标视图)
struct DetailView: View {
    let card: CardItem
    let namespace: Namespace.ID
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // 背景
            card.color.gradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: card.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text(card.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("这是 \(card.title) 的详情页面")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Button("关闭") {
                    onDismiss()
                }
                .font(.headline)
                .foregroundStyle(card.color)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.white, in: Capsule())
                .padding(.bottom, 50)
            }
        }
        // iOS 26: Zoom 过渡动画
        .navigationTransition(.zoom(sourceID: card.id, in: namespace))
    }
}

// MARK: - iOS 26 Liquid Glass Morph 示例
struct LiquidGlassMorphDemo: View {
    @State private var isExpanded = false
    @Namespace private var glassNamespace

    var body: some View {
        VStack {
            Spacer()

            // iOS 26 GlassEffectContainer - 实现 morph 动画
            #if swift(>=6.0)
            GlassEffectContainer {
                if isExpanded {
                    // 展开状态：多个按钮
                    HStack(spacing: 12) {
                        ForEach(["photo", "video", "doc"], id: \.self) { icon in
                            Button {
                                // action
                            } label: {
                                Image(systemName: icon + ".fill")
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                            }
                            .glassEffect()
                            .glassEffectID(icon, in: glassNamespace)
                        }

                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .frame(width: 50, height: 50)
                        }
                        .glassEffect()
                        .glassEffectID("main", in: glassNamespace)
                    }
                } else {
                    // 收起状态：单个按钮
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isExpanded = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .frame(width: 60, height: 60)
                    }
                    .glassEffect()
                    .glassEffectID("main", in: glassNamespace)
                }
            }
            #else
            // iOS 18 回退方案
            Text("需要 iOS 26+ 才能看到 Liquid Glass 效果")
                .foregroundStyle(.secondary)
            #endif

            Spacer().frame(height: 100)
        }
    }
}

#Preview {
    ContentView()
}

#Preview("Liquid Glass Morph") {
    LiquidGlassMorphDemo()
}
