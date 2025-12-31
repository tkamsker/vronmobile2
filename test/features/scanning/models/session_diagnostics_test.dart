import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/session_diagnostics.dart';

void main() {
  group('SessionDiagnostics', () {
    test('should deserialize from JSON with all fields', () {
      // Arrange
      final json = {
        'session_id': 'sess_ABC123',
        'session_status': 'completed',
        'created_at': '2025-12-30T12:00:00Z',
        'expires_at': '2025-12-30T13:00:00Z',
        'last_accessed': '2025-12-30T12:30:00Z',
        'workspace_exists': true,
        'files': {
          'directories': {
            'input': {
              'exists': true,
              'file_count': 1,
              'files': [
                {
                  'name': 'scan.usdz',
                  'size_bytes': 1234567,
                  'modified_at': '2025-12-30T12:01:00Z',
                }
              ],
            },
            'output': {
              'exists': true,
              'file_count': 1,
              'files': [
                {
                  'name': 'scan.glb',
                  'size_bytes': 2345678,
                  'modified_at': '2025-12-30T12:05:00Z',
                }
              ],
            },
            'logs': {
              'exists': true,
              'file_count': 1,
              'files': [
                {
                  'name': 'blender.log',
                  'size_bytes': 45678,
                  'modified_at': '2025-12-30T12:05:00Z',
                }
              ],
            },
          },
          'root_files': [
            {
              'name': 'status.json',
              'size_bytes': 1234,
              'modified_at': '2025-12-30T12:00:00Z',
            }
          ],
        },
        'status_data': {
          'processing_stage': 'completed',
          'progress': 100,
        },
        'metadata': {
          'filename': 'scan.glb',
          'size_bytes': 2345678,
        },
        'parameters': {
          'job_type': 'usdz_to_glb',
        },
        'logs_summary': {
          'total_lines': 150,
          'error_count': 0,
          'warning_count': 2,
          'file_size_bytes': 45678,
          'last_lines': ['INFO: Conversion complete'],
          'first_timestamp': '2025-12-30T12:01:00Z',
          'last_timestamp': '2025-12-30T12:05:00Z',
        },
        'error_details': null,
        'investigation_timestamp': '2025-12-30T12:30:00Z',
      };

      // Act
      final diagnostics = SessionDiagnostics.fromJson(json);

      // Assert
      expect(diagnostics.sessionId, 'sess_ABC123');
      expect(diagnostics.sessionStatus, 'completed');
      expect(diagnostics.workspaceExists, true);
      expect(diagnostics.files, isNotNull);
      expect(diagnostics.files!.directories['input']!.exists, true);
      expect(diagnostics.files!.directories['input']!.fileCount, 1);
      expect(diagnostics.files!.directories['input']!.files.length, 1);
      expect(diagnostics.files!.directories['input']!.files[0].name, 'scan.usdz');
      expect(diagnostics.logsSummary, isNotNull);
      expect(diagnostics.logsSummary!.totalLines, 150);
      expect(diagnostics.errorDetails, null);
    });

    test('should handle minimal response (session not found scenario)', () {
      // Arrange
      final json = {
        'session_id': 'sess_XYZ789',
        'session_status': 'expired',
        'created_at': '2025-12-30T11:00:00Z',
        'expires_at': '2025-12-30T12:00:00Z',
        'last_accessed': null,
        'workspace_exists': false,
        'files': null,
        'status_data': null,
        'metadata': null,
        'parameters': null,
        'logs_summary': null,
        'error_details': null,
        'investigation_timestamp': '2025-12-30T13:00:00Z',
      };

      // Act
      final diagnostics = SessionDiagnostics.fromJson(json);

      // Assert
      expect(diagnostics.sessionId, 'sess_XYZ789');
      expect(diagnostics.sessionStatus, 'expired');
      expect(diagnostics.workspaceExists, false);
      expect(diagnostics.files, null);
      expect(diagnostics.statusData, null);
      expect(diagnostics.metadata, null);
      expect(diagnostics.logsSummary, null);
      expect(diagnostics.errorDetails, null);
    });

    test('should handle failed session with error details', () {
      // Arrange
      final json = {
        'session_id': 'sess_FAILED',
        'session_status': 'failed',
        'created_at': '2025-12-30T11:00:00Z',
        'expires_at': '2025-12-30T12:00:00Z',
        'last_accessed': '2025-12-30T11:05:00Z',
        'workspace_exists': true,
        'files': null,
        'status_data': null,
        'metadata': null,
        'parameters': null,
        'logs_summary': null,
        'error_details': {
          'error_message': 'Failed to load USDZ',
          'error_code': 'malformed_usdz',
          'processing_stage': 'upload_validation',
          'failed_at': '2025-12-30T11:03:00Z',
          'blender_exit_code': 1,
          'last_error_logs': [
            'ERROR: Invalid geometry data',
            'ERROR: Conversion aborted',
          ],
        },
        'investigation_timestamp': '2025-12-30T11:10:00Z',
      };

      // Act
      final diagnostics = SessionDiagnostics.fromJson(json);

      // Assert
      expect(diagnostics.sessionStatus, 'failed');
      expect(diagnostics.errorDetails, isNotNull);
      expect(diagnostics.errorDetails!.errorMessage, 'Failed to load USDZ');
      expect(diagnostics.errorDetails!.errorCode, 'malformed_usdz');
      expect(diagnostics.errorDetails!.processingStage, 'upload_validation');
      expect(diagnostics.errorDetails!.blenderExitCode, 1);
      expect(diagnostics.errorDetails!.lastErrorLogs.length, 2);
    });

    test('isExpired should return true when current time is after expiration', () {
      // Arrange - create session that expired 1 hour ago
      final json = {
        'session_id': 'sess_OLD',
        'session_status': 'expired',
        'created_at': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'expires_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'last_accessed': null,
        'workspace_exists': false,
        'files': null,
        'status_data': null,
        'metadata': null,
        'parameters': null,
        'logs_summary': null,
        'error_details': null,
        'investigation_timestamp': DateTime.now().toIso8601String(),
      };

      // Act
      final diagnostics = SessionDiagnostics.fromJson(json);

      // Assert
      expect(diagnostics.isExpired, true);
    });

    test('isExpired should return false when session is still valid', () {
      // Arrange - create session that expires in 30 minutes
      final json = {
        'session_id': 'sess_VALID',
        'session_status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(Duration(minutes: 30)).toIso8601String(),
        'last_accessed': null,
        'workspace_exists': true,
        'files': null,
        'status_data': null,
        'metadata': null,
        'parameters': null,
        'logs_summary': null,
        'error_details': null,
        'investigation_timestamp': DateTime.now().toIso8601String(),
      };

      // Act
      final diagnostics = SessionDiagnostics.fromJson(json);

      // Assert
      expect(diagnostics.isExpired, false);
    });

    test('statusMessage should return correct message for each status', () {
      // Test each status
      final statuses = {
        'active': 'Session active, ready for upload',
        'processing': 'Conversion in progress',
        'completed': 'Conversion completed successfully',
        'failed': 'Conversion failed',
        'expired': 'Session expired (TTL: 1 hour)',
      };

      statuses.forEach((status, expectedMessage) {
        final json = {
          'session_id': 'sess_TEST',
          'session_status': status,
          'created_at': '2025-12-30T12:00:00Z',
          'expires_at': '2025-12-30T13:00:00Z',
          'last_accessed': null,
          'workspace_exists': false,
          'files': null,
          'status_data': null,
          'metadata': null,
          'parameters': null,
          'logs_summary': null,
          'error_details': null,
          'investigation_timestamp': '2025-12-30T12:00:00Z',
        };

        final diagnostics = SessionDiagnostics.fromJson(json);
        expect(diagnostics.statusMessage, expectedMessage);
      });
    });
  });

  group('FileInfo', () {
    test('sizeHumanReadable should format bytes correctly', () {
      // Test different file sizes
      expect(FileInfo(name: 'test', sizeBytes: 512, modifiedAt: null).sizeHumanReadable, '512 B');
      expect(FileInfo(name: 'test', sizeBytes: 1536, modifiedAt: null).sizeHumanReadable, '1.5 KB');
      expect(FileInfo(name: 'test', sizeBytes: 2097152, modifiedAt: null).sizeHumanReadable, '2.0 MB');
      expect(FileInfo(name: 'test', sizeBytes: 5242880, modifiedAt: null).sizeHumanReadable, '5.0 MB');
    });
  });
}
