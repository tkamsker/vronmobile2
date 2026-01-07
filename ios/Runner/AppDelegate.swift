import Flutter
import UIKit
import SceneKit
import UniformTypeIdentifiers

// MARK: - Feature 018: USDZ Combiner

/// Transform data for positioning a scan in the combined scene
struct ScanTransform {
    let positionX: Float
    let positionY: Float
    let rotation: Float  // degrees
    let scale: Float

    /// Convert canvas 2D position to 3D scene position
    var scenePosition: SCNVector3 {
        let scaleFactor: Float = 0.01
        return SCNVector3(positionX * scaleFactor, 0, positionY * scaleFactor)
    }

    /// Convert rotation degrees to radians for SceneKit
    var rotationRadians: Float {
        return rotation * .pi / 180.0
    }
}

/// Result of USDZ combination operation
enum CombineResult {
    case success(path: String)
    case failure(error: CombineError)
}

/// Combine error with FlutterError mapping
struct CombineError {
    let code: String
    let message: String
    let details: String?
}

/// iOS native implementation for combining multiple USDZ files
class USDZCombiner {
    func combineScans(
        scanPaths: [String],
        transforms: [ScanTransform],
        outputPath: String
    ) -> CombineResult {
        guard scanPaths.count >= 2 else {
            return .failure(error: CombineError(
                code: "INVALID_ARGUMENTS",
                message: "Need at least 2 scans to combine",
                details: nil
            ))
        }

        guard scanPaths.count == transforms.count else {
            return .failure(error: CombineError(
                code: "INVALID_ARGUMENTS",
                message: "Scan paths and transforms count mismatch",
                details: "\(scanPaths.count) paths vs \(transforms.count) transforms"
            ))
        }

        let combinedScene = SCNScene()
        let rootNode = combinedScene.rootNode

        for (index, scanPath) in scanPaths.enumerated() {
            let transform = transforms[index]

            guard let scanScene = loadUSDZ(path: scanPath) else {
                return .failure(error: CombineError(
                    code: "LOAD_FAILED",
                    message: "Failed to load USDZ at \(scanPath)",
                    details: nil
                ))
            }

            let scanContainerNode = SCNNode()
            scanContainerNode.name = "scan_\(index)"

            for childNode in scanScene.rootNode.childNodes {
                let clonedNode = childNode.clone()
                scanContainerNode.addChildNode(clonedNode)
            }

            applyTransform(to: scanContainerNode, transform: transform)
            rootNode.addChildNode(scanContainerNode)
        }

        do {
            try exportUSDZ(scene: combinedScene, toPath: outputPath)
            return .success(path: outputPath)
        } catch {
            return .failure(error: CombineError(
                code: "EXPORT_FAILED",
                message: "Failed to export USDZ",
                details: error.localizedDescription
            ))
        }
    }

    private func loadUSDZ(path: String) -> SCNScene? {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        return try? SCNScene(url: url, options: [
            .checkConsistency: true,
            .flattenScene: false,
            .createNormalsIfAbsent: true
        ])
    }

    private func applyTransform(to node: SCNNode, transform: ScanTransform) {
        node.position = transform.scenePosition
        node.eulerAngles = SCNVector3(0, transform.rotationRadians, 0)
        node.scale = SCNVector3(transform.scale, transform.scale, transform.scale)
    }

    private func exportUSDZ(scene: SCNScene, toPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }
        try scene.write(to: url, options: nil, delegate: nil, progressHandler: nil)
    }
}

// MARK: - AppDelegate

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Flutter engine shared across scenes
  lazy var flutterEngine = FlutterEngine(name: "vron_engine")

  // Flutter view controller (scene-managed)
  var flutterViewController: FlutterViewController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("📱 [AppDelegate] didFinishLaunchingWithOptions - initializing Flutter engine")
    print("📱 [AppDelegate] didFinishLaunchingWithOptions - initializing Flutter engine")
    
    // Initialize Flutter engine (returns false if already running)
    let engineStarted = flutterEngine.run()
    if engineStarted {
      NSLog("✅ [AppDelegate] Flutter engine started")
      print("✅ [AppDelegate] Flutter engine started")
    } else {
      NSLog("⚠️ [AppDelegate] Flutter engine was already running")
      print("⚠️ [AppDelegate] Flutter engine was already running")
    }
    
    GeneratedPluginRegistrant.register(with: self)

    // Setup method channels
    setupMethodChannels()

    // Call super - FlutterAppDelegate will handle window creation automatically
    // (UIScene is temporarily disabled in Info.plist)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    NSLog("✅ [AppDelegate] didFinishLaunchingWithOptions completed")
    print("✅ [AppDelegate] didFinishLaunchingWithOptions completed")
    
    return result
  }

  // MARK: - UIScene Lifecycle Support (TEMPORARILY DISABLED)
  
  // UIScene methods commented out - using traditional AppDelegate window management
  /*
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(
      name: "Default Configuration",
      sessionRole: connectingSceneSession.role
    )
  }
  */

  // MARK: - Method Channel Setup

  private func setupMethodChannels() {
    // Get or create Flutter view controller for method channels
    let controller = getFlutterViewController()

    // Setup USDZ Combiner method channel for Feature 018: Combined Scan to NavMesh
    let combinerChannel = FlutterMethodChannel(
      name: "com.vron.usdz_combiner",
      binaryMessenger: controller.binaryMessenger
    )

    let combiner = USDZCombiner()

    combinerChannel.setMethodCallHandler { (call, result) in
      if call.method == "combineScans" {
        guard let args = call.arguments as? [String: Any],
              let paths = args["paths"] as? [String],
              let transformsData = args["transforms"] as? [[String: Any]],
              let outputPath = args["outputPath"] as? String else {
          result(FlutterError(
            code: "INVALID_ARGUMENTS",
            message: "Missing required arguments: paths, transforms, or outputPath",
            details: nil
          ))
          return
        }

        // Parse transforms
        let transforms = transformsData.map { data -> ScanTransform in
          ScanTransform(
            positionX: (data["positionX"] as? NSNumber)?.floatValue ?? 0.0,
            positionY: (data["positionY"] as? NSNumber)?.floatValue ?? 0.0,
            rotation: (data["rotation"] as? NSNumber)?.floatValue ?? 0.0,
            scale: (data["scale"] as? NSNumber)?.floatValue ?? 1.0
          )
        }

        // Perform combination in background
        DispatchQueue.global(qos: .userInitiated).async {
          let combineResult = combiner.combineScans(
            scanPaths: paths,
            transforms: transforms,
            outputPath: outputPath
          )

          DispatchQueue.main.async {
            switch combineResult {
            case .success(let path):
              result(path)
            case .failure(let error):
              result(FlutterError(
                code: error.code,
                message: error.message,
                details: error.details
              ))
            }
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Setup method channel for USDZ→GLB conversion
    // Note: On-device conversion is not supported due to iOS framework limitations.
    // ModelIO does not support GLB export format.
    // Future implementation will use server-side conversion.
    let conversionChannel = FlutterMethodChannel(
      name: "com.vron.mobile/usdz_converter",
      binaryMessenger: controller.binaryMessenger
    )

    conversionChannel.setMethodCallHandler { (call, result) in
      if call.method == "convertUsdzToGlb" {
        // Return not implemented error
        result(FlutterError(
          code: "NOT_IMPLEMENTED",
          message: "On-device USDZ→GLB conversion is not supported. Use server-side conversion or view USDZ directly in QuickLook.",
          details: "iOS ModelIO framework does not support GLB export format. Requires USD SDK integration (4-8 week project) or server-side conversion."
        ))
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Setup method channel for room outline extraction
    let outlineChannel = FlutterMethodChannel(
      name: "com.vron.mobile/outline_extractor",
      binaryMessenger: controller.binaryMessenger
    )

    let extractor = RoomOutlineExtractor()

    outlineChannel.setMethodCallHandler { (call, result) in
      if call.method == "extractOutline" {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
          result(FlutterError(
            code: "INVALID_ARGUMENTS",
            message: "Missing filePath argument",
            details: nil
          ))
          return
        }

        let fileUrl = URL(fileURLWithPath: filePath)

        // Extract outline in background to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
          if let outline = extractor.extractOutline(from: fileUrl) {
            DispatchQueue.main.async {
              result(outline)
            }
          } else {
            DispatchQueue.main.async {
              result(FlutterError(
                code: "EXTRACTION_FAILED",
                message: "Failed to extract outline from \(filePath)",
                details: "Could not load 3D model or extract vertices"
              ))
            }
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Helper Methods

  private func getFlutterViewController() -> FlutterViewController {
    if let existingController = flutterViewController {
      return existingController
    }

    // Create new Flutter view controller
    let controller = FlutterViewController(
      engine: flutterEngine,
      nibName: nil,
      bundle: nil
    )
    flutterViewController = controller
    return controller
  }
}
