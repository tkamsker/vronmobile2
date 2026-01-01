import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service for converting USDZ files to GLB format using native iOS ModelIO
///
/// This service uses platform channels to invoke native iOS code that:
/// 1. Loads the USDZ file using ModelIO framework
/// 2. Exports it to GLB (glTF 2.0 binary) format
/// 3. Returns the path to the converted GLB file
class UsdzConverterService {
  static const MethodChannel _channel = MethodChannel(
    'com.vron.mobile/usdz_converter',
  );

  /// Convert USDZ file to GLB format
  ///
  /// Parameters:
  /// - usdzPath: Full path to the USDZ file
  /// - outputFileName: Optional custom filename for GLB (defaults to same name as USDZ)
  ///
  /// Returns: Path to the converted GLB file
  ///
  /// Throws:
  /// - PlatformException if conversion fails
  /// - FileSystemException if file operations fail
  Future<String> convertUsdzToGlb({
    required String usdzPath,
    String? outputFileName,
  }) async {
    print('🔄 [CONVERTER] Starting conversion for: $usdzPath');

    // Verify input file exists
    final usdzFile = File(usdzPath);
    if (!await usdzFile.exists()) {
      throw FileSystemException('USDZ file not found', usdzPath);
    }

    // Generate output path
    final glbPath = await _generateGlbPath(usdzPath, outputFileName);
    print('🔄 [CONVERTER] Output path: $glbPath');

    try {
      // Call native iOS conversion method
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'convertUsdzToGlb',
        {'usdzPath': usdzPath, 'glbPath': glbPath},
      );

      if (result == null) {
        throw PlatformException(
          code: 'NULL_RESULT',
          message: 'Native method returned null',
        );
      }

      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown result';

      if (!success) {
        throw PlatformException(code: 'CONVERSION_FAILED', message: message);
      }

      final outputPath = result['glbPath'] as String? ?? glbPath;
      print('✅ [CONVERTER] Conversion successful: $outputPath');

      // Verify output file exists
      final glbFile = File(outputPath);
      if (!await glbFile.exists()) {
        throw FileSystemException('GLB file was not created', outputPath);
      }

      final fileSize = await glbFile.length();
      print('✅ [CONVERTER] Output file size: ${_formatBytes(fileSize)}');

      return outputPath;
    } on PlatformException catch (e) {
      print('❌ [CONVERTER] Platform error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [CONVERTER] Unexpected error: $e');
      rethrow;
    }
  }

  /// Generate output GLB file path
  ///
  /// Places GLB files in the same directory as the USDZ file
  /// or in app documents directory if custom filename provided
  Future<String> _generateGlbPath(
    String usdzPath,
    String? customFileName,
  ) async {
    if (customFileName != null) {
      // Use custom filename in documents directory
      final docDir = await getApplicationDocumentsDirectory();
      return '${docDir.path}/$customFileName';
    }

    // Use same directory and filename as USDZ, just change extension
    final file = File(usdzPath);
    final directory = file.parent.path;
    final filename = file.uri.pathSegments.last;
    final nameWithoutExt = filename.replaceAll('.usdz', '');

    return '$directory/$nameWithoutExt.glb';
  }

  /// Format bytes for human-readable output
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if conversion is supported on this platform
  ///
  /// USDZ→GLB conversion is only supported on iOS using ModelIO
  bool isConversionSupported() {
    return Platform.isIOS;
  }

  /// Get estimated conversion time based on file size
  ///
  /// This is a rough estimate:
  /// - Small files (<5MB): ~1-2 seconds
  /// - Medium files (5-20MB): ~2-5 seconds
  /// - Large files (>20MB): ~5-10 seconds
  Duration estimateConversionTime(int fileSizeBytes) {
    final sizeMB = fileSizeBytes / (1024 * 1024);

    if (sizeMB < 5) {
      return const Duration(seconds: 2);
    } else if (sizeMB < 20) {
      return const Duration(seconds: 4);
    } else {
      return const Duration(seconds: 8);
    }
  }
}
