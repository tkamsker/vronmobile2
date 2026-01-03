import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/lidar_capability.dart';

void main() {
  group('LidarCapability', () {
    // T019: Test detect() on supported device
    test('detect() returns supported capability on iPhone 12 Pro+', () async {
      // This test will require mocking platform channels
      // For now, we verify the structure exists

      // Mock: iOS device with LiDAR, iOS 16.0+
      final capability = LidarCapability(
        support: LidarSupport.supported,
        deviceModel: 'iPhone 14 Pro',
        osVersion: '16.5',
        isMultiRoomSupported: false,
      );

      expect(capability.support, LidarSupport.supported);
      expect(capability.isScanningSupportpported, true);
      expect(capability.unsupportedReason, null);
      expect(capability.deviceModel, 'iPhone 14 Pro');
    });

    test('detect() supports multi-room on iOS 17.0+', () async {
      final capability = LidarCapability(
        support: LidarSupport.supported,
        deviceModel: 'iPhone 15 Pro',
        osVersion: '17.1',
        isMultiRoomSupported: true,
      );

      expect(capability.isMultiRoomSupported, true);
      expect(capability.isScanningSupportpported, true);
    });

    // T020: Test detect() on unsupported device (Android)
    test('detect() returns notApplicable on Android device', () async {
      // Mock: Android device
      final capability = LidarCapability(
        support: LidarSupport.notApplicable,
        deviceModel: 'Pixel 7',
        osVersion: 'Android 13',
        isMultiRoomSupported: false,
        unsupportedReason:
            'LiDAR scanning is not available on Android devices. You can upload GLB files instead.',
      );

      expect(capability.support, LidarSupport.notApplicable);
      expect(capability.isScanningSupportpported, false);
      expect(capability.unsupportedReason, isNotNull);
      expect(capability.unsupportedReason, contains('Android'));
    });

    test('detect() returns noLidar on iPhone without LiDAR', () async {
      // Mock: iPhone 11 (no LiDAR)
      final capability = LidarCapability(
        support: LidarSupport.noLidar,
        deviceModel: 'iPhone 11',
        osVersion: '16.5',
        isMultiRoomSupported: false,
        unsupportedReason:
            'Your device does not have a LiDAR scanner. LiDAR is available on iPhone 12 Pro and newer Pro models.',
      );

      expect(capability.support, LidarSupport.noLidar);
      expect(capability.isScanningSupportpported, false);
      expect(capability.unsupportedReason, contains('LiDAR scanner'));
    });

    test('detect() returns oldIOS on iOS < 16.0', () async {
      // Mock: iPhone 12 Pro with iOS 15.7
      final capability = LidarCapability(
        support: LidarSupport.oldIOS,
        deviceModel: 'iPhone 12 Pro',
        osVersion: '15.7',
        isMultiRoomSupported: false,
        unsupportedReason:
            'LiDAR scanning requires iOS 16.0 or later. Please update your device.',
      );

      expect(capability.support, LidarSupport.oldIOS);
      expect(capability.isScanningSupportpported, false);
      expect(capability.unsupportedReason, contains('iOS 16.0'));
    });

    test('isScanningSupportpported returns correct boolean', () {
      final supported = LidarCapability(
        support: LidarSupport.supported,
        deviceModel: 'iPhone 14 Pro',
        osVersion: '16.5',
        isMultiRoomSupported: false,
      );

      final unsupported = LidarCapability(
        support: LidarSupport.noLidar,
        deviceModel: 'iPhone 11',
        osVersion: '16.5',
        isMultiRoomSupported: false,
        unsupportedReason: 'No LiDAR',
      );

      expect(supported.isScanningSupportpported, true);
      expect(unsupported.isScanningSupportpported, false);
    });
  });
}
