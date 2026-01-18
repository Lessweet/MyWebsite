import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  View+ExpandingPhoto - 液态展开照片的 View 扩展
//  提供便捷的 modifier 让任何图片视图都能拥有展开能力
// ═══════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
extension View {
    /// 添加液态展开能力
    /// - Parameters:
    ///   - isPresented: 控制展开状态的绑定
    ///   - photo: 要展开显示的照片
    ///   - sourceFrame: 源视图的 frame（用于动画起点）
    func expandablePhoto(
        isPresented: Binding<Bool>,
        photo: UIImage?,
        sourceFrame: CGRect
    ) -> some View {
        self.modifier(
            ExpandablePhotoModifier(
                isPresented: isPresented,
                photo: photo,
                sourceFrame: sourceFrame
            )
        )
    }
}

// MARK: - Expandable Photo Modifier

@available(iOS 26.0, *)
struct ExpandablePhotoModifier: ViewModifier {
    @Binding var isPresented: Bool
    let photo: UIImage?
    let sourceFrame: CGRect

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                if let photo = photo {
                    ExpandingPhotoView(
                        photo: photo,
                        startFrame: sourceFrame,
                        onDismiss: {
                            isPresented = false
                        }
                    )
                    .background(ClearBackgroundView())
                }
            }
    }
}

// MARK: - Clear Background for FullScreenCover

struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = ClearBackgroundUIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private class ClearBackgroundUIView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            superview?.superview?.backgroundColor = .clear
        }
    }
}

// MARK: - Frame Preference Key

struct SourceFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Expandable Photo Container

/// 包装一个图片视图，自动追踪其 frame 并提供展开功能
@available(iOS 26.0, *)
struct ExpandablePhotoContainer<Content: View>: View {
    let photo: UIImage?
    @ViewBuilder let content: () -> Content

    @State private var isExpanded = false
    @State private var sourceFrame: CGRect = .zero

    var body: some View {
        content()
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: SourceFramePreferenceKey.self,
                        value: geo.frame(in: .global)
                    )
                }
            )
            .onPreferenceChange(SourceFramePreferenceKey.self) { frame in
                sourceFrame = frame
            }
            .onTapGesture {
                if photo != nil {
                    isExpanded = true
                }
            }
            .expandablePhoto(
                isPresented: $isExpanded,
                photo: photo,
                sourceFrame: sourceFrame
            )
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    VStack {
        ExpandablePhotoContainer(
            photo: UIImage(systemName: "photo.fill")
        ) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.3))
                .frame(width: 150, height: 200)
                .overlay {
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                }
        }

        Text("Tap to expand")
            .foregroundStyle(.secondary)
    }
}
