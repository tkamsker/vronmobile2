import Flutter
import UIKit

/// Flutter MethodChannel plugin for iOS USDZ combination
/// Feature 018: Combined Scan to NavMesh Workflow
/// Bridges Flutter Dart code to native iOS USDZCombiner implementation
class USDZCombinerPlugin: NSObject, FlutterPlugin {

    /// Channel name for Flutter communication
    private static let channelName = "com.vron.usdz_combiner"

    /// Instance of the native USDZ combiner
    private let combiner = USDZCombiner()

    /// Register plugin with Flutter engine
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = USDZCombinerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    /// Handle method calls from Flutter
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "combineScans":
            handleCombineScans(call, result: result)

        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    /// Handle combineScans method call from Flutter
    /// Expected arguments:
    /// {
    ///   "paths": ["path1.usdz", "path2.usdz", ...],
    ///   "transforms": [
    ///     {"positionX": 0.0, "positionY": 0.0, "rotation": 0.0, "scale": 1.0},
    ///     {"positionX": 150.0, "positionY": 0.0, "rotation": 90.0, "scale": 1.0},
    ///     ...
    ///   ],
    ///   "outputPath": "/path/to/combined_scan.usdz"
    /// }
    private func handleCombineScans(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Arguments must be a dictionary",
                details: nil
            ))
            return
        }

        // Extract paths
        guard let paths = args["paths"] as? [String], !paths.isEmpty else {
            result(FlutterError(
                code: "INVALID_PATHS",
                message: "paths must be a non-empty array of strings",
                details: nil
            ))
            return
        }

        // Extract transforms
        guard let transformsData = args["transforms"] as? [[String: Any]],
              !transformsData.isEmpty else {
            result(FlutterError(
                code: "INVALID_TRANSFORMS",
                message: "transforms must be a non-empty array of dictionaries",
                details: nil
            ))
            return
        }

        // Extract output path
        guard let outputPath = args["outputPath"] as? String, !outputPath.isEmpty else {
            result(FlutterError(
                code: "INVALID_OUTPUT_PATH",
                message: "outputPath must be a non-empty string",
                details: nil
            ))
            return
        }

        // Validate counts match
        guard paths.count == transformsData.count else {
            result(FlutterError(
                code: "COUNT_MISMATCH",
                message: "Number of paths (\(paths.count)) must match number of transforms (\(transformsData.count))",
                details: nil
            ))
            return
        }

        // Parse transforms
        var transforms: [ScanTransform] = []
        for (index, transformData) in transformsData.enumerated() {
            guard let transform = parseTransform(transformData) else {
                result(FlutterError(
                    code: "INVALID_TRANSFORM",
                    message: "Invalid transform at index \(index)",
                    details: transformData
                ))
                return
            }
            transforms.append(transform)
        }

        // Perform combination on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let combineResult = self.combiner.combineScans(
                scanPaths: paths,
                transforms: transforms,
                outputPath: outputPath
            )

            // Return result on main thread
            DispatchQueue.main.async {
                switch combineResult {
                case .success(let path):
                    result(path)

                case .failure(let error):
                    result(FlutterError(
                        code: "COMBINE_FAILED",
                        message: error,
                        details: nil
                    ))
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Parse transform dictionary from Flutter into ScanTransform struct
    private func parseTransform(_ data: [String: Any]) -> ScanTransform? {
        guard let positionX = data["positionX"] as? Double,
              let positionY = data["positionY"] as? Double,
              let rotation = data["rotation"] as? Double,
              let scale = data["scale"] as? Double else {
            return nil
        }

        return ScanTransform(
            positionX: Float(positionX),
            positionY: Float(positionY),
            rotation: Float(rotation),
            scale: Float(scale)
        )
    }
}
