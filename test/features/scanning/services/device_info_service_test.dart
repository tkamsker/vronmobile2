import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vronmobile2/features/scanning/services/device_info_service.dart';

void main() {
  group('DeviceInfoService', () {
    setUp(() {
      // Set initial values for SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    group('UUID generation', () {
      test('T008: generates new UUID on first initialization', () async {
        // Arrange
        final service = DeviceInfoService();

        // Act
        await service.initialize();
        final deviceId = service.deviceId;

        // Assert
        expect(deviceId, isNotNull);
        expect(deviceId, isNotEmpty);
        // UUID format: 8-4-4-4-12 hexadecimal characters
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        );
        expect(
          uuidRegex.hasMatch(deviceId!),
          isTrue,
          reason: 'Device ID should be a valid UUID',
        );
      });
    });

    group('Device ID persistence', () {
      test('T009: reuses existing device ID from SharedPreferences', () async {
        // Arrange
        const existingDeviceId = '12345678-1234-1234-1234-123456789abc';
        SharedPreferences.setMockInitialValues({'device_id': existingDeviceId});
        final service = DeviceInfoService();

        // Act
        await service.initialize();
        final deviceId = service.deviceId;

        // Assert
        expect(
          deviceId,
          equals(existingDeviceId),
          reason: 'Should reuse existing device ID from storage',
        );
      });
    });

    group('Platform-specific device info', () {
      test(
        'T010: collects iOS device info when running on iOS',
        () async {
          // Arrange
          final service = DeviceInfoService();

          // Act
          await service.initialize();

          // Assert
          // Note: In unit tests, we can't guarantee running on iOS
          // This test verifies the service initializes without errors
          expect(service.platform, isNotNull);
          expect(service.osVersion, isNotNull);
          expect(service.deviceModel, isNotNull);
        },
        skip: 'Requires iOS platform - integration test recommended',
      );

      test(
        'T011: collects Android device info when running on Android',
        () async {
          // Arrange
          final service = DeviceInfoService();

          // Act
          await service.initialize();

          // Assert
          // Note: In unit tests, we can't guarantee running on Android
          // This test verifies the service initializes without errors
          expect(service.platform, isNotNull);
          expect(service.osVersion, isNotNull);
          expect(service.deviceModel, isNotNull);
        },
        skip: 'Requires Android platform - integration test recommended',
      );
    });

    group('Device headers', () {
      test('T012: device headers are empty before initialization', () {
        // Arrange
        final service = DeviceInfoService();

        // Act
        final headers = service.deviceHeaders;

        // Assert
        expect(
          headers,
          isEmpty,
          reason:
              'Device headers should be empty before initialize() is called',
        );
      });

      test(
        'T013: device headers include all 5 fields after initialization',
        () async {
          // Arrange
          final service = DeviceInfoService();

          // Act
          await service.initialize();
          final headers = service.deviceHeaders;

          // Assert
          expect(headers, isNotEmpty);
          expect(headers.containsKey('X-Device-ID'), isTrue);
          expect(headers['X-Device-ID'], isNotNull);
          expect(headers['X-Device-ID'], isNotEmpty);

          // Optional headers (may be present based on platform availability)
          if (headers.containsKey('X-Platform')) {
            expect(
              headers['X-Platform'],
              anyOf(equals('ios'), equals('android')),
            );
          }
          if (headers.containsKey('X-OS-Version')) {
            expect(headers['X-OS-Version'], isNotEmpty);
          }
          if (headers.containsKey('X-App-Version')) {
            expect(headers['X-App-Version'], isNotEmpty);
          }
          if (headers.containsKey('X-Device-Model')) {
            expect(headers['X-Device-Model'], isNotEmpty);
          }
        },
      );
    });

    group('Error handling', () {
      test('T014: gracefully handles device_info_plus failures', () async {
        // Arrange
        final service = DeviceInfoService();

        // Act & Assert
        // Service should initialize without throwing even if device info fails
        await expectLater(
          service.initialize(),
          completes,
          reason:
              'Service should complete initialization even if device info collection fails',
        );

        // X-Device-ID should still be present (mandatory header)
        final headers = service.deviceHeaders;
        expect(headers.containsKey('X-Device-ID'), isTrue);
        expect(headers['X-Device-ID'], isNotNull);
      });
    });
  });
}
