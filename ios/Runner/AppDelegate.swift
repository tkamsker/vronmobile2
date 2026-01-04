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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
