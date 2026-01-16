import SwiftUI
import Photos

// ═══════════════════════════════════════════════════════════════
//  PhotoThumbnail - 照片缩略图组件
//  支持选中状态、液态透镜边缘、融化动画
// ═══════════════════════════════════════════════════════════════

struct PhotoThumbnail: View {
    let photo: PhotoAsset
    var size: CGSize = CGSize(width: 100, height: 100)
    var cornerRadius: CGFloat = Constants.Layout.photoCornerRadius

    @State private var rippleProgress: CGFloat = 0
    @State private var showRipple = false

    var body: some View {
        ZStack {
            // 照片图像
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                // 占位符
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.psTextSecondaryAdaptive.opacity(0.2))
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(Color.psTextSecondaryAdaptive.opacity(0.5))
                    }
            }

            // 选中状态边框
            if photo.isSelected || photo.isBestInGroup {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.psAccent, lineWidth: 3)
                    .frame(width: size.width, height: size.height)
                    .shadow(color: Color.psAccent.opacity(0.5), radius: 8)
            }

            // 选中标记
            if photo.isSelected || photo.isBestInGroup {
                VStack {
                    HStack {
                        Spacer()
                        CheckMark(isBest: photo.isBestInGroup)
                            .padding(8)
                    }
                    Spacer()
                }
            }

            // 涟漪效果
            if showRipple {
                Circle()
                    .stroke(Color.psAccent.opacity(0.6 - rippleProgress * 0.6), lineWidth: 2)
                    .scaleEffect(0.3 + rippleProgress * 1.5)
                    .frame(width: size.width, height: size.height)
            }
        }
    }

    /// 播放选中涟漪动画
    func playSelectionRipple() {
        showRipple = true
        rippleProgress = 0

        withAnimation(.easeOut(duration: 0.4)) {
            rippleProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showRipple = false
        }
    }
}

// MARK: - Check Mark

struct CheckMark: View {
    let isBest: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.psAccent)
                .frame(width: 24, height: 24)

            if isBest {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.psTextPrimaryAdaptive)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.psTextPrimaryAdaptive)
            }
        }
        .shadow(color: Color.psAccent.opacity(0.5), radius: 4)
    }
}

// MARK: - Large Photo View (用于纵向布局中心)

struct LargePhotoView: View {
    let photo: PhotoAsset
    var maxWidth: CGFloat = 280

    @State private var breathingScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .scaleEffect(breathingScale)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.psTextSecondaryAdaptive.opacity(0.2))
                    .frame(width: maxWidth, height: maxWidth)
            }

            // 选中边框
            if photo.isSelected || photo.isBestInGroup {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.psAccent, lineWidth: 4)
                    .frame(maxWidth: maxWidth)
                    .aspectRatio(photo.aspectRatio, contentMode: .fit)
                    .shadow(color: Color.psAccent.opacity(0.4), radius: 12)
            }

            // 选中标记
            if photo.isSelected || photo.isBestInGroup {
                VStack {
                    HStack {
                        Spacer()
                        CheckMark(isBest: photo.isBestInGroup)
                            .scaleEffect(1.2)
                            .padding(12)
                    }
                    Spacer()
                }
                .frame(maxWidth: maxWidth)
                .aspectRatio(photo.aspectRatio, contentMode: .fit)
            }
        }
        .onAppear {
            // 微弱呼吸动画
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                breathingScale = 1.005
            }
        }
    }
}

// MARK: - Dissolving Photo View (融化动画)

struct DissolvingPhotoView: View {
    let photo: PhotoAsset
    var size: CGSize

    @State private var dissolveProgress: CGFloat = 0
    @State private var droplets: [Droplet] = []

    struct Droplet: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var delay: Double
    }

    var body: some View {
        ZStack {
            // 原图 (逐渐消失)
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.photoCornerRadius, style: .continuous))
                    .opacity(1 - dissolveProgress)
                    .blur(radius: dissolveProgress * 4)
                    .scaleEffect(1 - dissolveProgress * 0.3)
            }

            // 液滴
            ForEach(droplets) { droplet in
                Circle()
                    .fill(Color.psTextSecondaryAdaptive.opacity(0.6))
                    .frame(width: droplet.size, height: droplet.size)
                    .offset(x: droplet.x, y: droplet.y + dissolveProgress * 100)
                    .opacity(Double(max(0.0, 1.0 - dissolveProgress * 1.5)))
                    .blur(radius: dissolveProgress * 2)
            }
        }
        .onAppear {
            startDissolve()
        }
    }

    private func startDissolve() {
        // 生成随机液滴
        for _ in 0..<8 {
            let droplet = Droplet(
                x: CGFloat.random(in: -size.width/2...size.width/2),
                y: CGFloat.random(in: -size.height/4...size.height/4),
                size: CGFloat.random(in: 4...12),
                delay: Double.random(in: 0...0.2)
            )
            droplets.append(droplet)
        }

        // 开始融化
        withAnimation(.easeOut(duration: 0.6)) {
            dissolveProgress = 1
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PhotoThumbnail(
            photo: PhotoAsset(asset: PHAsset()),
            size: CGSize(width: 100, height: 100)
        )

        LargePhotoView(
            photo: PhotoAsset(asset: PHAsset()),
            maxWidth: 200
        )
    }
    .padding()
    .background(Color.psBackgroundAdaptive)
}
