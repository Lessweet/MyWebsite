//
//  PureShotApp.swift
//  PureShot
//
//  Created by chentongrong on 2026/1/13.
//

import SwiftUI

@main
@available(iOS 26.0, *)
struct PureShotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // 设置默认窗口背景为深色，避免启动时闪白
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // 强制深色模式启动
        }
    }

    private func configureAppearance() {
        // 设置导航栏背景透明
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    /// 深色背景色
    static let darkBackgroundColor = UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 设置所有窗口的背景色为深色
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.backgroundColor = Self.darkBackgroundColor }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// MARK: - Scene Delegate

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // 设置窗口背景为深色
        windowScene.windows.forEach { window in
            window.backgroundColor = AppDelegate.darkBackgroundColor
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        windowScene.windows.forEach { window in
            window.backgroundColor = AppDelegate.darkBackgroundColor
        }
    }
}
