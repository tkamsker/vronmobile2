/// Media file model representing a file attached to a product
/// Used for product images, videos, and other media assets
class MediaFile {
  final String id;
  final String url;
  final String filename;
  final String? mimeType;
  final int? size;

  MediaFile({
    required this.id,
    required this.url,
    required this.filename,
    this.mimeType,
    this.size,
  });

  /// Create MediaFile from GraphQL JSON response
  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String,
      mimeType: (json['mime'] ?? json['mimeType']) as String?,
      size: json['size'] as int?,
    );
  }

  /// Check if this is an image file
  bool get isImage => mimeType?.startsWith('image/') ?? false;

  /// Check if this is a video file
  bool get isVideo => mimeType?.startsWith('video/') ?? false;

  /// Get human-readable file size
  String get formattedSize {
    if (size == null) return 'Unknown size';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) {
      return '${(size! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaFile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url &&
          filename == other.filename &&
          mimeType == other.mimeType &&
          size == other.size;

  @override
  int get hashCode =>
      id.hashCode ^
      url.hashCode ^
      filename.hashCode ^
      mimeType.hashCode ^
      size.hashCode;
}
