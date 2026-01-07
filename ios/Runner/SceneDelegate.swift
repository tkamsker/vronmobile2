import Flutter
import UIKit

@available(iOS 13.0, *)
@objc(SceneDelegate)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Force print to console (NSLog is more reliable than print in some cases)
        NSLog("📱 [SceneDelegate] willConnectTo session: attaching Flutter rootViewController")
        print("📱 [SceneDelegate] willConnectTo session: attaching Flutter rootViewController")
        
        guard let windowScene = scene as? UIWindowScene else {
            NSLog("❌ [SceneDelegate] Failed to cast UIScene to UIWindowScene")
            print("❌ [SceneDelegate] Failed to cast UIScene to UIWindowScene")
            return
        }

        // Get the Flutter app delegate
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            NSLog("❌ [SceneDelegate] Failed to get AppDelegate")
            print("❌ [SceneDelegate] Failed to get AppDelegate")
            return
        }

        // Ensure Flutter engine is running
        if !appDelegate.flutterEngine.run() {
            NSLog("❌ [SceneDelegate] Flutter engine failed to run")
            print("❌ [SceneDelegate] Flutter engine failed to run")
        }

        // Create Flutter window for this scene
        window = UIWindow(windowScene: windowScene)

        // Get or create Flutter view controller
        let flutterViewController: FlutterViewController
        if let existingVC = appDelegate.flutterViewController {
            flutterViewController = existingVC
            NSLog("✅ [SceneDelegate] Reusing existing FlutterViewController")
            print("✅ [SceneDelegate] Reusing existing FlutterViewController")
        } else {
            flutterViewController = FlutterViewController(
                engine: appDelegate.flutterEngine,
                nibName: nil,
                bundle: nil
            )
            appDelegate.flutterViewController = flutterViewController
            NSLog("✅ [SceneDelegate] Created new FlutterViewController")
            print("✅ [SceneDelegate] Created new FlutterViewController")
        }

        // Set root view controller
        window?.rootViewController = flutterViewController
        
        // Make window key and visible
        window?.makeKeyAndVisible()
        
        NSLog("✅ [SceneDelegate] Window made key and visible, rootViewController set")
        print("✅ [SceneDelegate] Window made key and visible, rootViewController set")
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
