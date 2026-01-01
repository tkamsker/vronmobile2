import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';

/// Enumeration of file upload error types
enum FileUploadError {
  noFileSelected,
  invalidExtension,
  fileTooLarge,
  noFilePath,
  copyFailed,
}

/// Service for handling GLB file uploads from device storage
///
/// Supports User Story 2: Upload GLB File
/// - File picker integration
/// - Extension validation (.glb only)
/// - File size validation (≤250 MB)
/// - File copy to app Documents directory
class FileUploadService {
  static const int maxFileSizeBytes = 250 * 1024 * 1024; // 250 MB
  static const String validExtension = 'glb';

  final FilePicker _filePicker;

  /// Constructor with optional FilePicker injection for testing
  FileUploadService({FilePicker? filePicker})
    : _filePicker = filePicker ?? FilePicker.platform;

  /// Pick and validate a GLB file from device storage
  ///
  /// Returns [ScanData] if file is valid, null otherwise
  ///
  /// Validation:
  /// - File must have .glb extension
  /// - File size must be ≤250 MB
  /// - File must have a valid path
  Future<ScanData?> pickAndValidateGLB() async {
    try {
      // Open file picker
      final FilePickerResult? result = await _filePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      // User cancelled
      if (result == null || result.files.isEmpty) {
        return null;
      }

      final PlatformFile file = result.files.first;

      // Validate file path exists
      if (file.path == null) {
        return null;
      }

      // Validate extension
      if (!isValidExtension(file.name)) {
        return null;
      }

      // Validate file size
      if (!isValidFileSize(file.size)) {
        return null;
      }

      // Copy file to app Documents directory
      final String newPath = await _copyFileToDocuments(file.path!, file.name);

      // Create ScanData entity
      final scanData = ScanData(
        id: _generateId(),
        format: ScanFormat.glb,
        localPath: newPath,
        fileSizeBytes: file.size,
        capturedAt: DateTime.now(),
        status: ScanStatus.completed,
      );

      return scanData;
    } catch (e) {
      // Log error and return null
      print('Error picking GLB file: $e');
      return null;
    }
  }

  /// Validate file extension is .glb (case-insensitive)
  bool isValidExtension(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return extension == validExtension;
  }

  /// Validate file size is within 250 MB limit
  bool isValidFileSize(int sizeBytes) {
    return sizeBytes <= maxFileSizeBytes;
  }

  /// Copy file to app Documents/scans directory
  ///
  /// Returns the new file path
  Future<String> _copyFileToDocuments(
    String sourcePath,
    String filename,
  ) async {
    // Get Documents directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();

    // Create scans subdirectory if it doesn't exist
    final Directory scansDir = Directory('${appDocDir.path}/scans');
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    // Generate unique filename to avoid collisions
    final String uniqueFilename = '${_generateId()}_$filename';
    final String destinationPath = '${scansDir.path}/$uniqueFilename';

    // Copy file
    final File sourceFile = File(sourcePath);
    await sourceFile.copy(destinationPath);

    return destinationPath;
  }

  /// Generate unique ID for scans (consistent with scanning_service.dart)
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString();
    return 'glb-$timestamp-$random';
  }

  /// Get user-friendly error message for a given error type
  String getErrorMessage(FileUploadError error) {
    switch (error) {
      case FileUploadError.noFileSelected:
        return 'No file was selected. Please try again.';
      case FileUploadError.invalidExtension:
        return 'Only GLB format is supported. Please select a .glb file.';
      case FileUploadError.fileTooLarge:
        return 'File size exceeds 250 MB limit. Please select a smaller file.';
      case FileUploadError.noFilePath:
        return 'Unable to access the selected file. Please try again.';
      case FileUploadError.copyFailed:
        return 'Failed to copy file to app storage. Please check available storage space.';
    }
  }

  /// Format file size in human-readable format
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
