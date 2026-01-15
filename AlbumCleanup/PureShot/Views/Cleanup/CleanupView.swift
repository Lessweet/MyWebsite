import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  CleanupView - 清理交互主视图
//  纵向空间感布局，支持选择、融合删除
// ═══════════════════════════════════════════════════════════════

struct CleanupView: View {
    let group: PhotoGroup
    let onComplete: () -> Void

    @State private var viewModel = CleanupViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 背景
            Color.psBackgroundAdaptive
                .ignoresSafeArea()

            // 照片纵向布局
            photoVerticalLayout

            // 底部操作栏
            if viewModel.showActionBar {
                VStack {
                    Spacer()
                    LiquidGlassActionBar(
                        keepCount: viewModel.keepCount,
                        deleteCount: viewModel.deleteCount,
                        onConfirm: {
                            Task {
                                await viewModel.confirmDelete()
                            }
                        }
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // 完成提示
            if viewModel.showCompletionToast {
                CompletionToast(
                    deletedCount: viewModel.deletedCount,
                    freedSpace: viewModel.formattedFreedSpace,
                    onDismiss: {
                        onComplete()
                        dismiss()
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.psTextPrimaryAdaptive)
                }
                .opacity(viewModel.state == .completed ? 0 : 1)
            }

            ToolbarItem(placement: .principal) {
                Text("\(group.photos.count) 张相似照片")
                    .font(.headline)
                    .foregroundStyle(Color.psTextPrimaryAdaptive)
            }
        }
        .onAppear {
            viewModel.setup(with: group)
        }
    }

    // MARK: - Photo Vertical Layout

    private var photoVerticalLayout: some View {
        GeometryReader { geometry in
            let centerY = geometry.size.height / 2 - 50 // 偏上一点，为底部操作栏留空间

            ZStack {
                ForEach(Array(viewModel.photos.enumerated()), id: \.element.id) { index, photo in
                    let distance = index - viewModel.focusIndex
                    let scale = viewModel.scale(for: index)
                    let opacity = viewModel.opacity(for: index)
                    let blur = viewModel.blur(for: index)
                    let yOffset = calculateYOffset(distance: distance, geometry: geometry)

                    // 检查是否正在融化
                    let isDissolving = viewModel.dissolvingPhotos.contains(photo.id)

                    Group {
                        if isDissolving {
                            // 融化中的照片
                            DissolvingPhotoView(
                                photo: photo,
                                size: sizeForScale(scale, maxWidth: geometry.size.width - 40)
                            )
                        } else if photo.animationState != .dissolved {
                            // 正常照片
                            photoCard(
                                photo: photo,
                                index: index,
                                scale: scale,
                                maxWidth: geometry.size.width - 40
                            )
                            .blur(radius: blur)
                            .opacity(opacity)
                        }
                    }
                    .offset(y: yOffset)
                    .zIndex(index == viewModel.focusIndex ? 100 : Double(50 - abs(distance)))
                    .animation(.bounceSettle, value: viewModel.focusIndex)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .position(x: geometry.size.width / 2, y: centerY)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        handleSwipe(value: value)
                    }
            )
        }
    }

    // MARK: - Photo Card

    private func photoCard(
        photo: PhotoAsset,
        index: Int,
        scale: CGFloat,
        maxWidth: CGFloat
    ) -> some View {
        let size = sizeForScale(scale, maxWidth: maxWidth)
        let isFocus = index == viewModel.focusIndex

        return ZStack {
            // 照片图像
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: isFocus ? 20 : 16, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: isFocus ? 20 : 16, style: .continuous)
                    .fill(Color.psTextSecondaryAdaptive.opacity(0.2))
                    .frame(width: size.width, height: size.height)
            }

            // 选中边框
            if photo.isSelected || photo.isBestInGroup {
                RoundedRectangle(cornerRadius: isFocus ? 20 : 16, style: .continuous)
                    .strokeBorder(Color.psAccent, lineWidth: isFocus ? 4 : 3)
                    .frame(width: size.width, height: size.height)
                    .shadow(color: Color.psAccent.opacity(0.4), radius: isFocus ? 12 : 8)
            }

            // 选中标记
            if photo.isSelected || photo.isBestInGroup {
                VStack {
                    HStack {
                        Spacer()
                        CheckMark(isBest: photo.isBestInGroup)
                            .scaleEffect(isFocus ? 1.2 : 1.0)
                            .padding(isFocus ? 12 : 8)
                    }
                    Spacer()
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if index == viewModel.focusIndex {
                // 焦点照片：切换选中
                viewModel.toggleSelection(for: photo)
            } else {
                // 非焦点照片：移动焦点
                viewModel.moveFocus(to: index)
            }
        }
        .onLongPressGesture {
            // 长按：切换选中
            viewModel.toggleSelection(for: photo)
        }
    }

    // MARK: - Helpers

    private func calculateYOffset(distance: Int, geometry: GeometryProxy) -> CGFloat {
        let baseSpacing: CGFloat = 90
        let sign = distance >= 0 ? 1.0 : -1.0

        // 使用递减间距
        var offset: CGFloat = 0
        for i in 0..<abs(distance) {
            let spacingMultiplier = max(0.6, 1.0 - Double(i) * 0.1)
            offset += baseSpacing * spacingMultiplier
        }

        return sign * offset
    }

    private func sizeForScale(_ scale: CGFloat, maxWidth: CGFloat) -> CGSize {
        let width = maxWidth * scale
        let height = width * 0.75 // 4:3 比例
        return CGSize(width: width, height: height)
    }

    private func handleSwipe(value: DragGesture.Value) {
        let threshold: CGFloat = 50

        if value.translation.height > threshold {
            // 向下滑：显示上一张
            viewModel.focusPrevious()
        } else if value.translation.height < -threshold {
            // 向上滑：显示下一张
            viewModel.focusNext()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CleanupView(
            group: PhotoGroup(photos: []),
            onComplete: {}
        )
    }
}
