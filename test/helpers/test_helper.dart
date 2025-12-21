import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';

/// Initialize i18n service for tests
Future<void> initializeI18nForTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up SharedPreferences with default language
  SharedPreferences.setMockInitialValues({
    'language_code': 'en',
  });

  // Initialize i18n service
  await I18nService().initialize();
}

/// Create a test MaterialApp wrapper with i18n initialized
/// Use this in widget tests to ensure translations work
Future<void> pumpWithI18n(
  WidgetTester tester,
  Widget widget, {
  bool initializeI18n = true,
}) async {
  if (initializeI18n) {
    await initializeI18nForTest();
  }
  await tester.pumpWidget(widget);
}
