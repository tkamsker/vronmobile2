import 'dart:io';
import 'package:flutter_roomplan/flutter_roomplan.dart';

enum LidarSupport {
  supported, // Device has LiDAR and iOS 16.0+
  noLidar, // Device lacks LiDAR hardware
  oldIOS, // iOS version < 16.0
  notApplicable, // Android device
}

class LidarCapability {
  final LidarSupport support;
  final String deviceModel;
  final String osVersion;
  final bool isMultiRoomSupported; // iOS 17.0+ for multi-room merge
  final String?
  unsupportedReason; // Human-readable message for unsupported devices

  LidarCapability({
    required this.support,
    required this.deviceModel,
    required this.osVersion,
    required this.isMultiRoomSupported,
    this.unsupportedReason,
  });

  /// Factory: Detect capability at runtime
  static Future<LidarCapability> detect() async {
    print('🔍 [LIDAR] Starting capability detection...');

    if (Platform.isAndroid) {
      print('🔍 [LIDAR] Platform is Android - LiDAR not applicable');
      return LidarCapability(
        support: LidarSupport.notApplicable,
        deviceModel: await _getDeviceModel(),
        osVersion: await _getOSVersion(),
        isMultiRoomSupported: false,
        unsupportedReason:
            'LiDAR scanning is not available on Android devices. You can upload GLB files instead.',
      );
    }

    print('🔍 [LIDAR] Platform is iOS - checking LiDAR support...');
    // iOS: Check via flutter_roomplan
    final isSupported = await _checkIOSLidarSupport();
    final osVersion = await _getOSVersion();
    final deviceModel = await _getDeviceModel();
    final isMultiRoom = _isIOSVersionAtLeast(osVersion, '17.0');

    print('🔍 [LIDAR] Detection results:');
    print('  - Device: $deviceModel');
    print('  - OS Version: $osVersion');
    print('  - LiDAR Supported: $isSupported');
    print('  - Multi-room: $isMultiRoom');

    if (!isSupported) {
      print('❌ [LIDAR] Device does not support LiDAR');
      return LidarCapability(
        support: LidarSupport.noLidar,
        deviceModel: deviceModel,
        osVersion: osVersion,
        isMultiRoomSupported: false,
        unsupportedReason:
            'Your device does not have a LiDAR scanner. LiDAR is available on iPhone 12 Pro and newer Pro models.',
      );
    }

    if (!_isIOSVersionAtLeast(osVersion, '16.0')) {
      print('❌ [LIDAR] iOS version too old (requires 16.0+)');
      return LidarCapability(
        support: LidarSupport.oldIOS,
        deviceModel: deviceModel,
        osVersion: osVersion,
        isMultiRoomSupported: false,
        unsupportedReason:
            'LiDAR scanning requires iOS 16.0 or later. Please update your device.',
      );
    }

    print('✅ [LIDAR] LiDAR fully supported!');
    return LidarCapability(
      support: LidarSupport.supported,
      deviceModel: deviceModel,
      osVersion: osVersion,
      isMultiRoomSupported: isMultiRoom,
    );
  }

  bool get isScanningSupportpported => support == LidarSupport.supported;

  // Helper methods
  static Future<bool> _checkIOSLidarSupport() async {
    try {
      print('🔍 [LIDAR] Checking LiDAR support...');
      // Use flutter_roomplan's isSupported() method
      final roomplan = FlutterRoomplan();
      print('🔍 [LIDAR] FlutterRoomplan instance created');
      final isSupported = await roomplan.isSupported();
      print('🔍 [LIDAR] isSupported() returned: $isSupported');
      return isSupported;
    } catch (e) {
      // If flutter_roomplan is not available or throws, assume unsupported
      print('❌ [LIDAR] Error checking support: $e');
      return false;
    }
  }

  static Future<String> _getDeviceModel() async {
    // This is a simplified version - in production, use device_info_plus package
    if (Platform.isAndroid) {
      return 'Android Device';
    } else if (Platform.isIOS) {
      return 'iOS Device';
    } else {
      return 'Unknown Device';
    }
  }

  static Future<String> _getOSVersion() async {
    // Simplified version - in production, use device_info_plus package
    return Platform.operatingSystemVersion;
  }

  static bool _isIOSVersionAtLeast(String version, String target) {
    try {
      // Extract major.minor version from strings like "Version 16.5 (Build 20F66)"
      final versionMatch = RegExp(r'(\d+)\.(\d+)').firstMatch(version);
      final targetMatch = RegExp(r'(\d+)\.(\d+)').firstMatch(target);

      if (versionMatch == null || targetMatch == null) {
        return false;
      }

      final versionMajor = int.parse(versionMatch.group(1)!);
      final versionMinor = int.parse(versionMatch.group(2)!);
      final targetMajor = int.parse(targetMatch.group(1)!);
      final targetMinor = int.parse(targetMatch.group(2)!);

      if (versionMajor > targetMajor) return true;
      if (versionMajor < targetMajor) return false;
      return versionMinor >= targetMinor;
    } catch (e) {
      return false;
    }
  }
}
