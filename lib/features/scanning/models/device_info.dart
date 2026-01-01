/// Device information model for diagnostic headers
///
/// Contains device context information sent to backend for error diagnostics
/// and support troubleshooting. All data is non-sensitive and privacy-compliant.
class DeviceInfo {
  /// Unique device identifier (random UUID, not hardware-based)
  final String deviceId;

  /// Platform: "ios" or "android"
  final String? platform;

  /// OS version (e.g., "17.2" for iOS, "13" for Android)
  final String? osVersion;

  /// App version from pubspec.yaml (e.g., "1.4.2")
  final String? appVersion;

  /// Device model identifier (e.g., "iPad13,8", "SM-G998B")
  final String? deviceModel;

  DeviceInfo({
    required this.deviceId,
    this.platform,
    this.osVersion,
    this.appVersion,
    this.deviceModel,
  });

  /// Convert device info to HTTP headers
  Map<String, String> toHeaders() {
    final headers = <String, String>{'X-Device-ID': deviceId};

    if (platform != null) headers['X-Platform'] = platform!;
    if (osVersion != null) headers['X-OS-Version'] = osVersion!;
    if (appVersion != null) headers['X-App-Version'] = appVersion!;
    if (deviceModel != null) headers['X-Device-Model'] = deviceModel!;

    return headers;
  }

  @override
  String toString() {
    return 'DeviceInfo(deviceId: $deviceId, platform: $platform, '
        'osVersion: $osVersion, appVersion: $appVersion, '
        'deviceModel: $deviceModel)';
  }
}
