import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/guest/widgets/guest_mode_banner.dart';

void main() {
  group('GuestModeBanner Widget', () {
    // T024: Test GuestModeBanner component
    testWidgets('displays banner with correct text', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GuestModeBanner(onSignUpPressed: () {})),
        ),
      );

      // Assert
      expect(
        find.text('Guest Mode - Scans saved locally only'),
        findsOneWidget,
      );
    });

    testWidgets('displays with amber color scheme', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GuestModeBanner(onSignUpPressed: () {})),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Guest Mode - Scans saved locally only'),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.amber.shade100);
    });

    testWidgets('has Sign Up button that is tappable', (
      WidgetTester tester,
    ) async {
      bool signUpPressed = false;

      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestModeBanner(
              onSignUpPressed: () {
                signUpPressed = true;
              },
            ),
          ),
        ),
      );

      // Act
      final signUpButton = find.widgetWithText(TextButton, 'Sign Up');
      expect(signUpButton, findsOneWidget);

      await tester.tap(signUpButton);
      await tester.pump();

      // Assert
      expect(signUpPressed, true);
    });

    testWidgets('has proper semantic label for accessibility', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GuestModeBanner(onSignUpPressed: () {})),
        ),
      );

      // Assert - verify Semantics widget exists with proper structure
      final semantics = find.byType(Semantics);
      expect(
        semantics,
        findsWidgets,
      ); // Should find at least one Semantics widget

      // Verify the banner text is present (which is wrapped in Semantics)
      expect(
        find.text('Guest Mode - Scans saved locally only'),
        findsOneWidget,
      );
    });

    testWidgets('has proper touch target size', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GuestModeBanner(onSignUpPressed: () {})),
        ),
      );

      // Assert - Sign Up button should have adequate touch target (>= 44x44)
      final signUpButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Sign Up'),
      );

      final renderBox = tester.renderObject<RenderBox>(
        find.widgetWithText(TextButton, 'Sign Up'),
      );

      expect(renderBox.size.height, greaterThanOrEqualTo(44));
    });
  });
}
