import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vronmobile2/features/scanning/models/room_outline.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';

/// Service for extracting 2D floor plan outlines from 3D scan models
/// Uses native platform code (iOS: SceneKit, Android: Filament/glTF parser)
class RoomOutlineExtractionService {
  static const MethodChannel _channel = MethodChannel(
    'com.vron.mobile/outline_extractor',
  );

  /// Extract 2D outline from scan data
  /// Returns RoomOutline with projected vertices or null if extraction fails
  Future<RoomOutline?> extractOutline(ScanData scan) async {
    try {
      // IMPORTANT: Always use USDZ path for outline extraction
      // iOS SceneKit (native extractor) only supports USDZ format
      // GLB files are for NavMesh generation only
      final String filePath = scan.localPath;

      if (filePath == null || filePath.isEmpty) {
        print('❌ No file path available for scan ${scan.id}');
        return null;
      }

      // Verify file exists
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ File does not exist: $filePath');
        return null;
      }

      print('🔄 Extracting outline from: $filePath');

      // Call native platform code
      final List<dynamic>? result = await _channel.invokeMethod(
        'extractOutline',
        {'filePath': filePath},
      );

      if (result == null || result.isEmpty) {
        print('❌ No outline extracted from $filePath');
        return null;
      }

      // Convert to Offset list
      final vertices = result.map((point) {
        final coords = point as List<dynamic>;
        return Offset(
          (coords[0] as num).toDouble(),
          (coords[1] as num).toDouble(),
        );
      }).toList();

      print('✅ Extracted ${vertices.length} vertices for scan ${scan.id}');

      // Scale vertices to canvas size (meters → pixels)
      // Assuming 1 meter = 100 pixels for visualization
      final scaleFactor = 100.0;
      final scaledVertices = vertices.map((v) {
        return Offset(v.dx * scaleFactor, v.dy * scaleFactor);
      }).toList();

      // Center the outline around origin for easier manipulation
      final centeredVertices = _centerVertices(scaledVertices);

      return RoomOutline(
        scanId: scan.id,
        roomName: scan.metadata?['roomName'] as String? ?? 'Room',
        vertices: centeredVertices,
        outlineColor: Colors.blue,
      );
    } on PlatformException catch (e) {
      print('❌ Platform exception extracting outline: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error extracting outline: $e');
      return null;
    }
  }

  /// Extract outlines for multiple scans
  Future<List<RoomOutline>> extractOutlines(List<ScanData> scans) async {
    final outlines = <RoomOutline>[];

    for (final scan in scans) {
      final outline = await extractOutline(scan);
      if (outline != null) {
        outlines.add(outline);
      } else {
        // Fallback to placeholder rectangle if extraction fails
        print('⚠️ Using placeholder outline for scan ${scan.id}');
        outlines.add(_createPlaceholderOutline(scan, outlines.length));
      }
    }

    return outlines;
  }

  /// Center vertices around origin (0, 0)
  List<Offset> _centerVertices(List<Offset> vertices) {
    if (vertices.isEmpty) return vertices;

    // Calculate centroid
    double sumX = 0;
    double sumY = 0;
    for (final vertex in vertices) {
      sumX += vertex.dx;
      sumY += vertex.dy;
    }

    final centroidX = sumX / vertices.length;
    final centroidY = sumY / vertices.length;

    // Translate vertices to center around origin
    return vertices.map((v) {
      return Offset(v.dx - centroidX, v.dy - centroidY);
    }).toList();
  }

  /// Create placeholder rectangle if extraction fails
  RoomOutline _createPlaceholderOutline(ScanData scan, int index) {
    // Simple rectangular outline as fallback
    final vertices = [
      const Offset(-50, -60), // Top-left
      const Offset(50, -60), // Top-right
      const Offset(50, 60), // Bottom-right
      const Offset(-50, 60), // Bottom-left
    ];

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    return RoomOutline(
      scanId: scan.id,
      roomName: 'Room ${index + 1}',
      vertices: vertices,
      outlineColor: colors[index % colors.length],
    );
  }
}
