//
//  SceneDelegate.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        _ = CoreDataManager.shared
        
        do {
            try RetailLoaderManager.shared.preloadDataIfNeeded()
        } catch {
            fatalError("Ошибка при загрузке данных \(error)")
        }
        
        attemptTimeZoneMigration()
        
        // Конфигурация ProgressHUD
        Loader.configure()
        print("👀 Тема из UserDefaults:", ThemeManager.current.rawValue)
        let window = UIWindow(windowScene: windowScene)
        let tabBarController = MainTabBarController()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        ThemeManager.applyCurrentTheme()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    private func attemptTimeZoneMigration() {
        do {
            let context = CoreDataManager.shared.context
            let migrationManager = TimeZoneMigrationManager(context: context)
            try migrationManager.runMigrationIfNeeded()
        } catch {
            // 1. Логируем
            let errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            print("❌ Ошибка миграции дат: \(errorMessage)")
            
            // 2. При желании, показываем алерт пользователю
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Ошибка миграции",
                                              message: errorMessage,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                
                // Если self.window?.rootViewController есть, показываем на нем
                self.window?.rootViewController?.present(alert, animated: true)
            }
        }
    }
}
