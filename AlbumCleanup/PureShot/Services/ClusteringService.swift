import Foundation
import Photos

// ═══════════════════════════════════════════════════════════════
//  ClusteringService - 时间/地点/相似度聚类
//  智能聚类引擎，将照片分组
// ═══════════════════════════════════════════════════════════════

actor ClusteringService {
    static let shared = ClusteringService()

    private init() {}

    // MARK: - Main Clustering

    /// 综合聚类 - 按时间 + 相似度
    func cluster(photos: [PhotoAsset]) async -> [PhotoGroup] {
        guard !photos.isEmpty else { return [] }

        // 第一步：按时间窗口初步分组
        let timeGroups = clusterByTime(photos)

        // 第二步：在时间组内按相似度细分
        var finalGroups: [PhotoGroup] = []

        for timeGroup in timeGroups {
            if timeGroup.count <= 1 {
                continue // 单张照片不需要聚类
            }

            // 使用相似度引擎进一步聚类
            let similarGroups = await SimilarityEngine.shared.findSimilarGroups(
                from: timeGroup,
                threshold: Constants.Similarity.threshold
            )

            for group in similarGroups {
                let photoGroup = PhotoGroup(
                    photos: group,
                    clusterType: .mixed
                )

                // 评估质量并自动选择最佳照片
                await evaluateAndSelectBest(for: photoGroup)

                finalGroups.append(photoGroup)
            }
        }

        return finalGroups
    }

    // MARK: - Time-based Clustering

    /// 按时间窗口聚类
    func clusterByTime(_ photos: [PhotoAsset]) -> [[PhotoAsset]] {
        guard !photos.isEmpty else { return [] }

        // 按创建时间排序
        let sorted = photos.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }

        var groups: [[PhotoAsset]] = []
        var currentGroup: [PhotoAsset] = []
        var lastDate: Date?

        for photo in sorted {
            guard let date = photo.creationDate else {
                continue
            }

            if let last = lastDate {
                let interval = date.timeIntervalSince(last)

                if interval <= Constants.Similarity.timeWindowSeconds {
                    // 在时间窗口内，加入当前组
                    currentGroup.append(photo)
                } else {
                    // 超出时间窗口，开始新组
                    if currentGroup.count > 1 {
                        groups.append(currentGroup)
                    }
                    currentGroup = [photo]
                }
            } else {
                currentGroup = [photo]
            }

            lastDate = date
        }

        // 添加最后一组
        if currentGroup.count > 1 {
            groups.append(currentGroup)
        }

        return groups
    }

    // MARK: - Location-based Clustering

    /// 按位置聚类
    func clusterByLocation(_ photos: [PhotoAsset]) -> [[PhotoAsset]] {
        guard !photos.isEmpty else { return [] }

        var visited = Set<String>()
        var groups: [[PhotoAsset]] = []

        for photo in photos {
            guard !visited.contains(photo.id),
                  let location = photo.location else {
                continue
            }

            var group: [PhotoAsset] = [photo]
            visited.insert(photo.id)

            // 找出附近的照片
            for otherPhoto in photos {
                guard !visited.contains(otherPhoto.id),
                      let otherLocation = otherPhoto.location else {
                    continue
                }

                let distance = location.distance(from: otherLocation)
                if distance <= Constants.Similarity.locationRadiusMeters {
                    group.append(otherPhoto)
                    visited.insert(otherPhoto.id)
                }
            }

            if group.count > 1 {
                groups.append(group)
            }
        }

        return groups
    }

    // MARK: - Quality Evaluation & Best Selection

    /// 评估组内照片质量并选择最佳
    private func evaluateAndSelectBest(for group: PhotoGroup) async {
        // 批量评估质量
        await QualityEvaluator.shared.evaluateBatch(group.photos)

        // 自动选择最佳照片
        await MainActor.run {
            group.autoSelectBest()
        }
    }

    // MARK: - Quick Scan

    /// 快速扫描 - 仅基于时间，不做相似度分析
    func quickScan(photos: [PhotoAsset]) -> [PhotoGroup] {
        let timeGroups = clusterByTime(photos)

        return timeGroups.map { group in
            let photoGroup = PhotoGroup(
                photos: group,
                clusterType: .timeBased
            )
            // 默认选择第一张作为最佳
            photoGroup.setBestPhoto(at: 0)
            return photoGroup
        }
    }
}
