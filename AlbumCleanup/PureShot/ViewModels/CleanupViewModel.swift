import SwiftUI
import Photos

// ═══════════════════════════════════════════════════════════════
//  CleanupViewModel - 清理交互状态
//  管理纵向布局、选择、删除动画
// ═══════════════════════════════════════════════════════════════

@MainActor
@Observable
final class CleanupViewModel {

    // MARK: - State

    enum CleanupState {
        case viewing        // 查看中
        case confirming     // 确认删除中
        case deleting       // 删除动画中
        case completed      // 完成
    }

    var state: CleanupState = .viewing

    // 当前处理的照片组
    var photoGroup: PhotoGroup?

    // 当前焦点照片索引 (纵向布局中心)
    var focusIndex: Int = 0

    // 动画状态
    var showActionBar: Bool = false
    var dissolvingPhotos: Set<String> = []
    var showCompletionToast: Bool = false

    // 完成信息
    var deletedCount: Int = 0
    var freedSpace: Int64 = 0

    // MARK: - Computed Properties

    var photos: [PhotoAsset] {
        photoGroup?.photos ?? []
    }

    var focusPhoto: PhotoAsset? {
        guard focusIndex < photos.count else { return nil }
        return photos[focusIndex]
    }

    var keepCount: Int {
        photoGroup?.keepCount ?? 0
    }

    var deleteCount: Int {
        photoGroup?.deleteCount ?? 0
    }

    var canConfirm: Bool {
        deleteCount > 0
    }

    var formattedFreedSpace: String {
        ByteCountFormatter.string(fromByteCount: freedSpace, countStyle: .file)
    }

    // MARK: - Setup

    func setup(with group: PhotoGroup) {
        self.photoGroup = group
        self.focusIndex = group.bestPhotoIndex
        self.state = .viewing
        self.dissolvingPhotos.removeAll()
        self.showCompletionToast = false

        // 延迟显示操作栏
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showActionBar = true
            }
            HapticManager.shared.softTap()
        }
    }

    // MARK: - Focus Navigation

    /// 移动焦点到指定索引
    func moveFocus(to index: Int) {
        guard index >= 0 && index < photos.count else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            focusIndex = index
        }

        HapticManager.shared.selectionChanged()
    }

    /// 移动焦点到上一张
    func focusPrevious() {
        moveFocus(to: focusIndex - 1)
    }

    /// 移动焦点到下一张
    func focusNext() {
        moveFocus(to: focusIndex + 1)
    }

    // MARK: - Selection

    /// 切换照片选中状态
    func toggleSelection(for photo: PhotoAsset) {
        guard let group = photoGroup else { return }

        // 最佳照片不能取消选中
        if photo.isBestInGroup { return }

        group.toggleSelection(for: photo)

        // 触觉反馈
        if photo.isSelected {
            HapticManager.shared.selectionRipple()
        } else {
            HapticManager.shared.lightTap()
        }
    }

    /// 将当前焦点照片设为最佳
    func setFocusAsBest() {
        guard let group = photoGroup else { return }

        group.setBestPhoto(at: focusIndex)
        HapticManager.shared.mediumTap()
    }

    // MARK: - Deletion

    /// 确认删除
    func confirmDelete() async {
        guard let group = photoGroup, canConfirm else { return }

        state = .confirming

        // 隐藏操作栏
        withAnimation {
            showActionBar = false
        }

        // 开始融化动画
        state = .deleting
        let photosToDelete = group.photosToDelete

        // 触觉反馈
        HapticManager.shared.liquidDissolve()

        // 依次标记融化
        for (index, photo) in photosToDelete.enumerated() {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms 间隔

            withAnimation(.easeOut(duration: 0.6)) {
                photo.animationState = .dissolving
                dissolvingPhotos.insert(photo.id)
            }
        }

        // 等待动画完成
        try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s

        // 执行真实删除
        deletedCount = photosToDelete.count
        freedSpace = group.estimatedSpaceSaved

        do {
            try await PhotoLibraryService.shared.deletePhotos(photosToDelete)

            // 更新照片列表
            for photo in photosToDelete {
                photo.animationState = .dissolved
            }

            // 标记完成
            state = .completed

            // 显示完成提示
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showCompletionToast = true
            }

            HapticManager.shared.dropletBounce()

        } catch {
            print("Delete failed: \(error)")
            state = .viewing
            showActionBar = true
        }
    }

    /// 取消并返回
    func cancel() {
        withAnimation {
            showActionBar = false
        }
        state = .viewing
    }

    // MARK: - Layout Helpers

    /// 获取照片在纵向布局中的位置偏移
    func verticalOffset(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let distance = index - focusIndex
        let baseOffset = CGFloat(distance) * 100 // 基础间距
        return baseOffset
    }

    /// 获取照片在纵向布局中的缩放比例
    func scale(for index: Int) -> CGFloat {
        let distance = abs(index - focusIndex)
        return Constants.PhotoScale.scale(for: distance)
    }

    /// 获取照片在纵向布局中的透明度
    func opacity(for index: Int) -> Double {
        let distance = abs(index - focusIndex)
        return Constants.PhotoScale.opacity(for: distance)
    }

    /// 获取照片在纵向布局中的模糊度
    func blur(for index: Int) -> CGFloat {
        let distance = abs(index - focusIndex)
        return Constants.PhotoScale.blur(for: distance)
    }
}
