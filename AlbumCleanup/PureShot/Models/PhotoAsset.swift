import SwiftUI
import Photos

// ═══════════════════════════════════════════════════════════════
//  PhotoAsset - 单张照片封装
//  封装 PHAsset，包含缩略图、质量评分、选中状态
// ═══════════════════════════════════════════════════════════════

@Observable
final class PhotoAsset: Identifiable {
    let id: String
    let asset: PHAsset

    // 图片数据
    var thumbnail: UIImage?
    var fullImage: UIImage?

    // 质量评分
    var qualityScore: QualityScore?

    // 选中状态
    var isSelected: Bool = false
    var isBestInGroup: Bool = false

    // 特征向量 (用于相似度比对)
    var featureVector: [Float]?

    // 元数据
    var creationDate: Date? { asset.creationDate }
    var location: CLLocation? { asset.location }
    var pixelWidth: Int { asset.pixelWidth }
    var pixelHeight: Int { asset.pixelHeight }

    // 动画状态
    var animationState: AnimationState = .idle

    enum AnimationState {
        case idle
        case selecting      // 选中动画中
        case deselecting    // 取消选中动画中
        case dissolving     // 融化消失中
        case dissolved      // 已消失
    }

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }

    // MARK: - Computed Properties

    var aspectRatio: CGFloat {
        guard pixelHeight > 0 else { return 1 }
        return CGFloat(pixelWidth) / CGFloat(pixelHeight)
    }

    var formattedDate: String {
        guard let date = creationDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var fileSizeString: String {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first,
              let fileSize = resource.value(forKey: "fileSize") as? Int64 else {
            return "未知"
        }
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - Equatable & Hashable

extension PhotoAsset: Equatable {
    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        lhs.id == rhs.id
    }
}

extension PhotoAsset: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
