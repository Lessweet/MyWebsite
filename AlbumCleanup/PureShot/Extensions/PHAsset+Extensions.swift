import Photos
import UIKit

// ═══════════════════════════════════════════════════════════════
//  PHAsset+Extensions - PHAsset 扩展
//  便捷方法和异步图片加载
// ═══════════════════════════════════════════════════════════════

extension PHAsset {

    /// 异步获取缩略图
    func fetchThumbnail(
        size: CGSize,
        contentMode: PHImageContentMode = .aspectFill
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: self,
                targetSize: size,
                contentMode: contentMode,
                options: options
            ) { image, info in
                // 检查是否是最终图片（非降级版本）
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    /// 异步获取高质量图片
    func fetchHighQualityImage(targetSize: CGSize? = nil) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            let size = targetSize ?? CGSize(width: pixelWidth, height: pixelHeight)

            PHImageManager.default().requestImage(
                for: self,
                targetSize: size,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// 获取图片数据
    func fetchImageData() async -> Data? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(
                for: self,
                options: options
            ) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }

    /// 文件大小
    var fileSize: Int64? {
        let resources = PHAssetResource.assetResources(for: self)
        guard let resource = resources.first else { return nil }
        return resource.value(forKey: "fileSize") as? Int64
    }

    /// 格式化的文件大小
    var formattedFileSize: String {
        guard let size = fileSize else { return "未知" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// 是否是截图
    var isScreenshot: Bool {
        mediaSubtypes.contains(.photoScreenshot)
    }

    /// 是否是 Live Photo
    var isLivePhoto: Bool {
        mediaSubtypes.contains(.photoLive)
    }

    /// 是否是 HDR 照片
    var isHDR: Bool {
        mediaSubtypes.contains(.photoHDR)
    }

    /// 是否是深度照片
    var isDepthEffect: Bool {
        mediaSubtypes.contains(.photoDepthEffect)
    }
}

// MARK: - Batch Operations

extension Array where Element == PHAsset {
    /// 批量获取缩略图
    func fetchThumbnails(size: CGSize) async -> [String: UIImage] {
        var results: [String: UIImage] = [:]

        await withTaskGroup(of: (String, UIImage?).self) { group in
            for asset in self {
                group.addTask {
                    let image = await asset.fetchThumbnail(size: size)
                    return (asset.localIdentifier, image)
                }
            }

            for await (id, image) in group {
                if let image = image {
                    results[id] = image
                }
            }
        }

        return results
    }
}
