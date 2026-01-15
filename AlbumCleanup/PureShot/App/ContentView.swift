import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  ContentView - 根视图
//  管理应用的主导航和状态
// ═══════════════════════════════════════════════════════════════

struct ContentView: View {
    @State private var isAuthorized = false
    @State private var showAuthorizationAlert = false

    var body: some View {
        Group {
            if isAuthorized {
                HomeView()
            } else {
                authorizationView
            }
        }
        .onAppear {
            checkAuthorization()
        }
    }

    // MARK: - Authorization View

    private var authorizationView: some View {
        ZStack {
            Color.psBackgroundAdaptive
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.psAccent.opacity(0.15))
                            .frame(width: 120, height: 120)

                        Image(systemName: "photo.stack")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.psAccent)
                    }

                    Text("PureShot")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.psTextPrimaryAdaptive)

                    Text("智能相册清理")
                        .font(.subheadline)
                        .foregroundStyle(Color.psTextSecondaryAdaptive)
                }

                Spacer()

                // 授权说明
                VStack(spacing: 16) {
                    Text("需要访问您的照片")
                        .font(.headline)
                        .foregroundStyle(Color.psTextPrimaryAdaptive)

                    Text("PureShot 需要访问您的照片库来\n识别和清理相似照片")
                        .font(.subheadline)
                        .foregroundStyle(Color.psTextSecondaryAdaptive)
                        .multilineTextAlignment(.center)
                }

                // 授权按钮
                Button {
                    requestAuthorization()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)

                        Text("授权访问照片")
                            .font(.headline)
                    }
                    .foregroundStyle(Color.psTextPrimaryAdaptive)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background {
                        Capsule()
                            .fill(Color.psAccent)
                            .shadow(color: Color.psAccent.opacity(0.4), radius: 12, x: 0, y: 4)
                    }
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, Constants.Layout.horizontalPadding)
        }
        .alert("需要照片权限", isPresented: $showAuthorizationAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在设置中允许 PureShot 访问您的照片库")
        }
    }

    // MARK: - Authorization

    private func checkAuthorization() {
        let service = PhotoLibraryService.shared
        isAuthorized = service.isAuthorized
    }

    private func requestAuthorization() {
        Task {
            let status = await PhotoLibraryService.shared.requestAuthorization()
            await MainActor.run {
                switch status {
                case .authorized, .limited:
                    isAuthorized = true
                case .denied, .restricted:
                    showAuthorizationAlert = true
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
