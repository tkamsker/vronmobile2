import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service for collecting device information for backend diagnostics
///
/// Collects and caches device context (device ID, platform, OS version, app version,
/// device model) for inclusion in BlenderAPI request headers. Device ID is randomly
/// generated UUID (privacy-compliant, not hardware-based) and persisted across
/// app launches.
///
/// Performance: <100ms first call, <10ms cached calls
class DeviceInfoService {
  static const String _deviceIdKey = 'device_id';

  String? _deviceId;
  String? _platform;
  String? _osVersion;
  String? _appVersion;
  String? _deviceModel;
  bool _initialized = false;

  /// Device ID (random UUID, persisted in SharedPreferences)
  String? get deviceId => _deviceId;

  /// Platform: "ios" or "android"
  String? get platform => _platform;

  /// OS version (e.g., "17.2" for iOS, "13" for Android)
  String? get osVersion => _osVersion;

  /// App version from pubspec.yaml (e.g., "1.4.2")
  String? get appVersion => _appVersion;

  /// Device model identifier (e.g., "iPad13,8")
  String? get deviceModel => _deviceModel;

  /// Whether the service has been initialized
  bool get initialized => _initialized;

  /// Initialize device info collection (call once on first API request)
  ///
  /// Collects:
  /// - Device ID: Random UUID (generated once, persisted)
  /// - Platform: iOS or Android
  /// - OS Version: From device_info_plus
  /// - App Version: From pubspec.yaml via package_info_plus
  /// - Device Model: From device_info_plus
  ///
  /// Gracefully handles errors (device ID will always be available,
  /// other fields may be null if collection fails)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load or generate device ID
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString(_deviceIdKey);

      if (_deviceId == null || _deviceId!.isEmpty) {
        // Generate new UUID
        _deviceId = const Uuid().v4();
        await prefs.setString(_deviceIdKey, _deviceId!);
      }

      // Collect platform info
      if (Platform.isIOS) {
        _platform = 'ios';
      } else if (Platform.isAndroid) {
        _platform = 'android';
      }

      // Collect device details via device_info_plus
      try {
        final deviceInfo = DeviceInfoPlugin();

        if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          _osVersion = iosInfo.systemVersion;
          _deviceModel = iosInfo.model;
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          _osVersion = androidInfo.version.release;
          _deviceModel = androidInfo.model;
        }
      } catch (e) {
        // Graceful fallback: device info collection failed
        // Log warning but don't fail initialization
        print('⚠️ [DeviceInfoService] Failed to collect device info: $e');
      }

      // Collect app version via package_info_plus
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        _appVersion = packageInfo.version;
      } catch (e) {
        // Graceful fallback: package info collection failed
        print('⚠️ [DeviceInfoService] Failed to collect app version: $e');
      }

      _initialized = true;
      print(
        '📱 [DeviceInfoService] Initialized: deviceId=$_deviceId, '
        'platform=$_platform, osVersion=$_osVersion, '
        'appVersion=$_appVersion, deviceModel=$_deviceModel',
      );
    } catch (e) {
      // Critical failure: even device ID generation failed
      print('❌ [DeviceInfoService] Initialization failed: $e');
      // Generate fallback UUID
      _deviceId = const Uuid().v4();
      _initialized = true;
    }
  }

  /// Get device context headers for HTTP requests
  ///
  /// Returns empty map if not initialized (call initialize() first).
  /// X-Device-ID is mandatory, other headers are optional based on availability.
  ///
  /// Example:
  /// ```dart
  /// final service = DeviceInfoService();
  /// await service.initialize();
  /// final headers = service.deviceHeaders;
  /// // headers = {
  /// //   'X-Device-ID': '8c1f9b2a-4e5d-4c8e-b4fa-9a7b3f6d92ab',
  /// //   'X-Platform': 'ios',
  /// //   'X-OS-Version': '17.2',
  /// //   'X-App-Version': '1.4.2',
  /// //   'X-Device-Model': 'iPad13,8'
  /// // }
  /// ```
  Map<String, String> get deviceHeaders {
    if (!_initialized || _deviceId == null) {
      return {};
    }

    final headers = <String, String>{'X-Device-ID': _deviceId!};

    if (_platform != null) headers['X-Platform'] = _platform!;
    if (_osVersion != null) headers['X-OS-Version'] = _osVersion!;
    if (_appVersion != null) headers['X-App-Version'] = _appVersion!;
    if (_deviceModel != null) headers['X-Device-Model'] = _deviceModel!;

    return headers;
  }
}
