import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  HomeView - 主页
//  光波扫描入口，展示发现的相似照片组
// ═══════════════════════════════════════════════════════════════

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showCleanupView = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color.psBackgroundAdaptive
                    .ignoresSafeArea()

                // 主内容
                mainContent

                // 光波扫描效果
                if viewModel.showLightWave {
                    DynamicIslandGlow(isActive: $viewModel.showLightWave)
                    LightWaveScanEffect(isActive: $viewModel.showLightWave)
                }

                // 扫描中文字
                if viewModel.scanState == .scanning || viewModel.scanState == .analyzing {
                    VStack {
                        Spacer()
                        ScanningTextView(isScanning: .constant(true))
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationDestination(isPresented: $showCleanupView) {
                if let group = viewModel.selectedGroup {
                    CleanupView(group: group) {
                        viewModel.completeCleanup(for: group)
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

            // 底部操作区域
            if viewModel.scanState == .idle {
                scanButton
                    .padding(.bottom, 60)
            }
        }
        .padding(.horizontal, Constants.Layout.horizontalPadding)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("PureShot")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.psTextPrimaryAdaptive)

            Text("智能相册清理")
                .font(.subheadline)
                .foregroundStyle(Color.psTextSecondaryAdaptive)
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
            // 图标
            ZStack {
                Circle()
                    .fill(Color.psAccent.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.psAccent)
            }

            Text("点击下方按钮\n开始扫描相似照片")
                .font(.body)
                .foregroundStyle(Color.psTextSecondaryAdaptive)
                .multilineTextAlignment(.center)
        }
    }

    private var scanningState: some View {
        VStack(spacing: 24) {
            // 进度指示
            ZStack {
                Circle()
                    .stroke(Color.psAccent.opacity(0.2), lineWidth: 4)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: viewModel.scanProgress)
                    .stroke(Color.psAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.scanProgress)

                Text("\(Int(viewModel.scanProgress * 100))%")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.psAccent)
            }

            Text(viewModel.scanState == .analyzing ? "分析相似度中..." : "扫描照片中...")
                .font(.body)
                .foregroundStyle(Color.psTextSecondaryAdaptive)
        }
    }

    private var completedState: some View {
        VStack(spacing: 20) {
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.photoGroups) { group in
                            GroupCard(group: group) {
                                viewModel.selectGroup(group)
                                showCleanupView = true
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
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

    // MARK: - Scan Button

    private var scanButton: some View {
        Button {
            Task {
                await viewModel.startScan()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "wand.and.rays")
                    .font(.title3)

                Text("开始扫描")
                    .font(.headline)
            }
            .foregroundStyle(Color.psTextPrimaryAdaptive)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background {
                Capsule()
                    .fill(Color.psAccent)
                    .shadow(color: Color.psAccent.opacity(0.4), radius: 12, x: 0, y: 4)
            }
        }
        .scaleEffect(viewModel.scanState == .idle ? 1 : 0.9)
        .opacity(viewModel.scanState == .idle ? 1 : 0)
        .animation(.spring(response: 0.3), value: viewModel.scanState)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
