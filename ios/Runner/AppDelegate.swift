import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup method channel for USDZ→GLB conversion
    // Note: On-device conversion is not supported due to iOS framework limitations.
    // ModelIO does not support GLB export format.
    // Future implementation will use server-side conversion.
    let controller = window?.rootViewController as! FlutterViewController
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
