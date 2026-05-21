import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  const LanguageService._();

  static const String languageKey = 'selectedLanguage';
  static const String spanish = 'es';
  static const String english = 'en';
  static const List<String> supportedLanguages = [spanish, english];

  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>(
    spanish,
  );

  static String get currentLanguage => languageNotifier.value;

  static Future<String> getCurrentLanguageCode() {
    return getLanguage();
  }

  static Future<String> getLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(languageKey);
    final language = _normalizedLanguage(savedLanguage);
    languageNotifier.value = language;
    return language;
  }

  static Future<void> setLanguage(String languageCode) async {
    final language = _normalizedLanguage(languageCode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(languageKey, language);
    languageNotifier.value = language;
  }

  static String _normalizedLanguage(String? languageCode) {
    final normalized = languageCode?.trim().toLowerCase();
    if (normalized != null && supportedLanguages.contains(normalized)) {
      return normalized;
    }

    return spanish;
  }
}
