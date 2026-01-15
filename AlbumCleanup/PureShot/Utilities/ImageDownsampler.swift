import UIKit
import Photos

// ═══════════════════════════════════════════════════════════════
//  ImageDownsampler - 图片下采样工具
//  高效的图片缩放，用于 Vision 特征提取加速
// ═══════════════════════════════════════════════════════════════

enum ImageDownsampler {

    /// 下采样图片到指定尺寸
    /// - Parameters:
    ///   - image: 原始图片
    ///   - targetSize: 目标尺寸
    ///   - scale: 屏幕 scale
    /// - Returns: 下采样后的图片
    static func downsample(
        image: UIImage,
        to targetSize: CGSize = Constants.Similarity.downsampleSize,
        scale: CGFloat = 1.0
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height) * scale
        ]

        guard let data = image.jpegData(compressionQuality: 0.8),
              let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }

    /// 从 Data 下采样
    static func downsample(
        data: Data,
        to targetSize: CGSize = Constants.Similarity.downsampleSize,
        scale: CGFloat = 1.0
    ) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height) * scale
        ]

        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }

    /// 从 URL 下采样
    static func downsample(
        url: URL,
        to targetSize: CGSize = Constants.Similarity.downsampleSize,
        scale: CGFloat = 1.0
    ) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height) * scale
        ]

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }
}

// MARK: - PHAsset Extension for Thumbnail

extension PHAsset {
    /// 异步获取缩略图
    func thumbnail(
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
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// 异步获取高质量图片
    func highQualityImage(
        targetSize: CGSize? = nil
    ) async -> UIImage? {
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
}
