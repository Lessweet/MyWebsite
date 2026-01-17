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
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowingResults)
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
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(textPrimaryColor)
                .matchedGeometryEffect(id: "title", in: titleAnimation)

            Text("智能相册清理")
                .font(.subheadline)
                .foregroundStyle(textSecondaryColor)
                .matchedGeometryEffect(id: "subtitle", in: titleAnimation)
        }
        .frame(maxWidth: .infinity, alignment: isShowingResults ? .leading : .center)
        .padding(.horizontal, Constants.Layout.horizontalPadding)
        .padding(.top, isShowingResults ? 8 : 0)
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
        VStack(spacing: 24) {
            // 准备扫描的提示
            ZStack {
                Circle()
                    .fill(Color.psAccent.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.psAccent)
            }

            Text("准备扫描...")
                .font(.body)
                .foregroundStyle(textSecondaryColor)
                .multilineTextAlignment(.center)
        }
    }

    private var scanningState: some View {
        // 扫描中：页面只显示顶部的 "PureShot 智能相册清理"
        // 配合灵动岛光波扫描动画，保持极简
        EmptyView()
    }

    private var completedState: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return ZStack {
            // 可滚动内容 - 标题 + 双列布局
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题区域 - 跟随滚动，使用 matchedGeometryEffect 实现平滑过渡
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PureShot")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(textPrimaryColor)
                            .matchedGeometryEffect(id: "title", in: titleAnimation)

                        Text("智能相册清理")
                            .font(.subheadline)
                            .foregroundStyle(textSecondaryColor)
                            .matchedGeometryEffect(id: "subtitle", in: titleAnimation)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)  // 原生导航栏标准间距

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

            // 底部重新扫描按钮 - 玻璃效果
            VStack {
                Spacer()

                Button {
                    Task {
                        await viewModel.rescan()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .semibold))
                        Text("重新扫描")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                }
                .glassEffect(.regular.interactive(), in: Capsule())
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

            Text("太棒了！\n没有发现相似照片")
                .font(.body)
                .foregroundStyle(Color.psTextSecondaryAdaptive)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.rescan()
                }
            } label: {
                Text("重新扫描")
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
                Text("重试")
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

    // 基于行号计算延迟：同一行左右列错开，行间也错开
    // 行号 = index / 2，列号 = index % 2
    // 初始可见（前3行=6个）用行延迟，之后只用列延迟
    private var animationDelay: Double {
        let row = index / 2
        let column = index % 2

        if row < 3 {
            // 初始可见的前3行：行延迟 + 列延迟
            return Double(row) * 0.1 + Double(column) * 0.05
        } else {
            // 滚动出现的卡片：只用列延迟（右列比左列晚一点）
            return Double(column) * 0.06
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
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.psTextSecondaryAdaptive.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
            }

            // 信息
            VStack(alignment: .leading, spacing: 2) {
                Text("\(group.photos.count) 张相似")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.psTextPrimaryAdaptive)

                Text("可节省 \(group.formattedSpaceSaved)")
                    .font(.caption)
                    .foregroundStyle(Color.psAccent)
            }
            .padding(.horizontal, 4)
        }
        .padding(10)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        // 入场动画：从下方上移 + 渐显
        .offset(y: appeared ? 0 : 30)
        .opacity(appeared ? 1 : 0)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.85)
            .delay(animationDelay),
            value: appeared
        )
        .onAppear {
            appeared = true
        }
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
