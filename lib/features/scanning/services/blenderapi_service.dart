import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vronmobile2/core/config/env_config.dart';

/// REST API client for BlenderAPI microservice
/// Feature 018: Combined Scan to NavMesh Workflow
/// Handles session-based navmesh generation workflow
class BlenderAPIService {
  final String baseUrl;
  final String apiKey;
  final http.Client client;

  /// Unity-standard navmesh parameters (hard-coded per spec)
  static const Map<String, dynamic> unityStandardNavMeshParams = {
    'cell_size': 0.3, // 30cm grid resolution
    'cell_height': 0.2, // 20cm height resolution
    'agent_height': 2.0, // 2m tall agent (Unity default)
    'agent_radius': 0.6, // 60cm wide agent
    'agent_max_climb': 0.9, // 90cm max step height
    'agent_max_slope': 45.0, // 45° max slope angle
  };

  BlenderAPIService({
    String? baseUrl,
    String? apiKey,
    http.Client? client,
  })  : baseUrl = baseUrl ?? EnvConfig.blenderApiBaseUrl,
        apiKey = apiKey ?? EnvConfig.blenderApiKey,
        client = client ?? http.Client();

  /// Step 1: Create a new BlenderAPI session
  ///
  /// Returns session ID for subsequent operations
  ///
  /// Throws [Exception] if session creation fails
  Future<String> createSession() async {
    final url = Uri.parse('$baseUrl/sessions');

    try {
      print('🔄 Creating BlenderAPI session at $baseUrl');

      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': apiKey,
          'X-Device-ID': '8c1f9b2a-4e5d-4c8e-b4fa-9a7b3f6d92ab',
          'X-Platform': 'ios',
          'X-OS-Version': '17.2',
          'X-App-Version': '1.4.2',
          'X-Device-Model': 'iPad13,8',
        },
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final sessionId = data['session_id'] as String?;

        if (sessionId == null) {
          throw Exception('Session ID not found in response');
        }

        print('✅ Session created: $sessionId');
        return sessionId;
      } else {
        throw Exception(
          'Failed to create session: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to create BlenderAPI session: $e');
    }
  }

  /// Step 2: Upload GLB file to session
  ///
  /// [sessionId] - Active session ID
  /// [glbFile] - GLB file to upload
  /// [onProgress] - Optional progress callback (0.0 to 1.0)
  ///
  /// Throws [Exception] if upload fails
  Future<void> uploadGLB({
    required String sessionId,
    required File glbFile,
    void Function(double progress)? onProgress,
  }) async {
    if (!await glbFile.exists()) {
      throw Exception('GLB file does not exist: ${glbFile.path}');
    }

    final url = Uri.parse('$baseUrl/sessions/$sessionId/upload');
    final filename = glbFile.path.split('/').last;

    try {
      final fileBytes = await glbFile.readAsBytes();
      final totalBytes = fileBytes.length;

      print('📤 Uploading ${filename} (${totalBytes} bytes)');

      // Report initial progress
      onProgress?.call(0.0);

      final response = await client.post(
        url,
        headers: {
          'X-API-Key': apiKey,
          'X-Asset-Type': 'model/gltf-binary',
          'X-Filename': filename,
          'Content-Type': 'application/octet-stream',
          'X-Device-ID': '8c1f9b2a-4e5d-4c8e-b4fa-9a7b3f6d92ab',
          'X-Platform': 'ios',
          'X-OS-Version': '17.2',
          'X-App-Version': '1.4.2',
          'X-Device-Model': 'iPad13,8',
        },
        body: fileBytes,
      );

      // Report completion
      onProgress?.call(1.0);

      if (response.statusCode != 200) {
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }

      print('✅ Upload completed');
    } catch (e) {
      throw Exception('Failed to upload GLB to BlenderAPI: $e');
    }
  }

  /// Step 3: Start navmesh generation
  ///
  /// [sessionId] - Active session ID
  /// [inputFilename] - Name of uploaded GLB file
  /// [outputFilename] - Desired navmesh output filename
  /// [navmeshParams] - Optional parameters (defaults to Unity-standard)
  ///
  /// Throws [Exception] if start fails
  Future<void> startNavMeshGeneration({
    required String sessionId,
    required String inputFilename,
    required String outputFilename,
    Map<String, dynamic>? navmeshParams,
  }) async {
    final url = Uri.parse('$baseUrl/sessions/$sessionId/navmesh');

    // Use provided params or Unity-standard defaults
    final params = navmeshParams ?? unityStandardNavMeshParams;

    final requestBody = {
      'job_type': 'navmesh_generation',
      'input_filename': inputFilename,
      'output_filename': outputFilename,
      'navmesh_params': params,
    };

    try {
      print('🗺️ Starting navmesh generation...');
      print('   Input: $inputFilename');
      print('   Output: $outputFilename');

      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': apiKey,
          'X-Device-ID': '8c1f9b2a-4e5d-4c8e-b4fa-9a7b3f6d92ab',
          'X-Platform': 'ios',
          'X-OS-Version': '17.2',
          'X-App-Version': '1.4.2',
          'X-Device-Model': 'iPad13,8',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to start navmesh generation: ${response.statusCode} - ${response.body}',
        );
      }

      print('✅ Navmesh generation started');
    } catch (e) {
      throw Exception('Failed to start navmesh generation: $e');
    }
  }

  /// Step 4: Poll session status until completed
  ///
  /// [sessionId] - Active session ID
  /// [pollingInterval] - Time between polls (default: 2 seconds)
  /// [maxAttempts] - Maximum polling attempts (default: 450 = 15 minutes)
  ///
  /// Returns final status ("completed")
  ///
  /// Throws [Exception] if status is failed
  /// Throws [TimeoutException] if max attempts reached
  Future<String> pollStatus({
    required String sessionId,
    Duration? pollingInterval,
    int? maxAttempts,
  }) async {
    final interval = pollingInterval ?? Duration(seconds: 2);
    final maxAttempt = maxAttempts ?? 450; // 15 minutes at 2-second intervals

    final url = Uri.parse('$baseUrl/sessions/$sessionId/status');

    print('⏳ Polling status...');

    for (var attempt = 0; attempt < maxAttempt; attempt++) {
      try {
        final response = await client.get(
          url,
          headers: {
            'X-API-Key': apiKey,
            'X-Device-ID': '8c1f9b2a-4e5d-4c8e-b4fa-9a7b3f6d92ab',
            'X-Platform': 'ios',
            'X-OS-Version': '17.2',
            'X-App-Version': '1.4.2',
            'X-Device-Model': 'iPad13,8',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          // IMPORTANT: API returns 'session_status' not 'status'
          final status = data['session_status'] as String?;
          final progress = data['progress'] as int? ?? 0;

          if (status == null) {
            throw Exception('session_status not found in response');
          }

          print('   Status: $status ($progress%)');

          if (status == 'completed') {
            print('✅ Navmesh generation completed');
            return status;
          } else if (status == 'failed') {
            final error = data['error_message'] as String? ?? 'Unknown error';
            throw Exception('NavMesh generation failed: $error');
          }

          // Still processing, wait and retry
          await Future.delayed(interval);
        } else {
          throw Exception(
            'Status poll failed: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('failed')) {
          rethrow; // Re-throw FAILED status
        }
        // Continue polling on other errors
        await Future.delayed(interval);
      }
    }

    throw TimeoutException(
      'NavMesh generation timed out after ${maxAttempt * interval.inSeconds} seconds',
    );
  }

  /// Step 5: Download navmesh file from session
  ///
  /// [sessionId] - Active session ID
  /// [filename] - Navmesh filename to download
  /// [outputPath] - Local path to save downloaded file
  ///
  /// Throws [Exception] if download fails
  Future<void> downloadNavMesh({
    required String sessionId,
    required String filename,
    required String outputPath,
  }) async {
    final url = Uri.parse('$baseUrl/sessions/$sessionId/download/$filename');

    try {
      print('📥 Downloading navmesh: $filename');

      final response = await client.get(
        url,
        headers: {
          'X-API-Key': apiKey,
          'X-Device-ID': '8c1f9b2a-4e5d-4c8e-b4fa-9a7b3f6d92ab',
          'X-Platform': 'ios',
          'X-OS-Version': '17.2',
          'X-App-Version': '1.4.2',
          'X-Device-Model': 'iPad13,8',
        },
      );

      if (response.statusCode == 200) {
        // Save to file
        final outputFile = File(outputPath);
        await outputFile.create(recursive: true);
        await outputFile.writeAsBytes(response.bodyBytes);

        print('✅ Downloaded to: $outputPath (${response.bodyBytes.length} bytes)');
      } else {
        throw Exception(
          'Download failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to download navmesh: $e');
    }
  }

  /// Step 6: Delete session (cleanup)
  ///
  /// [sessionId] - Session ID to delete
  ///
  /// Note: Best-effort cleanup, does not throw on failure
  Future<void> deleteSession({required String sessionId}) async {
    final url = Uri.parse('$baseUrl/sessions/$sessionId');

    try {
      print('🧹 Cleaning up session: $sessionId');

      await client.delete(
        url,
        headers: {
          'X-API-Key': apiKey,
          'X-Device-ID': '8c1f9b2a-4e5d-4c8e-b4fa-9a7b3f6d92ab',
          'X-Platform': 'ios',
          'X-OS-Version': '17.2',
          'X-App-Version': '1.4.2',
          'X-Device-Model': 'iPad13,8',
        },
      );

      print('✅ Session deleted');
      // Ignore response status - cleanup is best-effort
    } catch (e) {
      // Log but don't throw - cleanup failures are non-fatal
      print('⚠️ Warning: Failed to delete BlenderAPI session $sessionId: $e');
    }
  }

  /// Complete navmesh generation workflow (convenience method)
  ///
  /// Orchestrates all 6 steps:
  /// 1. Create session
  /// 2. Upload GLB
  /// 3. Start navmesh
  /// 4. Poll status
  /// 5. Download result
  /// 6. Delete session
  ///
  /// [glbFile] - Combined GLB file to process
  /// [outputPath] - Where to save navmesh file
  /// [onProgress] - Optional progress callback
  ///
  /// Returns path to downloaded navmesh file
  Future<String> generateNavMesh({
    required File glbFile,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) async {
    String? sessionId;

    try {
      // Step 1: Create session
      onProgress?.call(0.1);
      sessionId = await createSession();

      // Step 2: Upload GLB
      onProgress?.call(0.2);
      await uploadGLB(
        sessionId: sessionId,
        glbFile: glbFile,
        onProgress: (uploadProgress) {
          onProgress?.call(0.2 + (uploadProgress * 0.2)); // 20-40%
        },
      );

      // Step 3: Start navmesh generation
      onProgress?.call(0.4);
      final inputFilename = glbFile.path.split('/').last;
      final outputFilename = 'navmesh_$inputFilename';

      await startNavMeshGeneration(
        sessionId: sessionId,
        inputFilename: inputFilename,
        outputFilename: outputFilename,
      );

      // Step 4: Poll status
      onProgress?.call(0.5);
      await pollStatus(sessionId: sessionId);

      // Step 5: Download navmesh
      onProgress?.call(0.9);
      await downloadNavMesh(
        sessionId: sessionId,
        filename: outputFilename,
        outputPath: outputPath,
      );

      onProgress?.call(1.0);

      return outputPath;
    } finally {
      // Step 6: Always cleanup session
      if (sessionId != null) {
        await deleteSession(sessionId: sessionId);
      }
    }
  }
}
