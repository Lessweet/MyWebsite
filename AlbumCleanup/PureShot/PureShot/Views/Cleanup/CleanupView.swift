import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  CleanupView - 清理交互主视图
//  纵向平铺布局，支持选择、物理内爆删除
//  删除效果：内爆 + 粒子汇聚灵动岛 + 奶油色呼吸扩展
// ═══════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct CleanupView: View {
    let group: PhotoGroup
    let onComplete: () -> Void

    @State private var viewModel = CleanupViewModel()
    @Environment(\.dismiss) private var dismiss

    // 滚动液态动效状态
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollVelocity: CGFloat = 0
    @State private var isScrolling: Bool = false

    // 粒子系统状态
    @State private var particles: [CleanupParticle] = []
    @State private var showDynamicIslandGlow = false
    @State private var photoFrames: [String: CGRect] = [:]  // 记录照片位置

    // 设置面板
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geometry in
            let dynamicIslandCenter = CGPoint(x: geometry.size.width / 2, y: 60)

            ZStack {
                // 照片纵向平铺列表（全屏，延伸到顶部）
                photoFlatList(geometry: geometry, dynamicIslandCenter: dynamicIslandCenter)
                    .ignoresSafeArea()

                // 粒子系统：向灵动岛汇聚
                ForEach(particles) { particle in
                    CleanupParticleView(particle: particle)
                }

                // 灵动岛奶油色呼吸光晕
                CleanupDynamicIslandGlow(isActive: $showDynamicIslandGlow)

                // 顶部渐变蒙层 (soft style) - 放在最顶部
                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: Color(uiColor: .systemBackground), location: 0),
                            .init(color: Color(uiColor: .systemBackground).opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .ignoresSafeArea(edges: .top)

                    Spacer()
                }
                .allowsHitTesting(false)

                // 顶部玻璃导航栏
                VStack {
                    GlassNavigationBar(
                        title: "\(group.photos.count) 张相似照片",
                        onBack: { dismiss() },
                        showSettings: $showSettings
                    )
                    Spacer()
                }

                // 底部操作栏 - 使用原生 glassEffect
                if viewModel.showActionBar {
                    VStack {
                        Spacer()
                        LiquidGlassActionBar(
                            keepCount: viewModel.keepCount,
                            deleteCount: viewModel.deleteCount,
                            onConfirm: {
                                triggerImplosionDelete(
                                    screenSize: geometry.size,
                                    dynamicIslandCenter: dynamicIslandCenter
                                )
                            }
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 完成提示
                if viewModel.showCompletionToast {
                    CompletionToast(
                        deletedCount: viewModel.deletedCount,
                        freedSpace: viewModel.formattedFreedSpace,
                        onDismiss: {
                            onComplete()
                            dismiss()
                        }
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.setup(with: group)
        }
        .overlay {
            if showSettings {
                VStack {
                    HStack {
                        Spacer()
                        LiquidBendSettingsPanel()
                            .padding(.top, 56)
                            .padding(.trailing, 16)
                    }
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.3), value: showSettings)
    }

    // MARK: - 触发内爆删除动画

    private func triggerImplosionDelete(screenSize: CGSize, dynamicIslandCenter: CGPoint) {
        // 触觉反馈
        HapticManager.shared.mediumTap()

        // 隐藏操作栏
        withAnimation {
            viewModel.showActionBar = false
        }

        // 获取待删除照片
        guard let group = viewModel.photoGroup else { return }
        let photosToDelete = group.photosToDelete

        // 依次触发内爆
        for (index, photo) in photosToDelete.enumerated() {
            let delay = Double(index) * 0.15  // 肥皂泡依次破碎节奏

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // 标记为内爆状态
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    photo.animationState = .dissolving
                    viewModel.dissolvingPhotos.insert(photo.id)
                }

                // 轻触觉反馈
                HapticManager.shared.lightTap()
            }

            // 生成粒子
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.2) {
                // 获取照片位置（使用记录的位置或默认中心）
                let photoFrame = photoFrames[photo.id]
                let photoCenter = photoFrame.map {
                    CGPoint(x: $0.midX, y: $0.midY)
                } ?? CGPoint(x: screenSize.width / 2, y: 300)

                // 生成粒子
                spawnParticles(from: photoCenter, to: dynamicIslandCenter)
            }
        }

        // 粒子汇聚完成后，灵动岛呼吸扩展
        let totalDelay = Double(photosToDelete.count) * 0.15 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            withAnimation {
                showDynamicIslandGlow = true
            }
            // 成功触觉
            HapticManager.shared.success()
        }

        // 执行真实删除
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 0.3) {
            Task {
                await viewModel.executeDelete()
            }
        }

        // 清理粒子
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 1.5) {
            particles.removeAll()
            showDynamicIslandGlow = false
        }
    }

    // MARK: - 生成粒子

    private func spawnParticles(from start: CGPoint, to target: CGPoint) {
        let particleCount = Int.random(in: 10...15)

        for i in 0..<particleCount {
            let particle = CleanupParticle(
                id: UUID(),
                startPosition: start,
                targetPosition: target,
                delay: Double(i) * 0.025,
                size: CGFloat.random(in: 4...10),
                color: [
                    Color.white,
                    Color.white.opacity(0.8),
                    Color(red: 1.0, green: 0.97, blue: 0.90)  // 奶油色
                ].randomElement()!,
                controlXOffset: CGFloat.random(in: -50...50)  // 创建时确定随机偏移
            )
            particles.append(particle)
        }
    }

    // MARK: - Photo Flat List (纵向平铺布局)

    private func photoFlatList(geometry: GeometryProxy, dynamicIslandCenter: CGPoint) -> some View {
        // 布局参数
        let screenWidth = geometry.size.width
        let horizontalPadding: CGFloat = 40
        let photoWidth = screenWidth - horizontalPadding * 2

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(Array(viewModel.photos.enumerated()), id: \.element.id) { index, photo in
                        let isImploding = viewModel.dissolvingPhotos.contains(photo.id)

                        if photo.animationState != .dissolved {
                            PhotoCardView(
                                photo: photo,
                                photoWidth: photoWidth,
                                isSelected: photo.isSelected || photo.isBestInGroup,
                                onTap: { viewModel.toggleSelection(for: photo) },
                                onLongPress: {
                                    viewModel.toggleSelection(for: photo)
                                    HapticManager.shared.mediumTap()
                                }
                            )
                            .background(
                                GeometryReader { cardGeo in
                                    Color.clear.onAppear {
                                        let frame = cardGeo.frame(in: .global)
                                        photoFrames[photo.id] = frame
                                    }
                                }
                            )
                            // 延迟滚动效果 - 每张照片依次延迟上滑（测试用大延迟）
                            .delayedScroll(delay: Double(index) * 0.3)
                            // 物理内爆效果
                            .scaleEffect(isImploding ? 0 : 1.0)
                            .opacity(isImploding ? 0 : 1.0)
                            .blur(radius: isImploding ? 20 : 0)
                            .id(photo.id)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 120)   // 顶部留白（导航栏下方）
                .padding(.bottom, 120)  // 底部留白（操作栏上方）
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                let newOffset = value
                let delta = newOffset - scrollOffset
                scrollVelocity = delta
                scrollOffset = newOffset
                isScrolling = abs(delta) > 0.5

                // 同步滚动偏移量到全局参数（用于延迟滚动效果）
                LiquidBendParameters.shared.scrollOffset = newOffset

                // 只更新速度，不更新 isScrolling（由 onScrollPhaseChange 控制）
                // 计算归一化速度 (0-1)，速度越快弯曲越强
                let absVelocity = abs(delta)
                let maxVelocity: CGFloat = 15  // 较小的阈值让弯曲更容易触发
                let normalizedSpeed = min(1.0, absVelocity / maxVelocity)
                LiquidBendParameters.shared.scrollSpeed = normalizedSpeed

                if abs(delta) > 30 {
                    HapticManager.shared.lightTap()
                }
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .top)  // 顶部渐变蒙层效果
            // 滚动结束时确保重置液态效果
            .onScrollPhaseChange { oldPhase, newPhase in
                switch newPhase {
                case .idle:
                    // 滚动完全停止
                    LiquidBendParameters.shared.isScrolling = false
                    LiquidBendParameters.shared.isDecelerating = false
                    LiquidBendParameters.shared.scrollSpeed = 0
                case .interacting:
                    // 手指正在触摸滚动
                    LiquidBendParameters.shared.isScrolling = true
                    LiquidBendParameters.shared.isDecelerating = false
                case .decelerating, .animating:
                    // 手指已离开，惯性减速中 - 弯曲应随速度自然减弱
                    LiquidBendParameters.shared.isScrolling = true
                    LiquidBendParameters.shared.isDecelerating = true
                default:
                    break
                }
            }
        }
    }

}


// MARK: - Photo Card View (照片卡片)
// 支持各种比例，超长图等比缩小
// 使用普通毛玻璃背景以支持液态变形效果

@available(iOS 26.0, *)
struct PhotoCardView: View {
    let photo: PhotoAsset
    let photoWidth: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        // 计算照片实际显示尺寸（按原比例，宽度固定）
        let finalHeight = photoWidth / photo.aspectRatio
        let finalWidth = photoWidth

        ZStack {
            // 照片图像
            Group {
                if let image = photo.fullImage ?? photo.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: finalWidth, height: finalHeight)
                        .clipped()
                } else {
                    // 加载中占位
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.psTextSecondaryAdaptive.opacity(0.1))
                        .frame(width: finalWidth, height: finalHeight)
                        .overlay {
                            ProgressView()
                                .tint(Color.psTextSecondaryAdaptive)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            // 选中边框
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.psAccent, lineWidth: 3)
                }
            }
            // 左上角 - 最佳标签（普通毛玻璃背景，支持液态变形）
            .overlay(alignment: .topLeading) {
                if photo.isBestInGroup {
                    BestTagView()
                        .padding(12)
                }
            }
            // 右下角 - 选中标记（普通毛玻璃背景，支持液态变形）
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(.ultraThinMaterial))
                        .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity)  // 水平居中
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onLongPressGesture(perform: onLongPress)
        .onAppear {
            Task {
                await loadHighQualityImage()
            }
        }
    }

    private func loadHighQualityImage() async {
        guard photo.fullImage == nil else { return }

        let maxDimension: CGFloat = 1200
        let targetSize = CGSize(
            width: maxDimension,
            height: maxDimension / photo.aspectRatio
        )

        if let image = await photo.asset.fetchHighQualityImage(targetSize: targetSize) {
            await MainActor.run {
                photo.fullImage = image
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Cleanup Particle Model

struct CleanupParticle: Identifiable {
    let id: UUID
    let startPosition: CGPoint
    let targetPosition: CGPoint
    let delay: Double
    let size: CGFloat
    let color: Color
    let controlXOffset: CGFloat  // 贝塞尔曲线控制点偏移（创建时随机确定）
}

// MARK: - Cleanup Particle View

struct CleanupParticleView: View {
    let particle: CleanupParticle

    @State private var progress: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .blur(radius: 1)
            .position(currentPosition)
            .opacity(opacity)
            .onAppear {
                // 粒子飞向灵动岛的动画
                withAnimation(
                    .easeIn(duration: 0.6)
                    .delay(particle.delay)
                ) {
                    progress = 1
                }

                // 到达时消失
                withAnimation(
                    .easeOut(duration: 0.2)
                    .delay(particle.delay + 0.5)
                ) {
                    opacity = 0
                }
            }
    }

    var currentPosition: CGPoint {
        // 贝塞尔曲线路径
        let t = progress

        // 控制点：让粒子有弧形轨迹（使用预先计算的偏移值）
        let controlX = (particle.startPosition.x + particle.targetPosition.x) / 2 + particle.controlXOffset
        let controlY = min(particle.startPosition.y, particle.targetPosition.y) - 100

        // 二次贝塞尔曲线
        let x = pow(1-t, 2) * particle.startPosition.x +
                2 * (1-t) * t * controlX +
                pow(t, 2) * particle.targetPosition.x

        let y = pow(1-t, 2) * particle.startPosition.y +
                2 * (1-t) * t * controlY +
                pow(t, 2) * particle.targetPosition.y

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Dynamic Island Glow (奶油色呼吸光晕)

struct CleanupDynamicIslandGlow: View {
    @Binding var isActive: Bool

    @State private var breathScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0

    // 奶油色
    let creamColor = Color(red: 1.0, green: 0.97, blue: 0.90)

    var body: some View {
        VStack {
            ZStack {
                // 外层大光晕
                Capsule()
                    .fill(creamColor.opacity(0.4))
                    .frame(width: 180, height: 55)
                    .blur(radius: 35)
                    .scaleEffect(breathScale * 1.8)
                    .opacity(glowOpacity * 0.5)

                // 中层光晕
                Capsule()
                    .fill(creamColor.opacity(0.6))
                    .frame(width: 150, height: 45)
                    .blur(radius: 25)
                    .scaleEffect(breathScale * 1.4)
                    .opacity(glowOpacity * 0.7)

                // 核心光晕
                Capsule()
                    .fill(creamColor)
                    .frame(width: 126, height: 37)
                    .blur(radius: 15)
                    .scaleEffect(breathScale)
                    .opacity(glowOpacity)

                // 白色高光
                Capsule()
                    .fill(Color.white)
                    .frame(width: 100, height: 28)
                    .blur(radius: 10)
                    .scaleEffect(breathScale * 0.9)
                    .opacity(glowOpacity * 0.8)
            }
            .padding(.top, 11)

            Spacer()
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startBreathAnimation()
            }
        }
    }

    func startBreathAnimation() {
        // 呼吸扩展动画
        withAnimation(.easeOut(duration: 0.3)) {
            glowOpacity = 1.0
            breathScale = 1.5
        }

        // 收缩
        withAnimation(.easeInOut(duration: 0.4).delay(0.3)) {
            breathScale = 1.2
        }

        // 再次扩展
        withAnimation(.easeInOut(duration: 0.3).delay(0.7)) {
            breathScale = 1.6
        }

        // 最终消散
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            breathScale = 2.0
            glowOpacity = 0
        }
    }
}

// MARK: - Glass Navigation Bar (透明玻璃导航栏)

@available(iOS 26.0, *)
struct GlassNavigationBar: View {
    let title: String
    let onBack: () -> Void
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 左侧返回按钮 - 圆形玻璃（带交互效果）
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular.interactive(), in: Circle())

            Spacer()

            // 中间标题
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.primary)

            Spacer()

            // 右侧设置按钮
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showSettings.toggle()
                }
                HapticManager.shared.lightTap()
            } label: {
                Image(systemName: showSettings ? "xmark" : "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular.interactive(), in: Circle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}

// MARK: - Best Tag View (带扫光效果的最佳标签)

@available(iOS 26.0, *)
struct BestTagView: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles.2")
                .font(.system(size: 14, weight: .semibold))
            Text("最佳")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(
            // 扫光效果
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0), location: 0.0),
                            .init(color: .white.opacity(0.1), location: 0.3),
                            .init(color: .white.opacity(0.25), location: 0.5),
                            .init(color: .white.opacity(0.1), location: 0.7),
                            .init(color: .white.opacity(0), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80)
                .offset(x: shimmerOffset)
                .blur(radius: 1)
        )
        .clipShape(Capsule())
        .onAppear {
            // 持续扫光动画
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CleanupView(
            group: PhotoGroup(photos: []),
            onComplete: {}
        )
    }
}
