import SwiftUI
import Photos

// ═══════════════════════════════════════════════════════════════
//  PhotoAsset - 单张照片封装
//  封装 PHAsset，包含缩略图、质量评分、选中状态
// ═══════════════════════════════════════════════════════════════

@Observable
class PhotoAsset: Identifiable, @unchecked Sendable {
    var id: String
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

    // 文件大小 (用于演示模式)
    var fileSize: Int64 = 0

    // 元数据 - 使用私有存储支持子类重写
    private var _creationDate: Date?
    private var _location: CLLocation?
    private var _aspectRatioOverride: CGFloat?

    var creationDate: Date? {
        get { _creationDate ?? asset.creationDate }
        set { _creationDate = newValue }
    }

    var location: CLLocation? {
        get { _location ?? asset.location }
        set { _location = newValue }
    }

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
        // 演示照片或无效资产使用预设的 fileSize
        if id.hasPrefix("demo_") || asset.localIdentifier.isEmpty {
            if fileSize > 0 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
            return "未知"
        }

        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first,
              let size = resource.value(forKey: "fileSize") as? Int64 else {
            return "未知"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
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

// MARK: - Demo Photo Asset Factory (用于演示模式)

/// 创建演示用的照片资源
enum DemoPhotoFactory {

    /// 创建演示用的照片数组
    static func createDemoPhotos(count: Int = 6) -> [PhotoAsset] {
        var photos: [PhotoAsset] = []

        for i in 0..<count {
            let photo = createDemoPhoto(index: i)
            photos.append(photo)
        }

        return photos
    }

    /// 创建单个演示照片
    static func createDemoPhoto(index: Int) -> PhotoAsset {
        // 使用 PHAsset() 创建空资产
        let emptyAsset = PHAsset()
        let photo = PhotoAsset(asset: emptyAsset)

        // 设置演示数据
        photo.id = "demo_\(index)"
        photo.thumbnail = generateDemoThumbnail(index: index)
        photo.fileSize = Int64.random(in: 5_000_000...15_000_000)
        photo.creationDate = Date().addingTimeInterval(-Double(index) * 30)

        return photo
    }

    /// 生成演示用的缩略图
    private static func generateDemoThumbnail(index: Int) -> UIImage? {
        let colors: [UIColor] = [
            .systemBlue, .systemGreen, .systemOrange,
            .systemPink, .systemPurple, .systemTeal,
            .systemRed, .systemYellow
        ]

        let icons = [
            "photo.fill", "camera.fill", "sun.max.fill",
            "moon.fill", "star.fill", "heart.fill",
            "mountain.2.fill", "leaf.fill"
        ]

        let size = CGSize(width: 300, height: 400) // 3:4 比例
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 背景色
            let color = colors[index % colors.count]
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // 添加一些装饰圆形
            let lighterColor = color.withAlphaComponent(0.3)
            lighterColor.setFill()

            for _ in 0..<15 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let circleSize = CGFloat.random(in: 30...100)
                context.cgContext.fillEllipse(in: CGRect(x: x, y: y, width: circleSize, height: circleSize))
            }

            // 中心图标
            let iconName = icons[index % icons.count]
            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .medium)
            if let icon = UIImage(systemName: iconName, withConfiguration: config) {
                let iconSize = icon.size
                let iconX = (size.width - iconSize.width) / 2
                let iconY = (size.height - iconSize.height) / 2

                UIColor.white.withAlphaComponent(0.9).setFill()
                icon.withTintColor(.white.withAlphaComponent(0.9), renderingMode: .alwaysOriginal)
                    .draw(at: CGPoint(x: iconX, y: iconY))
            }

            // 右上角编号
            let text = "\(index + 1)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textX = size.width - textSize.width - 16
            let textY: CGFloat = 16
            text.draw(at: CGPoint(x: textX, y: textY), withAttributes: attributes)
        }
    }
}
