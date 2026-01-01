import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vronmobile2/features/scanning/services/blender_api_client.dart';
import 'package:vronmobile2/features/scanning/services/device_info_service.dart';

void main() {
  group('BlenderApiClient Device Headers Integration', () {
    late DeviceInfoService deviceInfoService;

    setUp(() async {
      deviceInfoService = DeviceInfoService();
      await deviceInfoService.initialize();
    });

    test(
      'T015: all BlenderAPI requests include device context headers',
      () async {
        // Arrange
        Map<String, String>? capturedHeaders;

        final mockHttpClient = MockClient((request) async {
          capturedHeaders = request.headers;
          return http.Response(
            '{"sessionId": "test-session-123", "status": "pending"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = BlenderApiClient(
          apiKey: 'test-api-key-1234567890',
          baseUrl: 'https://api.example.com',
          deviceInfoService: deviceInfoService,
          client: mockHttpClient,
        );

        // Act
        await client.createSession();

        // Assert
        expect(capturedHeaders, isNotNull);

        // Verify mandatory X-Device-ID header
        expect(
          capturedHeaders!.containsKey('X-Device-ID'),
          isTrue,
          reason: 'X-Device-ID is mandatory for all BlenderAPI requests',
        );
        expect(capturedHeaders!['X-Device-ID'], isNotEmpty);

        // Verify UUID format for X-Device-ID
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        );
        expect(
          uuidRegex.hasMatch(capturedHeaders!['X-Device-ID']!),
          isTrue,
          reason: 'X-Device-ID should be a valid UUID',
        );

        // Verify optional headers are present (platform-dependent)
        final optionalHeaders = [
          'X-Platform',
          'X-OS-Version',
          'X-App-Version',
          'X-Device-Model',
        ];

        for (final header in optionalHeaders) {
          if (capturedHeaders!.containsKey(header)) {
            expect(
              capturedHeaders![header],
              isNotEmpty,
              reason: '$header should not be empty if present',
            );
          }
        }

        // Verify X-Platform value if present
        if (capturedHeaders!.containsKey('X-Platform')) {
          expect(
            capturedHeaders!['X-Platform'],
            anyOf(equals('ios'), equals('android')),
            reason: 'X-Platform should be either "ios" or "android"',
          );
        }

        // Verify other standard headers still present
        expect(capturedHeaders!.containsKey('X-API-Key'), isTrue);
        expect(capturedHeaders!['X-API-Key'], equals('test-api-key'));
      },
    );

    test('T015: device headers persist across multiple API calls', () async {
      // Arrange
      final capturedHeadersList = <Map<String, String>>[];

      final mockHttpClient = MockClient((request) async {
        capturedHeadersList.add(Map.from(request.headers));
        return http.Response(
          '{"sessionId": "test-session-${capturedHeadersList.length}", "status": "pending"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = BlenderApiClient(
        apiKey: 'test-api-key-1234567890',
        baseUrl: 'https://api.example.com',
        deviceInfoService: deviceInfoService,
        client: mockHttpClient,
      );

      // Act - Make multiple API calls
      await client.createSession();
      await client.createSession();
      await client.createSession();

      // Assert - All requests should have same device ID
      expect(capturedHeadersList.length, equals(3));

      final firstDeviceId = capturedHeadersList[0]['X-Device-ID'];
      expect(firstDeviceId, isNotNull);

      for (int i = 1; i < capturedHeadersList.length; i++) {
        expect(
          capturedHeadersList[i]['X-Device-ID'],
          equals(firstDeviceId),
          reason:
              'Device ID should remain consistent across multiple API calls',
        );
      }
    });
  });
}
