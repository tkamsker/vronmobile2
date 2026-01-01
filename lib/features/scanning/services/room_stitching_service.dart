import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_request.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_job.dart';
import 'package:vronmobile2/features/scanning/services/retry_policy_service.dart';

/// Service for stitching multiple room scans into a single 3D model
///
/// Handles:
/// - GraphQL mutation to initiate stitching
/// - Polling logic with 2-second intervals
/// - Result file download
/// - Error handling with retry policy
/// - Offline queue integration (Feature 015)
class RoomStitchingService {
  final GraphQLService graphQLService;
  final RetryPolicyService retryPolicyService;

  RoomStitchingService({
    required this.graphQLService,
    required this.retryPolicyService,
  });

  /// Starts a stitching job by calling the StitchRooms mutation
  ///
  /// Throws [ArgumentError] if request is invalid (< 2 scans)
  /// Throws [Exception] on network errors or GraphQL errors
  ///
  /// Returns [RoomStitchJob] with jobId for polling
  Future<RoomStitchJob> startStitching(RoomStitchRequest request) async {
    // Validate request
    if (!request.isValid()) {
      throw ArgumentError(
        'Invalid stitching request: Must have at least 2 scans and non-empty projectId',
      );
    }

    // Build GraphQL mutation
    const mutation = '''
      mutation StitchRooms(\$input: StitchRoomsInput!) {
        stitchRooms(input: \$input) {
          jobId
          status
          estimatedDurationSeconds
          createdAt
        }
      }
    ''';

    try {
      // Execute mutation
      final result = await graphQLService.mutate(
        mutation,
        variables: request.toGraphQLVariables(),
      );

      // Check for errors
      if (result.hasException) {
        throw Exception(
          'Failed to start stitching: ${result.exception.toString()}',
        );
      }

      // Parse response
      final data = result.data?['stitchRooms'];
      if (data == null) {
        throw Exception('No data returned from stitchRooms mutation');
      }

      // Create RoomStitchJob from response
      return RoomStitchJob(
        jobId: data['jobId'] as String,
        status: _parseStatus(data['status'] as String),
        progress: 0, // Initial progress
        createdAt: DateTime.parse(data['createdAt'] as String),
        estimatedDurationSeconds: data['estimatedDurationSeconds'] as int?,
      );
    } catch (e) {
      // Preserve specific exception types for proper error handling
      if (e is TimeoutException || e is SocketException) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  /// Polls stitching job status until terminal state (COMPLETED or FAILED)
  ///
  /// Parameters:
  /// - [jobId]: Job identifier from startStitching
  /// - [pollingInterval]: Time between polls (default: 2 seconds)
  /// - [maxAttempts]: Maximum polling attempts (default: 60 = 2 minutes)
  /// - [onStatusChange]: Callback invoked when status changes
  ///
  /// Throws [TimeoutException] if maxAttempts exceeded
  /// Throws [Exception] on non-recoverable errors
  ///
  /// Returns completed or failed [RoomStitchJob]
  Future<RoomStitchJob> pollStitchStatus({
    required String jobId,
    Duration pollingInterval = const Duration(seconds: 2),
    int maxAttempts = 60,
    void Function(RoomStitchJob)? onStatusChange,
  }) async {
    int attempts = 0;
    RoomStitchJobStatus? lastStatus;

    while (attempts < maxAttempts) {
      attempts++;

      try {
        // Query job status
        final job = await _queryJobStatus(jobId);

        // Notify if status changed
        if (onStatusChange != null && job.status != lastStatus) {
          onStatusChange(job);
          lastStatus = job.status;
        }

        // Check if terminal state reached
        if (job.isTerminal) {
          return job;
        }

        // Wait before next poll
        await Future.delayed(pollingInterval);
      } catch (e) {
        // Check if error is recoverable
        final isRecoverable = retryPolicyService.isRecoverable(null, null);

        if (!isRecoverable) {
          // Non-recoverable error - rethrow
          rethrow;
        }

        // Recoverable error - continue polling with backoff
        await Future.delayed(pollingInterval);
      }
    }

    // Max attempts exceeded
    throw TimeoutException(
      'Polling exceeded maximum attempts ($maxAttempts)',
    );
  }

  /// Queries job status from backend
  ///
  /// Internal method used by pollStitchStatus
  Future<RoomStitchJob> _queryJobStatus(String jobId) async {
    const query = '''
      query GetStitchJobStatus(\$jobId: ID!) {
        stitchJob(jobId: \$jobId) {
          jobId
          status
          progress
          errorCode
          errorMessage
          resultUrl
          createdAt
          completedAt
          metadata {
            polygonCount
            textureCount
            fileSizeBytes
          }
        }
      }
    ''';

    final result = await graphQLService.query(
      query,
      variables: {'jobId': jobId},
    );

    if (result.hasException) {
      throw Exception(
        'Failed to query job status: ${result.exception.toString()}',
      );
    }

    final data = result.data?['stitchJob'];
    if (data == null) {
      throw Exception('Job not found: $jobId');
    }

    // Parse metadata if present
    Map<String, dynamic>? metadata;
    if (data['metadata'] != null) {
      final meta = data['metadata'] as Map<String, dynamic>;
      metadata = {
        'polygonCount': meta['polygonCount'],
        'textureCount': meta['textureCount'],
        'fileSizeBytes': meta['fileSizeBytes'],
      };
    }

    return RoomStitchJob(
      jobId: data['jobId'] as String,
      status: _parseStatus(data['status'] as String),
      progress: data['progress'] as int,
      errorMessage: data['errorMessage'] as String?,
      resultUrl: data['resultUrl'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'] as String)
          : null,
    );
  }

  /// Downloads stitched model from resultUrl and saves to local storage
  ///
  /// Parameters:
  /// - [resultUrl]: Signed S3 URL from completed job
  /// - [filename]: Local filename (from RoomStitchRequest.generateFilename())
  ///
  /// Throws [Exception] on download failure or non-200 status code
  ///
  /// Returns [File] object pointing to downloaded GLB/USDZ file
  Future<File> downloadStitchedModel({
    required String resultUrl,
    required String filename,
  }) async {
    try {
      // Download file
      final response = await http.get(Uri.parse(resultUrl));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download stitched model: HTTP ${response.statusCode}',
        );
      }

      // Get Documents/scans directory
      final directory = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${directory.path}/scans');

      // Create directory if it doesn't exist
      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }

      // Save file
      final file = File('${scansDir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      throw Exception('Download error: $e');
    }
  }

  /// Parses GraphQL status string to RoomStitchJobStatus enum
  RoomStitchJobStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return RoomStitchJobStatus.pending;
      case 'UPLOADING':
        return RoomStitchJobStatus.uploading;
      case 'PROCESSING':
        return RoomStitchJobStatus.processing;
      case 'ALIGNING':
        return RoomStitchJobStatus.aligning;
      case 'MERGING':
        return RoomStitchJobStatus.merging;
      case 'COMPLETED':
        return RoomStitchJobStatus.completed;
      case 'FAILED':
        return RoomStitchJobStatus.failed;
      default:
        throw ArgumentError('Unknown status: $status');
    }
  }

  /// Translates error codes to user-friendly messages
  ///
  /// Maps backend error codes (from GraphQL contract) to actionable messages
  String _translateErrorCode(String? errorCode) {
    if (errorCode == null) return 'Stitching failed';

    switch (errorCode.toUpperCase()) {
      case 'INSUFFICIENT_OVERLAP':
        return 'Insufficient overlap between scans - please rescan with more overlap (at least 20% common area)';
      case 'ALIGNMENT_FAILURE':
        return 'Unable to align rooms - scans may be incompatible or of different spaces';
      case 'BACKEND_TIMEOUT':
        return 'Processing exceeded 5-minute limit - try splitting into smaller batches';
      case 'INCOMPATIBLE_FORMATS':
        return 'Mixed scan formats detected - please use consistent format';
      case 'INVALID_SCAN_ID':
        return 'One or more scans not found - please verify scans exist';
      case 'UNAUTHORIZED':
        return 'Authentication required - please sign in again';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too many stitching requests - please wait a moment and try again';
      case 'STORAGE_LIMIT_EXCEEDED':
        return 'Storage quota exceeded - please free up space or upgrade plan';
      default:
        return 'Stitching failed: $errorCode';
    }
  }
}
