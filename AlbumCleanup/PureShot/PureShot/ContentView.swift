//
//  ContentView.swift
//  PureShot
//
//  Created by chentongrong on 2026/1/13.
//

import SwiftUI

// ═══════════════════════════════════════════════════════════════
//  ContentView - 根视图
//  管理应用的主导航和状态
// ═══════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct ContentView: View {
    @State private var isAuthorized = false
    @State private var showAuthorizationAlert = false

    var body: some View {
        ZStack {
            // 基础深色背景，防止任何闪白
            Color(hex: 0x0A0A0A)
                .ignoresSafeArea()

            Group {
                if isAuthorized {
                    HomeView()
                } else {
                    authorizationView
                }
            }
        }
        .onAppear {
            checkAuthorization()
        }
    }

    // MARK: - Authorization View

    private var authorizationView: some View {
        ZStack {
            // 深色背景
            Color(hex: 0x0A0A0A)
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
                        .foregroundStyle(Color(hex: 0xF5F5F5))

                    Text("智能相册清理")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: 0x8E8E93))
                }

                Spacer()

                // 授权说明
                VStack(spacing: 16) {
                    Text("需要访问您的照片")
                        .font(.headline)
                        .foregroundStyle(Color(hex: 0xF5F5F5))

                    Text("PureShot 需要访问您的照片库来\n识别和清理相似照片")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: 0x8E8E93))
                        .multilineTextAlignment(.center)
                }

                // 授权按钮 - 使用原生 Liquid Glass
                Button {
                    requestAuthorization()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)

                        Text("授权访问照片")
                            .font(.headline)
                    }
                    .foregroundStyle(Color(hex: 0xF5F5F5))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                }
                .glassEffect(
                    .regular.tint(Color.psAccent).interactive(),
                    in: Capsule()
                )
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
