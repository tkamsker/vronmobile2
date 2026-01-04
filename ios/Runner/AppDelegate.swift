import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    // Register USDZ Combiner Plugin for Feature 018: Combined Scan to NavMesh
    let registrar = self.registrar(forPlugin: "USDZCombinerPlugin")!
    USDZCombinerPlugin.register(with: registrar)

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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
