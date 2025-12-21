import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// I18n service for managing translations
class I18nService extends ChangeNotifier {
  static final I18nService _instance = I18nService._internal();
  factory I18nService() => _instance;
  I18nService._internal();

  Map<String, dynamic> _translations = {};
  String _currentLanguage = 'en';
  static const String _languageKey = 'selected_language';

  /// Get current language code
  String get currentLanguage => _currentLanguage;

  /// Get available languages
  List<String> get availableLanguages => ['en', 'de', 'pt'];

  /// Get language name for display
  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'pt':
        return 'Português';
      default:
        return code;
    }
  }

  /// Get language flag emoji
  String getLanguageFlag(String code) {
    switch (code) {
      case 'en':
        return '🇬🇧';
      case 'de':
        return '🇩🇪';
      case 'pt':
        return '🇵🇹';
      default:
        return '🌐';
    }
  }

  /// Initialize i18n service - load saved language preference and translations
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_languageKey) ?? 'en';
      await _loadTranslations(_currentLanguage);
    } catch (e) {
      debugPrint('Error initializing i18n: $e');
      // Fallback to English if there's an error
      _currentLanguage = 'en';
      await _loadTranslations('en');
    }
  }

  /// Load translations from JSON file
  Future<void> _loadTranslations(String languageCode) async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/core/i18n/$languageCode.json');
      _translations = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading translations for $languageCode: $e');
      _translations = {};
    }
  }

  /// Change current language
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;

    try {
      await _loadTranslations(languageCode);
      _currentLanguage = languageCode;

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      // Notify listeners to rebuild UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error changing language to $languageCode: $e');
    }
  }

  /// Get translation for a key with optional parameters
  /// Example: translate('projectDetail.lastUpdated', {'date': '2023-12-21'})
  String translate(String key, [Map<String, String>? params]) {
    // Split key by dots to navigate nested structure
    final keys = key.split('.');
    dynamic value = _translations;

    // Navigate through nested structure
    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        // Key not found, return the key itself as fallback
        debugPrint('Translation key not found: $key');
        return key;
      }
    }

    // If value is not a string, return the key
    if (value is! String) {
      debugPrint('Translation value is not a string for key: $key');
      return key;
    }

    // Replace parameters if provided
    String result = value;
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        result = result.replaceAll('{$paramKey}', paramValue);
      });
    }

    return result;
  }
}

/// Extension method for easy translation access
/// Usage: 'projectDetail.title'.tr()
extension StringTranslation on String {
  String tr([Map<String, String>? params]) {
    return I18nService().translate(this, params);
  }
}
