import Foundation
import CoreLocation

// ═══════════════════════════════════════════════════════════════
//  PhotoGroup - 相似照片组数据结构
//  按地理位置、拍摄时间、视觉相似度聚类
// ═══════════════════════════════════════════════════════════════

@Observable
final class PhotoGroup: Identifiable, @unchecked Sendable {
    let id: UUID
    var photos: [PhotoAsset]

    // 聚类元数据
    var clusterType: ClusterType
    var createdAt: Date

    // AI 推荐的最佳照片索引
    var bestPhotoIndex: Int = 0

    // 组状态
    var state: GroupState = .pending

    enum ClusterType {
        case timeBased          // 基于时间聚类 (短时间内连拍)
        case locationBased      // 基于地点聚类
        case visualSimilarity   // 基于视觉相似度
        case mixed              // 混合聚类
    }

    enum GroupState {
        case pending            // 待处理
        case reviewing          // 用户正在查看
        case confirmed          // 用户已确认选择
        case cleaned            // 已清理完成
    }

    init(
        id: UUID = UUID(),
        photos: [PhotoAsset],
        clusterType: ClusterType = .visualSimilarity,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.photos = photos
        self.clusterType = clusterType
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// 最佳照片 (AI 推荐)
    var bestPhoto: PhotoAsset? {
        guard bestPhotoIndex < photos.count else { return photos.first }
        return photos[bestPhotoIndex]
    }

    /// 被选中保留的照片
    var selectedPhotos: [PhotoAsset] {
        photos.filter { $0.isSelected || $0.isBestInGroup }
    }

    /// 待删除的照片
    var photosToDelete: [PhotoAsset] {
        photos.filter { !$0.isSelected && !$0.isBestInGroup }
    }

    /// 保留数量
    var keepCount: Int {
        selectedPhotos.count
    }

    /// 删除数量
    var deleteCount: Int {
        photos.count - keepCount
    }

    /// 组的时间范围描述
    var timeRangeDescription: String {
        guard let first = photos.first?.creationDate,
              let last = photos.last?.creationDate else {
            return "Unknown time"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        if Calendar.current.isDate(first, inSameDayAs: last) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return "\(formatter.string(from: first))"
        } else {
            return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
        }
    }

    /// 组的地点描述
    var locationDescription: String? {
        guard let location = photos.first?.location else { return nil }
        return String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
    }

    /// 预计释放空间
    var estimatedSpaceSaved: Int64 {
        photosToDelete.reduce(0) { total, photo in
            // 演示照片使用预设的 fileSize
            if photo.id.hasPrefix("demo_") {
                return total + photo.fileSize
            }

            // 真实照片从 PHAssetResource 获取大小
            guard !photo.asset.localIdentifier.isEmpty else {
                return total + photo.fileSize
            }

            let resources = PHAssetResource.assetResources(for: photo.asset)
            guard let resource = resources.first,
                  let fileSize = resource.value(forKey: "fileSize") as? Int64 else {
                return total
            }
            return total + fileSize
        }
    }

    var formattedSpaceSaved: String {
        ByteCountFormatter.string(fromByteCount: estimatedSpaceSaved, countStyle: .file)
    }

    /// 组内最新照片的日期（用于按时间排序）
    var latestDate: Date {
        photos.compactMap { $0.creationDate }.max() ?? createdAt
    }

    /// 组内所有照片的总大小（用于按容量排序）
    var totalSize: Int64 {
        photos.reduce(0) { total, photo in
            if photo.id.hasPrefix("demo_") {
                return total + photo.fileSize
            }
            guard !photo.asset.localIdentifier.isEmpty else {
                return total + photo.fileSize
            }
            let resources = PHAssetResource.assetResources(for: photo.asset)
            guard let resource = resources.first,
                  let fileSize = resource.value(forKey: "fileSize") as? Int64 else {
                return total
            }
            return total + fileSize
        }
    }

    // MARK: - Methods

    /// 设置最佳照片
    func setBestPhoto(at index: Int) {
        guard index < photos.count else { return }

        // 清除之前的最佳标记
        photos.forEach { $0.isBestInGroup = false }

        // 设置新的最佳照片
        bestPhotoIndex = index
        photos[index].isBestInGroup = true
        photos[index].isSelected = true
    }

    /// 切换照片选中状态
    func toggleSelection(for photo: PhotoAsset) {
        guard let index = photos.firstIndex(of: photo) else { return }

        // 最佳照片不能取消选中
        if photos[index].isBestInGroup { return }

        photos[index].isSelected.toggle()
    }

    /// 根据质量评分自动选择最佳照片
    func autoSelectBest() {
        guard !photos.isEmpty else { return }

        // 找到评分最高的照片
        var bestIndex = 0
        var bestScore: Float = 0

        for (index, photo) in photos.enumerated() {
            let score = photo.qualityScore?.overallScore ?? 0
            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        setBestPhoto(at: bestIndex)
    }
}

// MARK: - Import Photos

import Photos
