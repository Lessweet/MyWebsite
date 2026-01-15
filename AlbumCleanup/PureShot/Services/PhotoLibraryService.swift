import Photos
import UIKit

// ═══════════════════════════════════════════════════════════════
//  PhotoLibraryService - Photos Framework 交互
//  相册访问、照片获取、删除操作
// ═══════════════════════════════════════════════════════════════

@MainActor
@Observable
final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    // 授权状态
    var authorizationStatus: PHAuthorizationStatus = .notDetermined

    // 照片缓存
    private let imageManager = PHCachingImageManager()
    private var cachedAssets: [String: PHAsset] = [:]

    private init() {
        checkAuthorization()
    }

    // MARK: - Authorization

    func checkAuthorization() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    // MARK: - Fetch Photos

    /// 获取最近的照片
    func fetchRecentPhotos(limit: Int = 100) async -> [PhotoAsset] {
        guard isAuthorized else { return [] }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = limit
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let results = PHAsset.fetchAssets(with: options)

        var assets: [PhotoAsset] = []
        results.enumerateObjects { asset, _, _ in
            let photoAsset = PhotoAsset(asset: asset)
            assets.append(photoAsset)
            self.cachedAssets[asset.localIdentifier] = asset
        }

        return assets
    }

    /// 获取指定时间范围内的照片
    func fetchPhotos(from startDate: Date, to endDate: Date) async -> [PhotoAsset] {
        guard isAuthorized else { return [] }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue),
            NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", startDate as NSDate, endDate as NSDate)
        ])

        let results = PHAsset.fetchAssets(with: options)

        var assets: [PhotoAsset] = []
        results.enumerateObjects { asset, _, _ in
            let photoAsset = PhotoAsset(asset: asset)
            assets.append(photoAsset)
            self.cachedAssets[asset.localIdentifier] = asset
        }

        return assets
    }

    /// 获取指定位置附近的照片
    func fetchPhotos(near location: CLLocation, radius: Double = 100) async -> [PhotoAsset] {
        guard isAuthorized else { return [] }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let results = PHAsset.fetchAssets(with: options)

        var assets: [PhotoAsset] = []
        results.enumerateObjects { asset, _, _ in
            if let assetLocation = asset.location,
               assetLocation.distance(from: location) <= radius {
                let photoAsset = PhotoAsset(asset: asset)
                assets.append(photoAsset)
                self.cachedAssets[asset.localIdentifier] = asset
            }
        }

        return assets
    }

    // MARK: - Load Thumbnails

    /// 批量加载缩略图
    func loadThumbnails(for assets: [PhotoAsset], size: CGSize) async {
        await withTaskGroup(of: Void.self) { group in
            for asset in assets {
                group.addTask {
                    let thumbnail = await asset.asset.thumbnail(size: size)
                    await MainActor.run {
                        asset.thumbnail = thumbnail
                    }
                }
            }
        }
    }

    /// 预缓存资源
    func startCaching(assets: [PhotoAsset], targetSize: CGSize) {
        let phAssets = assets.map { $0.asset }
        imageManager.startCachingImages(
            for: phAssets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    func stopCaching(assets: [PhotoAsset], targetSize: CGSize) {
        let phAssets = assets.map { $0.asset }
        imageManager.stopCachingImages(
            for: phAssets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    // MARK: - Delete Photos

    /// 删除照片
    func deletePhotos(_ assets: [PhotoAsset]) async throws {
        let phAssets = assets.map { $0.asset }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(phAssets as NSFastEnumeration)
        }

        // 清除缓存
        for asset in assets {
            cachedAssets.removeValue(forKey: asset.id)
        }
    }

    /// 计算照片总大小
    func calculateTotalSize(for assets: [PhotoAsset]) -> Int64 {
        var totalSize: Int64 = 0

        for asset in assets {
            let resources = PHAssetResource.assetResources(for: asset.asset)
            if let resource = resources.first,
               let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += fileSize
            }
        }

        return totalSize
    }

    func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
