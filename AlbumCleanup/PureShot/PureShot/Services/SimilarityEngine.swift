@preconcurrency import Vision
import UIKit
import CoreML

// ═══════════════════════════════════════════════════════════════
//  SimilarityEngine - Vision 相似度计算引擎
//  使用 VNGenerateImageFeaturePrintRequest 计算图片特征向量
// ═══════════════════════════════════════════════════════════════

actor SimilarityEngine {
    static let shared = SimilarityEngine()

    // 特征向量缓存
    private var featureCache: [String: VNFeaturePrintObservation] = [:]

    private init() {}

    // MARK: - Feature Extraction

    /// 提取单张图片的特征向量
    func extractFeature(from image: UIImage) async throws -> VNFeaturePrintObservation {
        guard let cgImage = image.cgImage else {
            throw SimilarityError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateImageFeaturePrintRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observation = request.results?.first as? VNFeaturePrintObservation else {
                    continuation.resume(throwing: SimilarityError.featureExtractionFailed)
                    return
                }

                continuation.resume(returning: observation)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// 批量提取特征向量 (并行处理)
    func extractFeatures(from assets: [PhotoAsset]) async -> [String: VNFeaturePrintObservation] {
        var results: [String: VNFeaturePrintObservation] = [:]

        // 首先检查缓存
        var assetsToProcess: [PhotoAsset] = []
        for asset in assets {
            if let cached = featureCache[asset.id] {
                results[asset.id] = cached
            } else {
                assetsToProcess.append(asset)
            }
        }

        // 并行处理未缓存的资源
        let newResults = await withTaskGroup(of: (String, VNFeaturePrintObservation?).self, returning: [String: VNFeaturePrintObservation].self) { group in
            for asset in assetsToProcess {
                group.addTask {
                    // 下采样后提取特征
                    guard let thumbnail = await asset.asset.thumbnail(
                        size: Constants.Similarity.downsampleSize
                    ) else {
                        return (asset.id, nil)
                    }

                    do {
                        let feature = try await self.extractFeature(from: thumbnail)
                        return (asset.id, feature)
                    } catch {
                        print("Feature extraction failed for \(asset.id): \(error)")
                        return (asset.id, nil)
                    }
                }
            }

            var taskResults: [String: VNFeaturePrintObservation] = [:]
            for await (id, feature) in group {
                if let feature = feature {
                    taskResults[id] = feature
                }
            }
            return taskResults
        }

        // 更新缓存和结果
        for (id, feature) in newResults {
            featureCache[id] = feature
            results[id] = feature
        }

        return results
    }

    // MARK: - Similarity Calculation

    /// 计算两个特征向量的相似度 (0-1)
    func calculateSimilarity(
        _ feature1: VNFeaturePrintObservation,
        _ feature2: VNFeaturePrintObservation
    ) throws -> Float {
        var distance: Float = 0
        try feature1.computeDistance(&distance, to: feature2)

        // 将距离转换为相似度 (距离越小，相似度越高)
        // Vision 框架特征向量距离通常在 0-20 之间
        // 距离 < 5: 非常相似, 5-10: 相似, 10-15: 有些相似, > 15: 不相似
        let maxDistance: Float = 15.0
        let similarity = max(0, 1 - distance / maxDistance)
        return similarity
    }

    /// 找出相似照片组
    func findSimilarGroups(
        from assets: [PhotoAsset],
        threshold: Float = Constants.Similarity.threshold
    ) async -> [[PhotoAsset]] {
        print("🔍 开始相似度分析，照片数量: \(assets.count)，阈值: \(threshold)")

        // 提取所有特征
        let features = await extractFeatures(from: assets)
        print("📊 成功提取特征数量: \(features.count)")

        // 构建相似度矩阵
        var visited = Set<String>()
        var groups: [[PhotoAsset]] = []

        for asset in assets {
            guard !visited.contains(asset.id),
                  let feature1 = features[asset.id] else {
                if features[asset.id] == nil {
                    print("⚠️ 照片特征提取失败: \(asset.id)")
                }
                continue
            }

            var group: [PhotoAsset] = [asset]
            visited.insert(asset.id)

            // 找出与当前照片相似的其他照片
            for otherAsset in assets {
                guard !visited.contains(otherAsset.id),
                      let feature2 = features[otherAsset.id] else {
                    continue
                }

                do {
                    let similarity = try calculateSimilarity(feature1, feature2)
                    print("📐 相似度: \(String(format: "%.3f", similarity)) (\(asset.id.prefix(8))... vs \(otherAsset.id.prefix(8))...)")

                    if similarity >= threshold {
                        group.append(otherAsset)
                        visited.insert(otherAsset.id)
                        print("✅ 找到相似照片!")
                    }
                } catch {
                    print("❌ 相似度计算失败: \(error)")
                    continue
                }
            }

            // 只有多于 1 张的才算相似组
            if group.count > 1 {
                // 按时间从新到旧排序
                let sortedGroup = group.sorted {
                    ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
                }
                groups.append(sortedGroup)
                print("📦 创建相似组，包含 \(sortedGroup.count) 张照片")
            }
        }

        print("🎯 分析完成，找到 \(groups.count) 个相似组")
        return groups
    }

    // MARK: - Cache Management

    func clearCache() {
        featureCache.removeAll()
    }

    func cacheFeature(_ feature: VNFeaturePrintObservation, for id: String) {
        featureCache[id] = feature
    }
}

// MARK: - Errors

enum SimilarityError: Error, LocalizedError {
    case invalidImage
    case featureExtractionFailed
    case comparisonFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片"
        case .featureExtractionFailed:
            return "特征提取失败"
        case .comparisonFailed:
            return "相似度比较失败"
        }
    }
}
