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

                // 扫描中只显示品牌名（按照README规范）
            }
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
            .onChange(of: viewModel.scanState) { _, newState in
                // 扫描完成且有结果时，自动跳转到清理视图
                if case .completed = newState {
                    if let firstGroup = viewModel.photoGroups.first {
                        // 短暂延迟让光波消散动画完成
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                            viewModel.selectGroup(firstGroup)
                            showCleanupView = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            // 顶部标题区域
            headerSection
                .padding(.top, 60)

            Spacer()

            // 中间内容区域
            centerContent

            Spacer()
        }
        .padding(.horizontal, Constants.Layout.horizontalPadding)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("PureShot")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(textPrimaryColor)

            Text("智能相册清理")
                .font(.subheadline)
                .foregroundStyle(textSecondaryColor)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.scanState)
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
        ZStack(alignment: .top) {
            // 可滚动内容
            ScrollView {
                VStack(spacing: 16) {
                    // 顶部留白（为导航栏和渐变留空间）
                    Color.clear.frame(height: 70)

                    if viewModel.showResultCard {
                        // 结果卡片
                        ResultCard(
                            groupCount: viewModel.similarGroupsFound,
                            totalPhotos: viewModel.totalPhotosToClean + viewModel.similarGroupsFound,
                            spaceSavable: viewModel.formattedSpaceSavable,
                            onTap: {
                                if let firstGroup = viewModel.photoGroups.first {
                                    viewModel.selectGroup(firstGroup)
                                    showCleanupView = true
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }

                    // 照片组列表
                    if viewModel.photoGroups.count > 1 {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.photoGroups) { group in
                                GroupCard(group: group) {
                                    viewModel.selectGroup(group)
                                    showCleanupView = true
                                }
                            }
                        }
                    }

                    // 重新扫描按钮
                    Button {
                        Task {
                            await viewModel.rescan()
                        }
                    } label: {
                        Text("重新扫描")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.psTextSecondaryAdaptive)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)

            // 顶部渐变遮罩 + 导航栏
            VStack(spacing: 0) {
                // 玻璃导航栏
                HomeGlassNavBar(
                    title: "扫描结果",
                    onRescan: {
                        Task {
                            await viewModel.rescan()
                        }
                    }
                )

                // 渐变过渡效果
                LinearGradient(
                    colors: [
                        Color.psBackgroundAdaptive,
                        Color.psBackgroundAdaptive.opacity(0.8),
                        Color.psBackgroundAdaptive.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)

                Spacer()
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

// MARK: - Home Glass Navigation Bar

@available(iOS 26.0, *)
struct HomeGlassNavBar: View {
    let title: String
    let onRescan: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 左侧占位（保持标题居中）
            Color.clear.frame(width: 36, height: 36)

            Spacer()

            // 中间标题
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.primary)

            Spacer()

            // 右侧刷新按钮
            Button(action: onRescan) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 36, height: 36)
            }
            .glassEffect(.regular, in: Circle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
