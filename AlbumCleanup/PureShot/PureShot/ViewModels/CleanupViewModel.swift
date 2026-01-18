import SwiftUI
import Photos

// ═══════════════════════════════════════════════════════════════
//  CleanupViewModel - 清理交互状态
//  管理纵向平铺布局、选择、删除动画
//  按照 README 规范：简化入场动画，统一照片尺寸
// ═══════════════════════════════════════════════════════════════

@MainActor
@Observable
final class CleanupViewModel {

    // MARK: - State

    enum CleanupState {
        case loading        // 加载中
        case viewing        // 查看中
        case confirming     // 确认删除中
        case deleting       // 删除动画中
        case completed      // 完成
    }

    var state: CleanupState = .loading

    // 当前处理的照片组
    var photoGroup: PhotoGroup?

    // 动画状态
    var showActionBar: Bool = false
    var dissolvingPhotos: Set<String> = []
    var showCompletionToast: Bool = false

    // 完成信息
    var deletedCount: Int = 0
    var freedSpace: Int64 = 0

    // MARK: - Computed Properties

    var photos: [PhotoAsset] {
        // 最佳照片排在第一位
        guard let photos = photoGroup?.photos else { return [] }
        return photos.sorted { $0.isBestInGroup && !$1.isBestInGroup }
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
        self.state = .loading
        self.dissolvingPhotos.removeAll()
        self.showCompletionToast = false
        self.showActionBar = false

        // 简化入场：直接显示
        Task {
            await runSimpleEntrance()
        }
    }

    // MARK: - Simple Entrance (简化入场)

    private func runSimpleEntrance() async {
        // 短暂延迟让视图准备好
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s

        // 直接进入查看状态
        withAnimation(.easeOut(duration: 0.3)) {
            state = .viewing
        }

        // 显示操作栏
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
        withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
            showActionBar = true
        }
        HapticManager.shared.softTap()
    }

    // MARK: - Selection

    /// 切换照片选中状态（包括最佳照片，再次点击可取消）
    func toggleSelection(for photo: PhotoAsset) {
        guard let group = photoGroup else { return }

        group.toggleSelection(for: photo)

        // 触觉反馈
        if photo.isSelected {
            HapticManager.shared.selectionRipple()
        } else {
            HapticManager.shared.lightTap()
        }
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
        for photo in photosToDelete {
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

    // MARK: - Execute Delete (被 CleanupView 内爆动画调用)

    /// 执行实际删除（动画由 CleanupView 处理）
    func executeDelete() async {
        guard let group = photoGroup else { return }

        let photosToDelete = group.photosToDelete

        // 记录删除信息
        deletedCount = photosToDelete.count
        freedSpace = group.estimatedSpaceSaved

        do {
            try await PhotoLibraryService.shared.deletePhotos(photosToDelete)

            // 更新照片状态
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
}
