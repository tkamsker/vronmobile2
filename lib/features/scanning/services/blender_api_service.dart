import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

/// Service for converting USDZ to GLB using the Blender API
///
/// Workflow:
/// 1. Create session
/// 2. Upload USDZ file
/// 3. Start conversion
/// 4. Poll for completion
/// 5. Download GLB file
class BlenderApiService {
  final String apiUrl;
  final String apiKey;
  String? _deviceId;
  String? _platform;
  String? _osVersion;
  String? _deviceModel;

  BlenderApiService({
    this.apiUrl = 'https://blenderapi.stage.motorenflug.at',
    this.apiKey = 'dev-test-key-1234567890', // TODO: Move to secure config
  });

  /// Get device metadata for API headers
  Future<Map<String, String>> _getDeviceHeaders() async {
    // Initialize device metadata if not already done
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();

      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _platform = 'ios';
        _osVersion = iosInfo.systemVersion;
        _deviceModel = iosInfo.model;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _platform = 'android';
        _osVersion = androidInfo.version.release;
        _deviceModel = androidInfo.model;
      }
    }

    return {
      'X-Device-ID': _deviceId ?? 'unknown',
      'X-Platform': _platform ?? 'unknown',
      'X-OS-Version': _osVersion ?? 'unknown',
      'X-App-Version': '1.0.0', // TODO: Get from package info
      'X-Device-Model': _deviceModel ?? 'unknown',
    };
  }

  /// Convert USDZ file to GLB
  ///
  /// Parameters:
  /// - usdzPath: Path to local USDZ file
  /// - onProgress: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// Returns: Path to downloaded GLB file
  ///
  /// Throws: Exception if conversion fails
  Future<String> convertUsdzToGlb({
    required String usdzPath,
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      print('🔄 [BLENDER_API] Starting USDZ to GLB conversion');
      print('🔄 [BLENDER_API] Input file: $usdzPath');

      final usdzFile = File(usdzPath);
      if (!await usdzFile.exists()) {
        throw Exception('USDZ file not found: $usdzPath');
      }

      final filename = usdzPath.split('/').last;
      onProgress?.call(0.0, 'Creating session...');

      // Step 1: Create session
      final sessionId = await _createSession();
      print('✅ [BLENDER_API] Session created: $sessionId');
      onProgress?.call(0.2, 'Uploading file...');

      // Step 2: Upload USDZ file
      await _uploadFile(sessionId, usdzFile, filename);
      print('✅ [BLENDER_API] File uploaded');
      onProgress?.call(0.4, 'Starting conversion...');

      // Step 3: Start conversion
      await _startConversion(sessionId, filename);
      print('✅ [BLENDER_API] Conversion started');
      onProgress?.call(0.5, 'Converting...');

      // Step 4: Poll for completion
      final result = await _pollConversion(
        sessionId,
        onProgress: (progress) {
          // Map poll progress to 50-90% of total
          onProgress?.call(0.5 + (progress * 0.4), 'Converting... ${(progress * 100).toInt()}%');
        },
      );
      print('✅ [BLENDER_API] Conversion completed');
      onProgress?.call(0.9, 'Downloading result...');

      // Step 5: Download GLB file
      final glbPath = await _downloadGlb(sessionId, result['filename'] as String, usdzPath);
      print('✅ [BLENDER_API] GLB downloaded: $glbPath');
      onProgress?.call(1.0, 'Complete!');

      return glbPath;
    } catch (e) {
      print('❌ [BLENDER_API] Conversion failed: $e');
      rethrow;
    }
  }

  /// Create a new session
  Future<String> _createSession() async {
    final deviceHeaders = await _getDeviceHeaders();

    final response = await http.post(
      Uri.parse('$apiUrl/sessions'),
      headers: {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
        ...deviceHeaders,
      },
    );

    // API returns 201 (Created) for successful session creation
    if (response.statusCode != 201) {
      throw Exception('Failed to create session: ${response.statusCode} ${response.body}');
    }

    final data = json.decode(response.body);
    return data['session_id'] as String;
  }

  /// Upload USDZ file to session
  Future<void> _uploadFile(String sessionId, File file, String filename) async {
    final fileBytes = await file.readAsBytes();
    final deviceHeaders = await _getDeviceHeaders();

    final response = await http.post(
      Uri.parse('$apiUrl/sessions/$sessionId/upload'),
      headers: {
        'X-API-Key': apiKey,
        'X-Asset-Type': 'model/vnd.usdz+zip',
        'X-Filename': filename,
        'Content-Type': 'application/octet-stream',
        ...deviceHeaders,
      },
      body: fileBytes,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload file: ${response.statusCode} ${response.body}');
    }
  }

  /// Start USDZ to GLB conversion
  Future<void> _startConversion(String sessionId, String filename) async {
    final deviceHeaders = await _getDeviceHeaders();

    final response = await http.post(
      Uri.parse('$apiUrl/sessions/$sessionId/convert'),
      headers: {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
        ...deviceHeaders,
      },
      body: json.encode({
        'job_type': 'usdz_to_glb',
        'input_filename': filename,
        'conversion_params': {
          'apply_scale': false,
          'merge_meshes': false,
          'target_scale': 1.0,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start conversion: ${response.statusCode} ${response.body}');
    }
  }

  /// Poll for conversion completion
  Future<Map<String, dynamic>> _pollConversion(
    String sessionId, {
    void Function(double progress)? onProgress,
    Duration interval = const Duration(seconds: 2),
    int maxAttempts = 300, // 10 minutes max
  }) async {
    final deviceHeaders = await _getDeviceHeaders();

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(interval);

      final response = await http.get(
        Uri.parse('$apiUrl/sessions/$sessionId/status'),
        headers: {
          'X-API-Key': apiKey,
          ...deviceHeaders,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get status: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final status = data['session_status'] as String;
      final progress = data['progress'] as int? ?? 0;

      onProgress?.call(progress / 100.0);

      if (status == 'completed') {
        // Get result filename from metadata
        // API returns 'result' not 'result_metadata'
        final result = data['result'] as Map<String, dynamic>?;
        if (result == null) {
          throw Exception('No result found in status response');
        }
        return result;
      } else if (status == 'failed') {
        final errorMsg = data['error_message'] as String? ?? 'Unknown error';
        throw Exception('Conversion failed: $errorMsg');
      }

      // Continue polling
    }

    throw TimeoutException('Conversion timeout after ${maxAttempts * interval.inSeconds} seconds');
  }

  /// Download GLB file and save next to original USDZ
  Future<String> _downloadGlb(String sessionId, String filename, String usdzPath) async {
    final deviceHeaders = await _getDeviceHeaders();

    final response = await http.get(
      Uri.parse('$apiUrl/sessions/$sessionId/download/$filename'),
      headers: {
        'X-API-Key': apiKey,
        ...deviceHeaders,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download GLB: ${response.statusCode}');
    }

    // Save GLB next to USDZ file
    final usdzFile = File(usdzPath);
    final directory = usdzFile.parent;
    final baseName = usdzPath.split('/').last.replaceAll('.usdz', '');
    final glbPath = '${directory.path}/$baseName.glb';

    final glbFile = File(glbPath);
    await glbFile.writeAsBytes(response.bodyBytes);

    return glbPath;
  }

  /// Get session status (for manual polling)
  Future<Map<String, dynamic>> getSessionStatus(String sessionId) async {
    final deviceHeaders = await _getDeviceHeaders();

    final response = await http.get(
      Uri.parse('$apiUrl/sessions/$sessionId/status'),
      headers: {
        'X-API-Key': apiKey,
        ...deviceHeaders,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get status: ${response.statusCode}');
    }

    return json.decode(response.body);
  }
}
