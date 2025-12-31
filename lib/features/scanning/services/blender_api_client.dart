/// BlenderAPI Client for USDZ to GLB Conversion
/// Reference: Requirements/FLUTTER_API_PRD.md
///
/// This client handles all communication with the BlenderAPI service:
/// - Session management (create, delete)
/// - File upload (binary USDZ)
/// - Conversion processing (USDZ → GLB)
/// - Status polling (progress tracking)
/// - File download (binary GLB)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import '../models/blender_api_models.dart';
import '../models/error_context.dart';
import './error_log_service.dart';

class BlenderApiClient {
  late final String baseUrl;
  late final String apiKey;
  late final int timeoutSeconds;
  late final int pollIntervalSeconds;

  final http.Client _client;
  final ErrorLogService _errorLogService;

  /// Create HTTP client with certificate verification disabled in debug mode
  /// Similar to curl -k, but only for development/testing
  static http.Client _createHttpClient() {
    if (kDebugMode) {
      // Debug mode: Disable certificate verification (like curl -k)
      print('⚠️ [BlenderAPI] Running in DEBUG mode - Certificate verification DISABLED');
      final ioClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          print('⚠️ [BlenderAPI] Accepting certificate for $host:$port');
          return true; // Accept all certificates in debug mode
        };
      return IOClient(ioClient);
    } else {
      // Release mode: Use default client with full certificate verification
      return http.Client();
    }
  }

  BlenderApiClient({
    http.Client? client,
    String? baseUrl,
    String? apiKey,
    int? timeoutSeconds,
    int? pollIntervalSeconds,
    ErrorLogService? errorLogService,
  })  : _client = client ?? _createHttpClient(),
        _errorLogService = errorLogService ?? ErrorLogService() {
    // Load configuration from parameters or .env (with fallback defaults for testing)
    String? envBaseUrl;
    String? envApiKey;
    int? envTimeoutSeconds;
    int? envPollIntervalSeconds;

    try {
      envBaseUrl = dotenv.env['BLENDER_API_BASE_URL'];
      envApiKey = dotenv.env['BLENDER_API_KEY'];
      envTimeoutSeconds = int.tryParse(dotenv.env['BLENDER_API_TIMEOUT_SECONDS'] ?? '900');
      envPollIntervalSeconds = int.tryParse(dotenv.env['BLENDER_API_POLL_INTERVAL_SECONDS'] ?? '2');
    } catch (e) {
      // DotEnv not initialized (likely in test environment), use defaults
      if (kDebugMode) {
        print('⚠️ [BlenderAPI] DotEnv not initialized, using provided parameters or defaults');
      }
    }

    this.baseUrl = baseUrl ??
        envBaseUrl ??
        'https://blenderapi.stage.motorenflug.at';
    this.apiKey = apiKey ?? envApiKey ?? '';
    this.timeoutSeconds = timeoutSeconds ?? envTimeoutSeconds ?? 900;
    this.pollIntervalSeconds = pollIntervalSeconds ?? envPollIntervalSeconds ?? 2;

    if (this.apiKey.isEmpty || this.apiKey.length < 16) {
      throw BlenderApiException(
        statusCode: 0,
        message: 'BLENDER_API_KEY not configured in .env or too short (minimum 16 characters)',
      );
    }
  }

  /// Get base headers for all API requests
  Map<String, String> get _baseHeaders => {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      };

  /// Create a new BlenderAPI session
  /// POST /sessions
  /// Returns session ID and expiration time (1 hour)
  Future<BlenderApiSession> createSession() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/sessions'),
        headers: _baseHeaders,
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 201) {
        return BlenderApiSession.fromJson(json.decode(response.body));
      } else {
        throw await _handleError(response);
      }
    } on SocketException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Network error: Unable to connect to BlenderAPI service',
      );
    } on TimeoutException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Request timeout: BlenderAPI service did not respond',
      );
    }
  }

  /// Upload USDZ file to session
  /// POST /sessions/{sessionId}/upload
  /// Returns upload confirmation with file metadata
  ///
  /// IMPORTANT: Always reads file as bytes first (not as stream) to avoid
  /// "Stream has already been listened to" error. See FLUTTER_STREAM_FIX.md
  Future<BlenderApiUploadResponse> uploadFile({
    required String sessionId,
    required File file,
    String assetType = 'model/vnd.usdz+zip',
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      // ✅ Read file as bytes ONCE (not as stream)
      final fileBytes = await file.readAsBytes();
      final totalBytes = fileBytes.length;

      // Validate file size (500 MB limit)
      if (totalBytes > 500 * 1024 * 1024) {
        throw BlenderApiException(
          statusCode: 422,
          message: 'File size exceeds 500MB limit',
          errorCode: 'FILE_TOO_LARGE',
        );
      }

      // Call progress callback with total bytes (upload happens atomically)
      // Note: http package doesn't easily support real-time upload progress
      if (onProgress != null) {
        onProgress(totalBytes, totalBytes);
      }

      // ✅ Use simple http.post with body parameter (not stream)
      final response = await _client.post(
        Uri.parse('$baseUrl/sessions/$sessionId/upload'),
        headers: {
          'X-API-Key': apiKey,
          'X-Asset-Type': assetType,
          'X-Filename': file.path.split('/').last,
          'Content-Type': 'application/octet-stream',
        },
        body: fileBytes, // ✅ Direct bytes, not a stream
      ).timeout(
        Duration(seconds: timeoutSeconds),
      );

      if (response.statusCode == 200) {
        return BlenderApiUploadResponse.fromJson(json.decode(response.body));
      } else {
        throw await _handleError(response, sessionId: sessionId);
      }
    } on SocketException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Network error during file upload',
      );
    } on TimeoutException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Upload timeout: File upload took too long',
      );
    }
  }

  /// Start USDZ to GLB conversion
  /// POST /sessions/{sessionId}/convert
  /// Returns processing started confirmation
  Future<BlenderApiProcessingStarted> startConversion({
    required String sessionId,
    required String inputFilename,
    String? outputFilename,
    ConversionParams? conversionParams,
  }) async {
    try {
      final request = BlenderApiConversionRequest(
        inputFilename: inputFilename,
        outputFilename: outputFilename,
        conversionParams: conversionParams ?? ConversionParams(),
      );

      final response = await _client.post(
        Uri.parse('$baseUrl/sessions/$sessionId/convert'),
        headers: _baseHeaders,
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return BlenderApiProcessingStarted.fromJson(json.decode(response.body));
      } else {
        throw await _handleError(response, sessionId: sessionId);
      }
    } on SocketException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Network error: Unable to start conversion',
      );
    } on TimeoutException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Request timeout: Conversion start did not respond',
      );
    }
  }

  /// Get session status
  /// GET /sessions/{sessionId}/status
  /// Returns current processing status and progress (0-100%)
  Future<BlenderApiStatus> getStatus(String sessionId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/sessions/$sessionId/status'),
        headers: {'X-API-Key': apiKey},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return BlenderApiStatus.fromJson(json.decode(response.body));
      } else {
        throw await _handleError(response, sessionId: sessionId);
      }
    } on SocketException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Network error: Unable to check status',
      );
    } on TimeoutException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Request timeout: Status check did not respond',
      );
    }
  }

  /// Download converted GLB file
  /// GET /sessions/{sessionId}/download/{filename}
  /// Returns File object with downloaded GLB
  ///
  /// ⚠️ IMPORTANT: Callers must wait 2 seconds after this completes before deleting the session
  /// (See convertUsdzToGlb() for the recommended high-level workflow)
  Future<File> downloadFile({
    required String sessionId,
    required String filename,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      final request = http.Request(
        'GET',
        Uri.parse('$baseUrl/sessions/$sessionId/download/$filename'),
      );
      request.headers['X-API-Key'] = apiKey;

      final streamedResponse = await _client.send(request).timeout(
        Duration(seconds: timeoutSeconds),
      );

      if (streamedResponse.statusCode == 200) {
        // Get total file size from content-length header
        final contentLength = streamedResponse.contentLength ?? 0;

        // Get temporary directory to save file
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$filename';
        final file = File(filePath);

        // Download file with progress tracking
        final bytes = <int>[];
        int received = 0;

        await for (final chunk in streamedResponse.stream) {
          bytes.addAll(chunk);
          received += chunk.length;
          if (onProgress != null && contentLength > 0) {
            onProgress(received, contentLength);
          }
        }

        // Write bytes to file
        await file.writeAsBytes(bytes);
        return file;
      } else {
        final response = await http.Response.fromStream(streamedResponse);
        throw await _handleError(response, sessionId: sessionId);
      }
    } on SocketException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Network error during file download',
      );
    } on TimeoutException {
      throw BlenderApiException(
        statusCode: 0,
        message: 'Download timeout: File download took too long',
      );
    }
  }

  /// Delete session and clean up resources
  /// DELETE /sessions/{sessionId}
  /// Sessions auto-expire after 1 hour, but manual cleanup is recommended
  Future<void> deleteSession(String sessionId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: {'X-API-Key': apiKey},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode != 204 && response.statusCode != 200) {
        // Log error but don't throw - session cleanup is not critical
        print('Warning: Failed to delete session $sessionId: ${response.body}');
      }
    } catch (e) {
      // Log error but don't throw - session cleanup is not critical
      print('Warning: Error deleting session $sessionId: $e');
    }
  }

  /// Complete USDZ to GLB conversion workflow with mandatory race condition waits
  ///
  /// This is the recommended high-level method that orchestrates the entire conversion:
  /// 1. Create session
  /// 2. Upload USDZ file
  /// 3. Start conversion
  /// 4. Poll until complete
  /// 5. ⚠️ CRITICAL: Wait 3 seconds (file system flush)
  /// 6. Download GLB file
  /// 7. ⚠️ CRITICAL: Wait 2 seconds (HTTP stream closure)
  /// 8. Delete session (cleanup)
  ///
  /// Returns the downloaded GLB file
  ///
  /// Reference: PRD lines 890-939 (Race Condition Fix - Mandatory Wait Periods)
  Future<File> convertUsdzToGlb({
    required File usdzFile,
    String? outputFilename,
    ConversionParams? conversionParams,
    Function(int sent, int total)? onUploadProgress,
    Function(int progress)? onConversionProgress,
  }) async {
    String? sessionId;

    try {
      // 1. Create session
      final session = await createSession();
      sessionId = session.sessionId;

      // 2. Upload USDZ file
      final uploadResponse = await uploadFile(
        sessionId: sessionId,
        file: usdzFile,
        onProgress: onUploadProgress,
      );

      // 3. Start conversion
      await startConversion(
        sessionId: sessionId,
        inputFilename: uploadResponse.filename,
        outputFilename: outputFilename,
        conversionParams: conversionParams,
      );

      // 4. Poll until complete
      String? downloadFilename;
      await for (final status in pollStatus(sessionId: sessionId)) {
        if (onConversionProgress != null) {
          onConversionProgress(status.progress);
        }

        if (status.isCompleted) {
          downloadFilename = status.result?.filename;
          break;
        }
      }

      if (downloadFilename == null) {
        throw BlenderApiException(
          statusCode: 500,
          message: 'Conversion completed but no output filename provided',
          sessionId: sessionId,
        );
      }

      // 5. ⚠️ CRITICAL: Wait 3 seconds after completion
      //    Reason: File system needs time to finalize the file
      //    - Backend file system needs to flush buffers
      //    - Blender may still be writing final metadata
      //    - File size needs to stabilize
      print('⏱️ [BlenderAPI] Waiting 3 seconds for file system flush...');
      await Future.delayed(Duration(seconds: 3));

      // 6. Download GLB file
      final file = await downloadFile(
        sessionId: sessionId,
        filename: downloadFilename,
      );

      // 7. ⚠️ CRITICAL: Wait 2 seconds after download
      //    Reason: HTTP stream needs time to fully close
      //    - HTTP chunked transfer encoding needs to complete
      //    - Connection needs to cleanly close
      print('⏱️ [BlenderAPI] Waiting 2 seconds for HTTP stream closure...');
      await Future.delayed(Duration(seconds: 2));

      // 8. Delete session (cleanup)
      await deleteSession(sessionId);

      return file;
    } catch (e) {
      // Attempt cleanup on error (best effort)
      if (sessionId != null) {
        try {
          await deleteSession(sessionId);
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      rethrow;
    }
  }

  /// Poll session status until completion or failure
  /// Polls every pollIntervalSeconds (default: 2 seconds)
  /// Throws exception if conversion fails or timeout exceeded
  ///
  /// ⚠️ IMPORTANT: Callers must wait 3 seconds after this completes before downloading
  /// (See convertUsdzToGlb() for the recommended high-level workflow)
  Stream<BlenderApiStatus> pollStatus({
    required String sessionId,
    Duration? maxDuration,
  }) async* {
    final maxDur = maxDuration ?? Duration(seconds: timeoutSeconds);
    final startTime = DateTime.now();

    while (true) {
      // Check timeout
      if (DateTime.now().difference(startTime) > maxDur) {
        throw BlenderApiException(
          statusCode: 504,
          message: 'Conversion timeout: Processing exceeded ${maxDur.inSeconds} seconds',
          errorCode: 'TIMEOUT',
        );
      }

      // Get current status
      final status = await getStatus(sessionId);
      yield status;

      // Check if completed or failed
      if (status.isCompleted) {
        return;
      } else if (status.isFailed) {
        throw BlenderApiException(
          statusCode: 500,
          message: status.errorMessage ?? 'Conversion failed',
          errorCode: 'CONVERSION_FAILED',
        );
      }

      // Wait before next poll
      await Future.delayed(Duration(seconds: pollIntervalSeconds));
    }
  }

  /// Handle HTTP error responses
  /// Logs errors using ErrorLogService and creates exception with sessionId
  Future<BlenderApiException> _handleError(
    http.Response response, {
    String? sessionId,
    int retryCount = 0,
  }) async {
    BlenderApiException exception;

    try {
      final error = BlenderApiError.fromJson(json.decode(response.body));
      exception = BlenderApiException.fromError(
        response.statusCode,
        error,
        sessionId: sessionId,
      );
    } catch (e) {
      // If error response is not JSON, create generic exception
      exception = BlenderApiException(
        statusCode: response.statusCode,
        message: response.body.isNotEmpty
            ? response.body
            : 'HTTP ${response.statusCode} error',
        sessionId: sessionId,
      );
    }

    // Log error using ErrorLogService (Phase 3 integration)
    try {
      final errorContext = ErrorContext(
        timestamp: DateTime.now(),
        sessionId: sessionId,
        httpStatus: exception.statusCode,
        errorCode: exception.errorCode,
        message: exception.message,
        retryCount: retryCount,
        isRecoverable: exception.isRecoverable,
      );
      await _errorLogService.logError(errorContext);
    } catch (logError) {
      // Silently fail - logging errors shouldn't crash the app
      print('Warning: Failed to log error: $logError');
    }

    return exception;
  }

  /// Close HTTP client
  void dispose() {
    _client.close();
  }
}
