import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/auth/widgets/oauth_button.dart';

void main() {
  group('OAuthButton Widget - Google variant', () {
    testWidgets('displays Google sign-in text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () {
                wasPressed = true;
              },
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('has accessible semantic label for Google', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Sign in with Google button'), findsOneWidget);
    });
  });

  group('OAuthButton Widget - Facebook variant', () {
    testWidgets('displays Facebook sign-in text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OAuthButton(
              provider: OAuthProvider.facebook,
              onPressed: () {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('Sign in with Facebook'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OAuthButton(
              provider: OAuthProvider.facebook,
              onPressed: () {
                wasPressed = true;
              },
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('has accessible semantic label for Facebook', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OAuthButton(
              provider: OAuthProvider.facebook,
              onPressed: () {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Sign in with Facebook button'), findsOneWidget);
    });
  });

  group('OAuthButton Widget - Common behavior', () {
    testWidgets('is disabled when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('has minimum height of 48 pixels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () {},
              isLoading: false,
            ),
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(ElevatedButton));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));
    });
  });
}
