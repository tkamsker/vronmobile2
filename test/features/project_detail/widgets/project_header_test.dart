import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/project_detail/widgets/project_header.dart';

void main() {
  group('ProjectHeader Widget Tests', () {
    testWidgets('displays project image when imageUrl is provided', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testImageUrl = 'https://example.com/image.jpg';
      const testName = 'Test Project';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectHeader(
              imageUrl: testImageUrl,
              name: testName,
              isLive: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('displays project name', (WidgetTester tester) async {
      // Arrange
      const testName = 'Test Project Name';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectHeader(imageUrl: null, name: testName, isLive: false),
          ),
        ),
      );

      // Assert
      expect(find.text(testName), findsOneWidget);
    });

    testWidgets('displays live status badge when isLive is true', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectHeader(
              imageUrl: null,
              name: 'Test Project',
              isLive: true,
            ),
          ),
        ),
      );

      // Assert
      // The badge should contain "Live" text
      expect(find.textContaining('Live'), findsOneWidget);
    });

    testWidgets('does not display live badge when isLive is false', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectHeader(
              imageUrl: null,
              name: 'Test Project',
              isLive: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Live'), findsNothing);
    });

    testWidgets('displays placeholder when imageUrl is null', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectHeader(
              imageUrl: null,
              name: 'Test Project',
              isLive: false,
            ),
          ),
        ),
      );

      // Assert
      // Should have an Icon or Container as placeholder
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
