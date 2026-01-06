import Flutter
import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        // Create Flutter window for this scene
        window = UIWindow(windowScene: windowScene)

        // Get the Flutter view controller from the app delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let flutterViewController = appDelegate.flutterViewController {
            window?.rootViewController = flutterViewController
        } else {
            // Create new Flutter view controller if not available
            let flutterViewController = FlutterViewController(
                engine: appDelegate.flutterEngine,
                nibName: nil,
                bundle: nil
            )
            window?.rootViewController = flutterViewController
            appDelegate.flutterViewController = flutterViewController
        }

        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is being released by the system
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background
    }
}
