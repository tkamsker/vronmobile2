import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing internationalization (i18n) and translations
class I18nService extends ChangeNotifier {
  static final I18nService _instance = I18nService._internal();
  factory I18nService() => _instance;
  I18nService._internal();

  // Supported languages
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'de', 'pt'];

  // Current language
  String _currentLanguage = defaultLanguage;
  String get currentLanguage => _currentLanguage;

  // Loaded translations
  Map<String, dynamic> _translations = {};

  // Preferences key
  static const String _languagePreferenceKey = 'app_language';

  /// Initialize i18n service and load saved language preference
  Future<void> initialize() async {
    if (kDebugMode) print('🌍 [I18N] Initializing i18n service...');

    // Load saved language preference
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languagePreferenceKey);

    if (savedLanguage != null && supportedLanguages.contains(savedLanguage)) {
      _currentLanguage = savedLanguage;
      if (kDebugMode) {
        print('🌍 [I18N] Loaded saved language: $_currentLanguage');
      }
    } else {
      if (kDebugMode) {
        print('🌍 [I18N] Using default language: $_currentLanguage');
      }
    }

    // Load translations for current language
    await _loadTranslations(_currentLanguage);

    if (kDebugMode) {
      print('✅ [I18N] Initialized with language: $_currentLanguage');
    }
  }

  /// Load translations from JSON file
  Future<void> _loadTranslations(String languageCode) async {
    try {
      if (kDebugMode) {
        print('🌍 [I18N] Loading translations for: $languageCode');
      }

      final String jsonString = await rootBundle.loadString(
        'lib/core/i18n/$languageCode.json',
      );
      _translations = json.decode(jsonString) as Map<String, dynamic>;

      if (kDebugMode) {
        print('✅ [I18N] Loaded translations for: $languageCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [I18N] Error loading translations for $languageCode: $e');
      }

      // Fallback to English if translation file not found
      if (languageCode != defaultLanguage) {
        if (kDebugMode) {
          print('🌍 [I18N] Falling back to default language: $defaultLanguage');
        }
        await _loadTranslations(defaultLanguage);
      }
    }
  }

  /// Change current language
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.contains(languageCode)) {
      if (kDebugMode) {
        print('⚠️ [I18N] Unsupported language: $languageCode');
      }
      return;
    }

    if (_currentLanguage == languageCode) {
      if (kDebugMode) print('🌍 [I18N] Language already set to: $languageCode');
      return;
    }

    if (kDebugMode) {
      print(
        '🌍 [I18N] Changing language from $_currentLanguage to $languageCode',
      );
    }

    _currentLanguage = languageCode;

    // Load new translations
    await _loadTranslations(languageCode);

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePreferenceKey, languageCode);

    // Notify listeners to rebuild UI
    notifyListeners();

    if (kDebugMode) print('✅ [I18N] Language changed to: $languageCode');
  }

  /// Get translated text by key path (e.g., "home.title", "navigation.home")
  String translate(String keyPath, {Map<String, dynamic>? params}) {
    // Split key path by dots
    final keys = keyPath.split('.');

    // Navigate through translation map
    dynamic current = _translations;
    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        // Key not found, return key path as fallback
        if (kDebugMode) {
          print('⚠️ [I18N] Translation not found for key: $keyPath');
        }
        return keyPath;
      }
    }

    // If final value is not a string, return key path
    if (current is! String) {
      if (kDebugMode) {
        print('⚠️ [I18N] Translation value is not a string for key: $keyPath');
      }
      return keyPath;
    }

    // Replace parameters in translation string
    String translated = current;
    if (params != null) {
      params.forEach((key, value) {
        translated = translated.replaceAll('{$key}', value.toString());
      });
    }

    return translated;
  }

  /// Get language name by code
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English (US)';
      case 'de':
        return 'Deutsch';
      case 'pt':
        return 'Português';
      default:
        return languageCode;
    }
  }

  /// Get language flag emoji by code
  String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'de':
        return '🇩🇪';
      case 'pt':
        return '🇵🇹';
      default:
        return '🌍';
    }
  }
}

/// Extension to easily access translations in widgets
extension I18nExtension on String {
  /// Translate this string as a key path
  String tr({Map<String, dynamic>? params}) {
    return I18nService().translate(this, params: params);
  }
}
