import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/conversion_result.dart';

void main() {
  group('ConversionStatus', () {
    test('should have all required status values', () {
      expect(ConversionStatus.values.length, 5);
      expect(ConversionStatus.values, containsAll([
        ConversionStatus.pending,
        ConversionStatus.inProgress,
        ConversionStatus.completed,
        ConversionStatus.failed,
        ConversionStatus.notApplicable,
      ]));
    });

    test('should parse from string (backend format)', () {
      expect(ConversionStatus.fromString('PENDING'), ConversionStatus.pending);
      expect(ConversionStatus.fromString('IN_PROGRESS'), ConversionStatus.inProgress);
      expect(ConversionStatus.fromString('COMPLETED'), ConversionStatus.completed);
      expect(ConversionStatus.fromString('FAILED'), ConversionStatus.failed);
      expect(ConversionStatus.fromString('NOT_APPLICABLE'), ConversionStatus.notApplicable);
    });

    test('should convert to GraphQL format', () {
      expect(ConversionStatus.pending.toGraphQL(), 'PENDING');
      expect(ConversionStatus.inProgress.toGraphQL(), 'IN_PROGRESS');
      expect(ConversionStatus.completed.toGraphQL(), 'COMPLETED');
      expect(ConversionStatus.failed.toGraphQL(), 'FAILED');
      expect(ConversionStatus.notApplicable.toGraphQL(), 'NOT_APPLICABLE');
    });
  });

  group('ConversionError', () {
    test('should create from JSON', () {
      final json = {
        'code': 'UNSUPPORTED_PRIM',
        'message': 'USDZ contains geometry types not supported in glTF',
      };

      final error = ConversionError.fromJson(json);

      expect(error.code, 'UNSUPPORTED_PRIM');
      expect(error.message, 'USDZ contains geometry types not supported in glTF');
    });

    test('should convert to JSON', () {
      final error = ConversionError(
        code: 'SERVER_ERROR',
        message: 'Internal conversion service error',
      );

      final json = error.toJson();

      expect(json['code'], 'SERVER_ERROR');
      expect(json['message'], 'Internal conversion service error');
    });
  });

  group('ConversionResult', () {
    test('should create success result from JSON', () {
      final json = {
        'scan': {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'projectId': '123e4567-e89b-12d3-a456-426614174000',
          'format': 'USDZ',
          'usdzUrl': 'https://s3.amazonaws.com/vron-scans/test.usdz',
          'glbUrl': 'https://s3.amazonaws.com/vron-scans/test.glb',
          'fileSizeBytes': 15728640,
          'capturedAt': '2025-12-25T14:30:00Z',
          'conversionStatus': 'COMPLETED',
          'createdAt': '2025-12-25T14:35:22Z',
        },
        'success': true,
        'message': 'Scan uploaded and converted successfully',
      };

      final result = ConversionResult.fromJson(json);

      expect(result.success, true);
      expect(result.message, 'Scan uploaded and converted successfully');
      expect(result.scanId, '550e8400-e29b-41d4-a716-446655440000');
      expect(result.usdzUrl, 'https://s3.amazonaws.com/vron-scans/test.usdz');
      expect(result.glbUrl, 'https://s3.amazonaws.com/vron-scans/test.glb');
      expect(result.conversionStatus, ConversionStatus.completed);
      expect(result.error, null);
    });

    test('should create failure result from JSON', () {
      final json = {
        'scan': {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'format': 'USDZ',
          'usdzUrl': 'https://s3.amazonaws.com/vron-scans/test.usdz',
          'glbUrl': null,
          'conversionStatus': 'FAILED',
        },
        'success': false,
        'message': 'File uploaded but GLB conversion failed',
      };

      final result = ConversionResult.fromJson(json);

      expect(result.success, false);
      expect(result.message, 'File uploaded but GLB conversion failed');
      expect(result.conversionStatus, ConversionStatus.failed);
      expect(result.glbUrl, null);
    });

    test('should handle error object in scan', () {
      final json = {
        'scan': {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'conversionStatus': 'FAILED',
          'error': {
            'code': 'UNSUPPORTED_PRIM',
            'message': 'USDZ contains unsupported geometry',
          },
        },
        'success': false,
        'message': 'Conversion failed',
      };

      final result = ConversionResult.fromJson(json);

      expect(result.error, isNotNull);
      expect(result.error!.code, 'UNSUPPORTED_PRIM');
      expect(result.error!.message, 'USDZ contains unsupported geometry');
    });

    test('should provide isComplete getter', () {
      final completed = ConversionResult(
        success: true,
        conversionStatus: ConversionStatus.completed,
        scanId: 'test-id',
      );

      final pending = ConversionResult(
        success: true,
        conversionStatus: ConversionStatus.pending,
        scanId: 'test-id',
      );

      final failed = ConversionResult(
        success: false,
        conversionStatus: ConversionStatus.failed,
        scanId: 'test-id',
      );

      expect(completed.isComplete, true);
      expect(pending.isComplete, false);
      expect(failed.isComplete, true); // Failed is also "complete" (terminal state)
    });

    test('should provide isSuccess getter', () {
      final completed = ConversionResult(
        success: true,
        conversionStatus: ConversionStatus.completed,
        scanId: 'test-id',
      );

      final failed = ConversionResult(
        success: false,
        conversionStatus: ConversionStatus.failed,
        scanId: 'test-id',
      );

      expect(completed.isSuccess, true);
      expect(failed.isSuccess, false);
    });
  });
}
