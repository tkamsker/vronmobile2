import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/auth/widgets/text_link.dart';

void main() {
  group('TextLink Widget', () {
    testWidgets('displays link text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextLink(
              text: 'Forgot Password?',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextLink(
              text: 'Forgot Password?',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('has minimum touch target size of 44x44', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextLink(
              text: 'Link',
              onPressed: () {},
            ),
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(TextButton));
      expect(buttonSize.width, greaterThanOrEqualTo(44.0));
      expect(buttonSize.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('displays with semantic label when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextLink(
              text: 'Forgot Password?',
              semanticLabel: 'Forgot password link',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Forgot password link'), findsOneWidget);
    });

    testWidgets('displays with default semantic label when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextLink(
              text: 'Create Account',
              onPressed: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(TextLink));
      expect(semantics.label, contains('Create Account'));
    });

    testWidgets('multiple links can be displayed together', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextLink(
                  text: 'Forgot Password?',
                  onPressed: () {},
                ),
                TextLink(
                  text: 'Create Account',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(TextLink), findsNWidgets(2));
    });

    testWidgets('each link calls its own onPressed callback', (tester) async {
      bool forgotPressed = false;
      bool createPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextLink(
                  text: 'Forgot Password?',
                  onPressed: () {
                    forgotPressed = true;
                  },
                ),
                TextLink(
                  text: 'Create Account',
                  onPressed: () {
                    createPressed = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();

      expect(forgotPressed, true);
      expect(createPressed, false);

      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(createPressed, true);
    });
  });
}
