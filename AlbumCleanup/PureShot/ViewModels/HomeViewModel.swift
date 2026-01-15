import SwiftUI
import Photos

// ═══════════════════════════════════════════════════════════════
//  HomeViewModel - 主页状态管理
//  处理相册扫描、聚类、导航
// ═══════════════════════════════════════════════════════════════

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - State

    enum ScanState: Equatable {
        case idle               // 空闲
        case scanning           // 扫描中
        case analyzing          // 分析相似度中
        case completed          // 完成
        case noSimilarPhotos    // 没有找到相似照片
        case error(String)      // 错误

        static func == (lhs: ScanState, rhs: ScanState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.scanning, .scanning): return true
            case (.analyzing, .analyzing): return true
            case (.completed, .completed): return true
            case (.noSimilarPhotos, .noSimilarPhotos): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    var scanState: ScanState = .idle

    // 扫描进度 (0-1)
    var scanProgress: Double = 0

    // 发现的相似照片组
    var photoGroups: [PhotoGroup] = []

    // 当前选中的组 (用于清理视图)
    var selectedGroup: PhotoGroup?

    // 总计可释放空间
    var totalSpaceSavable: Int64 = 0

    // 动画状态
    var showLightWave: Bool = false
    var showResultCard: Bool = false

    // 统计信息
    var totalPhotosScanned: Int = 0
    var similarGroupsFound: Int { photoGroups.count }
    var totalPhotosToClean: Int {
        photoGroups.reduce(0) { $0 + $1.deleteCount }
    }

    // MARK: - Dependencies

    private let photoService = PhotoLibraryService.shared

    // MARK: - Actions

    /// 开始扫描
    func startScan() async {
        // 重置状态
        scanState = .scanning
        scanProgress = 0
        showLightWave = true
        showResultCard = false

        // 触觉反馈
        HapticManager.shared.lightWaveScan()

        // 检查授权
        guard photoService.isAuthorized else {
            let status = await photoService.requestAuthorization()
            if status != .authorized && status != .limited {
                scanState = .error("需要相册访问权限")
                showLightWave = false
                return
            }
        }

        // 获取最近照片
        scanProgress = 0.2
        let photos = await photoService.fetchRecentPhotos(limit: 200)
        totalPhotosScanned = photos.count

        if photos.isEmpty {
            scanState = .noSimilarPhotos
            showLightWave = false
            return
        }

        // 加载缩略图
        scanProgress = 0.4
        await photoService.loadThumbnails(
            for: photos,
            size: CGSize(width: 200, height: 200)
        )

        // 切换到分析状态
        scanState = .analyzing
        scanProgress = 0.6

        // 聚类分析
        let groups = await ClusteringService.shared.cluster(photos: photos)
        scanProgress = 0.9

        // 更新结果
        photoGroups = groups

        if groups.isEmpty {
            scanState = .noSimilarPhotos
        } else {
            // 计算可释放空间
            totalSpaceSavable = groups.reduce(0) { $0 + $1.estimatedSpaceSaved }
            scanState = .completed
        }

        // 完成动画
        scanProgress = 1.0

        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        showLightWave = false

        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        showResultCard = true

        // 完成触觉
        HapticManager.shared.success()
    }

    /// 选择一个组进行清理
    func selectGroup(_ group: PhotoGroup) {
        selectedGroup = group
        group.state = .reviewing
        HapticManager.shared.lightTap()
    }

    /// 完成清理后刷新
    func completeCleanup(for group: PhotoGroup) {
        group.state = .cleaned

        // 从列表中移除已清理的组
        if let index = photoGroups.firstIndex(where: { $0.id == group.id }) {
            photoGroups.remove(at: index)
        }

        selectedGroup = nil

        // 重新计算可释放空间
        totalSpaceSavable = photoGroups.reduce(0) { $0 + $1.estimatedSpaceSaved }
    }

    /// 重新扫描
    func rescan() async {
        photoGroups.removeAll()
        selectedGroup = nil
        await startScan()
    }

    // MARK: - Formatted Strings

    var formattedSpaceSavable: String {
        ByteCountFormatter.string(fromByteCount: totalSpaceSavable, countStyle: .file)
    }

    var scanResultText: String {
        switch scanState {
        case .completed:
            return "发现 \(similarGroupsFound) 组相似照片"
        case .noSimilarPhotos:
            return "没有发现相似照片"
        case .error(let message):
            return message
        default:
            return ""
        }
    }
}
