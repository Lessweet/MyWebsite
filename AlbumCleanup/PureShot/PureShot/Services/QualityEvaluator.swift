import Vision
import UIKit
import CoreImage

// ═══════════════════════════════════════════════════════════════
//  QualityEvaluator - AI 照片质量评估
//  结合清晰度、曝光、人脸属性等多维度评分
// ═══════════════════════════════════════════════════════════════

actor QualityEvaluator {
    static let shared = QualityEvaluator()

    private let context = CIContext()

    private init() {}

    // MARK: - Quality Evaluation

    /// 评估照片质量
    func evaluate(image: UIImage) async -> QualityScore {
        guard let ciImage = CIImage(image: image) else {
            return .placeholder
        }

        async let sharpness = evaluateSharpness(ciImage)
        async let exposure = evaluateExposure(ciImage)
        async let noise = evaluateNoise(ciImage)
        async let faceQuality = evaluateFaces(image)

        return await QualityScore(
            sharpness: sharpness,
            exposure: exposure,
            noise: noise,
            composition: 0.5, // 构图评分需要更复杂的模型
            faceQuality: faceQuality
        )
    }

    /// 批量评估照片质量
    func evaluateBatch(_ assets: [PhotoAsset]) async {
        await withTaskGroup(of: Void.self) { group in
            for asset in assets {
                group.addTask {
                    guard let thumbnail = await asset.asset.thumbnail(
                        size: CGSize(width: 512, height: 512)
                    ) else { return }

                    let score = await self.evaluate(image: thumbnail)

                    await MainActor.run {
                        asset.qualityScore = score
                    }
                }
            }
        }
    }

    // MARK: - Individual Metrics

    /// 评估清晰度 (使用拉普拉斯算子)
    private func evaluateSharpness(_ image: CIImage) -> Float {
        // 使用 Laplacian 滤波检测边缘清晰度
        guard let filter = CIFilter(name: "CILaplacian") else { return 0.5 }
        filter.setValue(image, forKey: kCIInputImageKey)

        guard let output = filter.outputImage else { return 0.5 }

        // 计算方差作为清晰度指标
        let extent = output.extent
        var bitmap = [Float](repeating: 0, count: 4)

        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 16,
            bounds: CGRect(x: extent.midX, y: extent.midY, width: 1, height: 1),
            format: .RGBAf,
            colorSpace: nil
        )

        // 归一化到 0-1
        let variance = abs(bitmap[0])
        return min(1.0, variance / 100)
    }

    /// 评估曝光 (分析直方图)
    private func evaluateExposure(_ image: CIImage) -> Float {
        guard let filter = CIFilter(name: "CIAreaAverage") else { return 0.5 }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: image.extent), forKey: kCIInputExtentKey)

        guard let output = filter.outputImage else { return 0.5 }

        var bitmap = [Float](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 16,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBAf,
            colorSpace: nil
        )

        // 计算亮度 (使用感知亮度公式)
        let luminance = 0.299 * bitmap[0] + 0.587 * bitmap[1] + 0.114 * bitmap[2]
        return luminance
    }

    /// 评估噪点 (简化版本)
    private func evaluateNoise(_ image: CIImage) -> Float {
        // 使用高斯模糊前后差异估算噪点
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return 0.5 }
        blurFilter.setValue(image, forKey: kCIInputImageKey)
        blurFilter.setValue(2.0, forKey: kCIInputRadiusKey)

        guard let blurred = blurFilter.outputImage else { return 0.5 }

        // 计算原图与模糊图的差异
        guard let diffFilter = CIFilter(name: "CIDifferenceBlendMode") else { return 0.5 }
        diffFilter.setValue(image, forKey: kCIInputImageKey)
        diffFilter.setValue(blurred, forKey: kCIInputBackgroundImageKey)

        guard let diff = diffFilter.outputImage else { return 0.5 }

        // 计算差异的平均值
        guard let avgFilter = CIFilter(name: "CIAreaAverage") else { return 0.5 }
        avgFilter.setValue(diff, forKey: kCIInputImageKey)
        avgFilter.setValue(CIVector(cgRect: diff.extent), forKey: kCIInputExtentKey)

        guard let output = avgFilter.outputImage else { return 0.5 }

        var bitmap = [Float](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 16,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBAf,
            colorSpace: nil
        )

        // 差异越小，噪点越少，分数越高
        let avgDiff = (bitmap[0] + bitmap[1] + bitmap[2]) / 3
        return max(0, 1 - avgDiff * 10)
    }

    /// 评估人脸质量
    private func evaluateFaces(_ image: UIImage) async -> FaceQuality? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceCaptureQualityRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNFaceObservation],
                      !observations.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                var totalFocus: Float = 0

                for face in observations {
                    // 人脸捕获质量作为整体清晰度
                    totalFocus += face.faceCaptureQuality ?? 0.5
                }

                let count = Float(observations.count)
                let faceQuality = FaceQuality(
                    faceCount: observations.count,
                    eyesOpen: 0.8, // Vision 框架不直接提供，使用默认值
                    smile: 0.5,
                    faceFocus: totalFocus / count
                )

                continuation.resume(returning: faceQuality)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
