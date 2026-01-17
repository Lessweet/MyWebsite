import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  HomeView - 主页
//  光波扫描入口，展示发现的相似照片组
// ═══════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showCleanupView = false
    @State private var hasStartedScan = false

    // 标题位移动画命名空间
    @Namespace private var titleAnimation

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
            .navigationDestination(isPresented: $showCleanupView) {
                if let group = viewModel.selectedGroup {
                    CleanupView(group: group) {
                        viewModel.completeCleanup(for: group)
                    }
                }
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
                .font(.system(size: 44, weight: .bold, design: .default))
                .scaleEffect(x: 0.85, y: 1.0, anchor: isShowingResults ? .leading : .center)
                .foregroundStyle(textPrimaryColor)
                .matchedGeometryEffect(id: "title", in: titleAnimation)

            // 副标题 - 结果页时切换显示（始终从左到右）
            ZStack(alignment: isShowingResults ? .leading : .center) {
                Text(subtitleTexts[subtitleIndex])
                    .font(.subheadline)
                    .foregroundStyle(textSecondaryColor)
                    .id(subtitleIndex)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 30)),
                        removal: .opacity.combined(with: .offset(x: -30))
                    ))
            }
            .frame(maxWidth: .infinity, alignment: isShowingResults ? .leading : .center)
            .animation(.easeInOut(duration: 0.5), value: subtitleIndex)
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
                        Text("PureShot")
                            .font(.system(size: 44, weight: .bold, design: .default))
                            .scaleEffect(x: 0.85, y: 1.0, anchor: .leading)
                            .foregroundStyle(textPrimaryColor)
                            .matchedGeometryEffect(id: "title", in: titleAnimation)

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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)  // 距离顶部间距

                    // 双列卡片 - 间距与标题对齐（外层已有 horizontalPadding）
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.photoGroups.enumerated()), id: \.element.id) { index, group in
                            CompactGroupCard(group: group, index: index) {
                                viewModel.selectGroup(group)
                                showCleanupView = true
                            }
                        }
                    }
                }
                .padding(.bottom, 100) // 底部留白给按钮
            }
            .scrollIndicators(.hidden)

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

            // 底部渐变蒙层
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
                .frame(height: 180)
                .ignoresSafeArea(edges: .bottom)
            }
            .allowsHitTesting(false)

            // 底部按钮栏 - 左：重新扫描，右：一键清理
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    // 重新扫描按钮
                    Button {
                        Task {
                            await viewModel.rescan()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Rescan")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .glassEffect(.regular.interactive(), in: Capsule())

                    // 一键清理按钮
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .glassEffect(.regular.interactive(), in: Capsule())
                }
                .padding(.horizontal, Constants.Layout.horizontalPadding)
                .padding(.bottom, 16)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
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
    let index: Int  // 用于计算动画延迟
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var appeared = false

    // 列号：0=左，1=右
    private var column: Int { index % 2 }
    private var row: Int { index / 2 }

    // 入场延迟：等标题位移完成后（0.5s）再开始，初始可见用行+列延迟
    private var appearDelay: Double {
        let titleAnimationDuration = 0.5  // 等待标题移动到左上角
        if row < 3 {
            return titleAnimationDuration + Double(row) * 0.1 + Double(column) * 0.08
        } else {
            return titleAnimationDuration + Double(column) * 0.08
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 预览图 - 正方形
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

            // 信息
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
        .padding(.vertical, 10)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        // 入场动画：从下方上移 + 渐显
        .offset(y: appeared ? 0 : 30)
        .opacity(appeared ? 1 : 0)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.85)
            .delay(appearDelay),
            value: appeared
        )
        .onAppear {
            appeared = true
        }
        // 滚动过渡效果：只在底部边缘（上滑离开时）向下掉落
        .scrollTransition(.animated(.spring(response: 0.8)), transition: { content, phase in
            let threshold: Double = 0.15
            // 只处理底部边缘，顶部边缘不做效果
            let effectValue = phase.value > threshold ? (phase.value - threshold) : 0

            // 行号越大偏移越多（下面先掉），右列额外偏移（右边先掉）
            let rowFactor = 1.0 + min(Double(row), 5.0) * 0.2
            let columnExtra = column == 1 ? effectValue * 15 : 0

            return content
                .offset(y: effectValue * 25 * rowFactor + columnExtra)
                .opacity(1 - effectValue * 0.4)
        })
        .animation(.spring(response: 0.2), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
