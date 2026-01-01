import 'dart:async';
import '../models/conversion_result.dart';
import '../models/scan_data.dart';
import '../../../core/services/graphql_service.dart';

/// Service for uploading scans to the backend and monitoring conversion status
///
/// Workflow:
/// 1. Upload USDZ file to backend via GraphQL multipart mutation
/// 2. Backend stores file in S3 and initiates USDZ→GLB conversion
/// 3. Poll conversion status until complete (or failed)
/// 4. Return final result with GLB URL
class ScanUploadService {
  final GraphQLService _graphQLService;

  ScanUploadService({GraphQLService? graphQLService})
    : _graphQLService = graphQLService ?? GraphQLService();

  /// Upload scan file to backend
  ///
  /// Parameters:
  /// - scanData: The scan to upload (must have valid localPath)
  /// - projectId: The project to associate the scan with
  /// - onProgress: Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns: ConversionResult with initial upload status
  ///
  /// Throws:
  /// - ArgumentError if scanData.localPath is empty or projectId is empty
  /// - Exception if upload fails
  Future<ConversionResult> uploadScan({
    required ScanData scanData,
    required String projectId,
    void Function(double progress)? onProgress,
  }) async {
    // Validation
    if (scanData.localPath.isEmpty) {
      throw ArgumentError('scanData.localPath cannot be empty');
    }
    if (projectId.isEmpty) {
      throw ArgumentError('projectId cannot be empty');
    }

    // GraphQL mutation for uploading scan
    const mutation = r'''
      mutation UploadProjectScan($projectId: UUID!, $file: Upload!) {
        uploadProjectScan(input: {
          projectId: $projectId
          file: $file
        }) {
          scan {
            id
            projectId
            format
            usdzUrl
            glbUrl
            fileSizeBytes
            capturedAt
            conversionStatus
            error {
              code
              message
            }
            createdAt
          }
          success
          message
        }
      }
    ''';

    try {
      // Upload file using multipart request
      final response = await _graphQLService.uploadFile(
        mutation: mutation,
        filePath: scanData.localPath,
        fileFieldName: 'file',
        variables: {'projectId': projectId},
        onProgress: onProgress,
      );

      // Parse uploadProjectScan response
      final result = ConversionResult.fromJson(
        response['uploadProjectScan'] as Map<String, dynamic>,
      );

      return result;
    } catch (e) {
      // Re-throw with context
      throw Exception('Failed to upload scan: $e');
    }
  }

  /// Poll backend for conversion status until complete
  ///
  /// Parameters:
  /// - scanId: The scan ID to poll
  /// - pollingInterval: How long to wait between polls (default: 2 seconds)
  /// - maxAttempts: Maximum number of polling attempts (default: 60)
  /// - onStatusChange: Optional callback when status changes
  ///
  /// Returns: Final ConversionResult when conversion is complete
  ///
  /// Throws:
  /// - ArgumentError if scanId is empty
  /// - TimeoutException if maxAttempts exceeded
  Future<ConversionResult> pollConversionStatus({
    required String scanId,
    Duration pollingInterval = const Duration(seconds: 2),
    int maxAttempts = 60,
    void Function(ConversionStatus status)? onStatusChange,
  }) async {
    // Validation
    if (scanId.isEmpty) {
      throw ArgumentError('scanId cannot be empty');
    }

    // GraphQL query for scan status
    const query = r'''
      query GetScanStatus($scanId: UUID!) {
        scan(id: $scanId) {
          id
          projectId
          format
          usdzUrl
          glbUrl
          fileSizeBytes
          capturedAt
          conversionStatus
          error {
            code
            message
          }
        }
      }
    ''';

    ConversionStatus? lastStatus;
    int attempt = 0;

    while (attempt < maxAttempts) {
      try {
        // Query scan status
        final response = await _graphQLService.query(
          query,
          variables: {'scanId': scanId},
        );

        // Parse scan data
        final scanData = response.data?['scan'] as Map<String, dynamic>?;
        if (scanData == null) {
          throw Exception('Scan not found: $scanId');
        }

        // Create result from scan data
        final result = ConversionResult.fromJson({
          'scan': scanData,
          'success': true,
          'message': 'Status retrieved successfully',
        });

        // Notify status change
        if (onStatusChange != null && result.conversionStatus != lastStatus) {
          onStatusChange(result.conversionStatus);
          lastStatus = result.conversionStatus;
        }

        // If conversion is complete (success or failure), return immediately
        if (result.isComplete) {
          return result;
        }

        // Wait before next poll
        await Future.delayed(pollingInterval);
        attempt++;
      } catch (e) {
        // On error, increment attempt and retry
        attempt++;
        if (attempt >= maxAttempts) {
          throw Exception('Failed to poll scan status: $e');
        }
        await Future.delayed(pollingInterval);
      }
    }

    // Max attempts exceeded
    throw TimeoutException(
      'Conversion polling timeout after $maxAttempts attempts',
      pollingInterval * maxAttempts,
    );
  }

  /// Upload scan and poll for conversion completion
  ///
  /// Combines uploadScan() and pollConversionStatus() into single operation.
  /// Progress callback reports combined upload (0-50%) and conversion (50-100%) progress.
  ///
  /// Parameters:
  /// - scanData: The scan to upload
  /// - projectId: The project to associate the scan with
  /// - pollingInterval: How long to wait between conversion polls
  /// - maxAttempts: Maximum number of polling attempts
  /// - onProgress: Optional callback for overall progress (0.0 to 1.0)
  ///
  /// Returns: Final ConversionResult when conversion is complete
  ///
  /// Throws: Same exceptions as uploadScan() and pollConversionStatus()
  Future<ConversionResult> uploadAndPoll({
    required ScanData scanData,
    required String projectId,
    Duration pollingInterval = const Duration(seconds: 2),
    int maxAttempts = 60,
    void Function(double progress)? onProgress,
  }) async {
    // Upload phase (0-50% of total progress)
    onProgress?.call(0.0);

    final uploadResult = await uploadScan(
      scanData: scanData,
      projectId: projectId,
      onProgress: (uploadProgress) {
        // Map upload progress to 0-50% of total
        onProgress?.call(uploadProgress * 0.5);
      },
    );

    // If upload failed or no scan ID, return immediately
    if (!uploadResult.success || uploadResult.scanId == null) {
      return uploadResult;
    }

    // If already complete (e.g., direct GLB upload), return immediately
    if (uploadResult.isComplete) {
      onProgress?.call(1.0);
      return uploadResult;
    }

    // Polling phase (50-100% of total progress)
    onProgress?.call(0.5);

    var attempt = 0;
    final pollResult = await pollConversionStatus(
      scanId: uploadResult.scanId!,
      pollingInterval: pollingInterval,
      maxAttempts: maxAttempts,
      onStatusChange: (status) {
        attempt++;
        // Map polling progress to 50-100% of total
        final pollProgress = attempt / maxAttempts;
        onProgress?.call(0.5 + (pollProgress * 0.5));
      },
    );

    onProgress?.call(1.0);
    return pollResult;
  }
}
