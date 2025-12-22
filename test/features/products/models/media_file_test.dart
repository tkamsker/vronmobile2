import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/models/media_file.dart';

void main() {
  group('MediaFile', () {
    group('fromJson', () {
      test('T001: parses complete JSON correctly', () {
        // Arrange
        final json = {
          'id': 'media_123',
          'url': 'https://cdn.example.com/image.jpg',
          'filename': 'product_image.jpg',
          'mimeType': 'image/jpeg',
          'size': 245678,
        };

        // Act
        final mediaFile = MediaFile.fromJson(json);

        // Assert
        expect(mediaFile.id, 'media_123');
        expect(mediaFile.url, 'https://cdn.example.com/image.jpg');
        expect(mediaFile.filename, 'product_image.jpg');
        expect(mediaFile.mimeType, 'image/jpeg');
        expect(mediaFile.size, 245678);
      });

      test('parses JSON with null optional fields', () {
        // Arrange
        final json = {
          'id': 'media_123',
          'url': 'https://cdn.example.com/image.jpg',
          'filename': 'product_image.jpg',
        };

        // Act
        final mediaFile = MediaFile.fromJson(json);

        // Assert
        expect(mediaFile.id, 'media_123');
        expect(mediaFile.url, 'https://cdn.example.com/image.jpg');
        expect(mediaFile.filename, 'product_image.jpg');
        expect(mediaFile.mimeType, isNull);
        expect(mediaFile.size, isNull);
      });
    });

    group('isImage', () {
      test('T002: returns true for image MIME types', () {
        // Arrange
        final imageFile = MediaFile(
          id: 'media_1',
          url: 'https://example.com/image.jpg',
          filename: 'image.jpg',
          mimeType: 'image/jpeg',
        );

        // Act & Assert
        expect(imageFile.isImage, isTrue);
      });

      test('returns true for different image formats', () {
        final imageTypes = [
          'image/jpeg',
          'image/png',
          'image/gif',
          'image/webp',
        ];

        for (final type in imageTypes) {
          final file = MediaFile(
            id: 'media_1',
            url: 'https://example.com/file',
            filename: 'file',
            mimeType: type,
          );
          expect(file.isImage, isTrue, reason: '$type should be image');
        }
      });

      test('returns false for non-image MIME types', () {
        // Arrange
        final videoFile = MediaFile(
          id: 'media_1',
          url: 'https://example.com/video.mp4',
          filename: 'video.mp4',
          mimeType: 'video/mp4',
        );

        // Act & Assert
        expect(videoFile.isImage, isFalse);
      });

      test('returns false when mimeType is null', () {
        // Arrange
        final file = MediaFile(
          id: 'media_1',
          url: 'https://example.com/file',
          filename: 'file',
        );

        // Act & Assert
        expect(file.isImage, isFalse);
      });
    });

    group('isVideo', () {
      test('returns true for video MIME types', () {
        // Arrange
        final videoFile = MediaFile(
          id: 'media_1',
          url: 'https://example.com/video.mp4',
          filename: 'video.mp4',
          mimeType: 'video/mp4',
        );

        // Act & Assert
        expect(videoFile.isVideo, isTrue);
      });

      test('returns false for non-video MIME types', () {
        // Arrange
        final imageFile = MediaFile(
          id: 'media_1',
          url: 'https://example.com/image.jpg',
          filename: 'image.jpg',
          mimeType: 'image/jpeg',
        );

        // Act & Assert
        expect(imageFile.isVideo, isFalse);
      });
    });

    group('formattedSize', () {
      test('T003: formats bytes correctly', () {
        // Arrange
        final file = MediaFile(
          id: 'media_1',
          url: 'https://example.com/file',
          filename: 'file',
          size: 512,
        );

        // Act & Assert
        expect(file.formattedSize, '512 B');
      });

      test('formats kilobytes correctly', () {
        // Arrange
        final file = MediaFile(
          id: 'media_1',
          url: 'https://example.com/file',
          filename: 'file',
          size: 2048, // 2 KB
        );

        // Act & Assert
        expect(file.formattedSize, '2.0 KB');
      });

      test('formats megabytes correctly', () {
        // Arrange
        final file = MediaFile(
          id: 'media_1',
          url: 'https://example.com/file',
          filename: 'file',
          size: 2097152, // 2 MB
        );

        // Act & Assert
        expect(file.formattedSize, '2.0 MB');
      });

      test('returns "Unknown size" when size is null', () {
        // Arrange
        final file = MediaFile(
          id: 'media_1',
          url: 'https://example.com/file',
          filename: 'file',
        );

        // Act & Assert
        expect(file.formattedSize, 'Unknown size');
      });

      test('formats fractional sizes correctly', () {
        // Arrange
        final file = MediaFile(
          id: 'media_1',
          url: 'https://example.com/file',
          filename: 'file',
          size: 245678, // ~239.9 KB
        );

        // Act & Assert
        expect(file.formattedSize, '239.9 KB');
      });
    });
  });
}
