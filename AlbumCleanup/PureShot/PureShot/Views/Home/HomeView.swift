import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  HomeView - 主页
//  光波扫描入口，展示发现的相似照片组
// ═══════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var hasStartedScan = false

    // 标题位移动画命名空间
    @Namespace private var titleAnimation

    // 卡片展开动画命名空间 - 用于 Zoom Transition
    @Namespace private var cardTransition

    // 副标题切换状态
    @State private var subtitleIndex = 0
    private let subtitleTimer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    /// 扫描期间使用深色背景以突出光波效果
    private var backgroundColor: Color {
        switch viewModel.scanState {
        case .idle, .scanning, .analyzing:
            // 扫描期间使用深色背景 #0A0A0A
            return Color(hex: 0x0A0A0A)
        default:
            return Color.psBackgroundAdaptive
        }
    }

    /// 扫描期间文字使用浅色
    private var textPrimaryColor: Color {
        switch viewModel.scanState {
        case .idle, .scanning, .analyzing:
            return Color(hex: 0xF5F5F5)
        default:
            return Color.psTextPrimaryAdaptive
        }
    }

    private var textSecondaryColor: Color {
        switch viewModel.scanState {
        case .idle, .scanning, .analyzing:
            return Color(hex: 0x8E8E93)
        default:
            return Color.psTextSecondaryAdaptive
        }
    }

    /// 副标题文案数组
    private var subtitleTexts: [String] {
        let groupCount = viewModel.photoGroups.count
        let totalSpace = viewModel.photoGroups.reduce(Int64(0)) { $0 + $1.estimatedSpaceSaved }
        let spaceString = ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
        return [
            "Smart Album Cleanup",
            "\(groupCount) groups · Save \(spaceString)"
        ]
    }

    var body: some View {
        // 使用原生 NavigationStack + Zoom Transition
        NavigationStack {
            ZStack {
                // 背景 - 扫描时使用深色
                backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: viewModel.scanState)

                // 主内容
                mainContent

                // 光波扫描效果
                if viewModel.showLightWave {
                    DynamicIslandGlow(isActive: $viewModel.showLightWave)
                    LightWaveScanEffect(isActive: $viewModel.showLightWave)
                }

                // 动画标题 - 扫描时居中，结果页在左上角
                VStack {
                    if isShowingResults {
                        // 结果页：标题在顶部，但由 ScrollView 控制
                        Spacer()
                    } else {
                        // 扫描时：标题居中
                        Spacer()
                        animatedTitle
                        Spacer()
                    }
                }
            }
            .animation(.spring(response: 1.0, dampingFraction: 0.8), value: isShowingResults)
            .navigationBarHidden(true)
        }
        .task {
            // 应用启动时自动开始扫描
            guard !hasStartedScan else { return }
            hasStartedScan = true
            // 短暂延迟让界面先渲染
            try? await Task.sleep(nanoseconds: 300_000_000)
            await viewModel.startScan()
        }
        .onReceive(subtitleTimer) { _ in
            // 扫描结果页时切换副标题
            if isShowingResults && !viewModel.photoGroups.isEmpty {
                withAnimation(.easeInOut(duration: 0.5)) {
                    subtitleIndex = (subtitleIndex + 1) % subtitleTexts.count
                }
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.scanState {
        case .completed:
            // 扫描完成时，标题和内容一起滚动
            completedState
                .padding(.horizontal, Constants.Layout.horizontalPadding)
        default:
            // 其他状态保持原有布局
            VStack(spacing: 0) {
                Spacer()

                // 中间内容区域
                centerContent

                Spacer()
            }
            .padding(.horizontal, Constants.Layout.horizontalPadding)
        }
    }

    /// 是否显示结果页（标题在左上角）
    private var isShowingResults: Bool {
        if case .completed = viewModel.scanState { return true }
        return false
    }

    // MARK: - Animated Title (带动画的标题)

    private var animatedTitle: some View {
        VStack(alignment: isShowingResults ? .leading : .center, spacing: 4) {
            Text("PureShot")
                .font(.system(size: 40, weight: .heavy, design: .default))
                .scaleEffect(x: 0.85, y: 1.0, anchor: isShowingResults ? .leading : .center)
                .foregroundStyle(textPrimaryColor)
                .matchedGeometryEffect(id: "title", in: titleAnimation)

            // 副标题 - 开屏固定显示，结果页切换显示
            Text("Smart Album Cleanup")
                .font(.subheadline)
                .foregroundStyle(textSecondaryColor)
                .matchedGeometryEffect(id: "subtitle", in: titleAnimation)
        }
        .frame(maxWidth: .infinity, alignment: isShowingResults ? .leading : .center)
        .padding(.horizontal, Constants.Layout.horizontalPadding)
        .padding(.top, isShowingResults ? 20 : 0)
        .onLongPressGesture {
            // 长按标题进入演示模式（开发测试用）
            Task {
                await viewModel.startDemoScan()
            }
        }
    }

    // MARK: - Center Content

    @ViewBuilder
    private var centerContent: some View {
        switch viewModel.scanState {
        case .idle:
            idleState

        case .scanning, .analyzing:
            scanningState

        case .completed:
            completedState

        case .noSimilarPhotos:
            noPhotosState

        case .error(let message):
            errorState(message: message)
        }
    }

    // MARK: - States

    private var idleState: some View {
        // 开屏只显示标题，无其他内容
        EmptyView()
    }

    private var scanningState: some View {
        // 扫描中：页面只显示顶部的 "PureShot 智能相册清理"
        // 配合灵动岛光波扫描动画，保持极简
        EmptyView()
    }

    private var completedState: some View {
        let columns = [
            GridItem(.flexible(), spacing: 24),
            GridItem(.flexible(), spacing: 24)
        ]

        return ZStack {
            // 可滚动内容 - 标题 + 双列布局
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // 标题区域 - 跟随滚动，使用 matchedGeometryEffect 实现平滑过渡
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center) {
                            Text("PureShot")
                                .font(.system(size: 40, weight: .heavy, design: .default))
                                .scaleEffect(x: 0.85, y: 1.0, anchor: .leading)
                                .foregroundStyle(textPrimaryColor)
                                .matchedGeometryEffect(id: "title", in: titleAnimation)

                            Spacer()

                            // 重新扫描按钮 - 与标题水平对齐
                            Button {
                                Task {
                                    await viewModel.rescan()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                    .frame(width: 44, height: 44)
                            }
                            .glassEffect(.regular.interactive(), in: Circle())
                        }

                        // 副标题 - 切换显示（始终从左到右）
                        ZStack(alignment: .leading) {
                            Text(subtitleTexts[subtitleIndex])
                                .font(.subheadline)
                                .foregroundStyle(textSecondaryColor)
                                .id(subtitleIndex)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .offset(x: 30)),
                                    removal: .opacity.combined(with: .offset(x: -30))
                                ))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut(duration: 0.5), value: subtitleIndex)
                        .matchedGeometryEffect(id: "subtitle", in: titleAnimation)
                    }
                    .padding(.top, 20)  // 距离顶部间距

                    // 双列卡片 - 使用原生 NavigationLink + Zoom Transition
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.photoGroups.enumerated()), id: \.element.id) { index, group in
                            NavigationLink {
                                // 目标视图：全屏清理页
                                CleanupDetailView(
                                    group: group,
                                    viewModel: viewModel
                                )
                                .navigationTransition(.zoom(sourceID: group.id, in: cardTransition))
                                .navigationBarHidden(true)
                            } label: {
                                CompactGroupCard(
                                    group: group,
                                    index: index
                                )
                            }
                            .buttonStyle(.plain)
                            .matchedTransitionSource(id: group.id, in: cardTransition)
                        }
                    }
                }
                .padding(.bottom, 100) // 底部留白给按钮
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.automatic)

            // 顶部渐变蒙层 - 复用 CleanupView 样式
            VStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(uiColor: .systemBackground), location: 0),
                        .init(color: Color(uiColor: .systemBackground).opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .ignoresSafeArea(edges: .top)

                Spacer()
            }
            .allowsHitTesting(false)

            // 底部渐变蒙层 - 固定在屏幕底部
            VStack {
                Spacer()

                LinearGradient(
                    stops: [
                        .init(color: Color(uiColor: .systemBackground).opacity(0), location: 0),
                        .init(color: Color(uiColor: .systemBackground), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)

            // 底部一键清理按钮 - 居中
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button {
                        // TODO: 一键清理功能
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles.2")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Quick Clean")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                    }
                    .glassEffect(.regular.interactive(), in: Capsule())

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
            }
        }
    }

    private var noPhotosState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.psAccent.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.psAccent)
            }

            Text("Great!\nNo similar photos found")
                .font(.body)
                .foregroundStyle(Color.psTextSecondaryAdaptive)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.rescan()
                }
            } label: {
                Text("Rescan")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.psAccent)
            }
        }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.psDestructive.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.psDestructive)
            }

            Text(message)
                .font(.body)
                .foregroundStyle(Color.psTextSecondaryAdaptive)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.startScan()
                }
            } label: {
                Text("Retry")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.psAccent)
            }
        }
    }
}

// MARK: - Compact Group Card (双列布局用)

@available(iOS 26.0, *)
struct CompactGroupCard: View {
    let group: PhotoGroup
    let index: Int

    @State private var appeared = false

    private var column: Int { index % 2 }
    private var row: Int { index / 2 }

    private var appearDelay: Double {
        let titleAnimationDuration = 0.5
        if row < 3 {
            return titleAnimationDuration + Double(row) * 0.1 + Double(column) * 0.08
        } else {
            return titleAnimationDuration + Double(column) * 0.08
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 照片
            photoImage

            // 信息
            infoSection
        }
        .padding(.vertical, 10)
        .offset(y: appeared ? 0 : 30)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85).delay(appearDelay)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var photoImage: some View {
        if let thumbnail = group.bestPhoto?.thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.psTextSecondaryAdaptive.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(group.photos.count) Similar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.psTextPrimaryAdaptive)

            Text(group.latestDate.formatted(.dateTime.month().day()))
                .font(.caption)
                .foregroundStyle(Color.psTextSecondaryAdaptive)

            Text("Save \(group.formattedSpaceSaved)")
                .font(.caption)
                .foregroundStyle(Color.psAccent)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Cleanup Detail View (原生 Zoom Transition 目标视图)

@available(iOS 26.0, *)
struct CleanupDetailView: View {
    let group: PhotoGroup
    let viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var cleanupViewModel = CleanupViewModel()

    // 粒子系统状态
    @State private var particles: [CleanupParticle] = []
    @State private var showDynamicIslandGlow = false
    @State private var photoFrames: [String: CGRect] = [:]

    // 动画状态 - 分阶段控制
    @State private var contentAppeared = false
    @State private var checkmarkAppeared = false

    var body: some View {
        GeometryReader { geometry in
            let dynamicIslandCenter = CGPoint(x: geometry.size.width / 2, y: 60)
            let photoWidth = geometry.size.width - 32

            ZStack {
                // 背景
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                // 所有照片在一个 ScrollView 中 - 原生滚动，系统自动处理下拉返回
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 第一张：AI 最佳照片
                        if let bestPhoto = group.bestPhoto {
                            heroPhotoCard(
                                photo: bestPhoto,
                                photoWidth: photoWidth
                            )
                            .onTapGesture {
                                cleanupViewModel.toggleSelection(for: bestPhoto)
                            }
                        }

                        // 其他照片 - 依次出现
                        ForEach(Array(cleanupViewModel.photos.dropFirst().enumerated()), id: \.element.id) { index, photo in
                            let isImploding = cleanupViewModel.dissolvingPhotos.contains(photo.id)
                            let appearDelay = Double(index) * 0.05

                            if photo.animationState != .dissolved {
                                DetailPhotoCard(
                                    photo: photo,
                                    photoWidth: photoWidth,
                                    isSelected: photo.isSelected,
                                    showCheckmark: checkmarkAppeared
                                ) {
                                    cleanupViewModel.toggleSelection(for: photo)
                                }
                                .background(
                                    GeometryReader { cardGeo in
                                        Color.clear.onAppear {
                                            photoFrames[photo.id] = cardGeo.frame(in: .global)
                                        }
                                    }
                                )
                                .scaleEffect(isImploding ? 0 : 1.0)
                                .offset(y: contentAppeared ? 0 : 50)
                                .opacity(isImploding ? 0 : (contentAppeared ? 1 : 0))
                                .blur(radius: isImploding ? 20 : 0)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8).delay(appearDelay),
                                    value: contentAppeared
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 60)
                    .padding(.bottom, 120)
                }

                // 粒子系统
                ForEach(particles) { particle in
                    CleanupParticleView(particle: particle)
                }

                // 灵动岛光晕
                CleanupDynamicIslandGlow(isActive: $showDynamicIslandGlow)

                // 顶部渐变蒙层
                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: Color(uiColor: .systemBackground), location: 0),
                            .init(color: Color(uiColor: .systemBackground).opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .ignoresSafeArea(edges: .top)

                    Spacer()
                }
                .allowsHitTesting(false)

                // 关闭按钮
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.primary)
                                .frame(width: 44, height: 44)
                        }
                        .glassEffect(.regular.interactive(), in: Circle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()
                }

                // 底部渐变蒙层 - 固定在屏幕底部
                VStack {
                    Spacer()

                    LinearGradient(
                        stops: [
                            .init(color: Color(uiColor: .systemBackground).opacity(0), location: 0),
                            .init(color: Color(uiColor: .systemBackground), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)

                // 底部操作栏
                if cleanupViewModel.showActionBar {
                    VStack {
                        Spacer()
                        LiquidGlassActionBar(
                            keepCount: cleanupViewModel.keepCount,
                            deleteCount: cleanupViewModel.deleteCount,
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
                if cleanupViewModel.showCompletionToast {
                    CompletionToast(
                        deletedCount: cleanupViewModel.deletedCount,
                        freedSpace: cleanupViewModel.formattedFreedSpace,
                        onDismiss: {
                            viewModel.completeCleanup(for: group)
                            dismiss()
                        }
                    )
                }
            }
        }
        .onAppear {
            cleanupViewModel.setup(with: group)
            // 延迟显示其他内容，让 Zoom Transition 先完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.3)) {
                    contentAppeared = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    checkmarkAppeared = true
                }
            }
        }
    }

    // MARK: - Hero Photo Card (第一张照片卡片)

    private func heroPhotoCard(photo: PhotoAsset, photoWidth: CGFloat) -> some View {
        let cornerRadius: CGFloat = 24

        return ZStack {
            Group {
                if let image = photo.fullImage ?? photo.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.psTextSecondaryAdaptive.opacity(0.2))
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // Best 标签
            if photo.isBestInGroup {
                VStack {
                    HStack {
                        BestTagView()
                            .padding(12)
                        Spacer()
                    }
                    Spacer()
                }
            }

            // 选中标记
            if photo.isSelected && checkmarkAppeared {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(.ultraThinMaterial))
                            .padding(16)
                    }
                }
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onAppear {
            Task {
                await loadHighQualityImage(for: photo)
            }
        }
    }

    // MARK: - Delete Animation

    private func triggerImplosionDelete(screenSize: CGSize, dynamicIslandCenter: CGPoint) {
        HapticManager.shared.mediumTap()

        withAnimation {
            cleanupViewModel.showActionBar = false
        }

        guard let group = cleanupViewModel.photoGroup else { return }
        let photosToDelete = group.photosToDelete

        for (index, photo) in photosToDelete.enumerated() {
            let delay = Double(index) * 0.15

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    photo.animationState = .dissolving
                    cleanupViewModel.dissolvingPhotos.insert(photo.id)
                }
                HapticManager.shared.lightTap()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.2) {
                let photoFrame = photoFrames[photo.id]
                let photoCenter = photoFrame.map {
                    CGPoint(x: $0.midX, y: $0.midY)
                } ?? CGPoint(x: screenSize.width / 2, y: 300)

                spawnParticles(from: photoCenter, to: dynamicIslandCenter)
            }
        }

        let totalDelay = Double(photosToDelete.count) * 0.15 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            withAnimation {
                showDynamicIslandGlow = true
            }
            HapticManager.shared.success()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 0.3) {
            Task {
                await cleanupViewModel.executeDelete()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 1.5) {
            particles.removeAll()
            showDynamicIslandGlow = false
        }
    }

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
                    Color(red: 1.0, green: 0.97, blue: 0.90)
                ].randomElement()!,
                controlXOffset: CGFloat.random(in: -50...50)
            )
            particles.append(particle)
        }
    }

    private func loadHighQualityImage(for photo: PhotoAsset?) async {
        guard let photo = photo, photo.fullImage == nil else { return }

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

// MARK: - Detail Photo Card (详情页照片卡片)

@available(iOS 26.0, *)
struct DetailPhotoCard: View {
    let photo: PhotoAsset
    let photoWidth: CGFloat
    let isSelected: Bool
    var showCheckmark: Bool = true
    let onTap: () -> Void

    var body: some View {
        let finalHeight = photoWidth / photo.aspectRatio

        Button {
            onTap()
        } label: {
            ZStack {
                Group {
                    if let image = photo.fullImage ?? photo.thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: photoWidth, height: finalHeight)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.psTextSecondaryAdaptive.opacity(0.1))
                            .frame(width: photoWidth, height: finalHeight)
                            .overlay {
                                ProgressView()
                                    .tint(Color.psTextSecondaryAdaptive)
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if isSelected && showCheckmark {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color.primary)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(.ultraThinMaterial))
                                .padding(16)
                        }
                    }
                    .frame(width: photoWidth, height: finalHeight)
                    .transition(.opacity)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
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

// MARK: - Pressable Button Style (按压动画样式)

@available(iOS 26.0, *)
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
