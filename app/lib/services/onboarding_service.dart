import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  const OnboardingService._();

  static const String hasSeenOnboardingKey = 'hasSeenOnboarding';
  static const String favoriteVibeKey = 'favoriteVibe';

  static Future<bool> hasSeenOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(hasSeenOnboardingKey) ?? false;
  }

  static Future<void> markAsSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(hasSeenOnboardingKey, true);
  }

  static Future<void> saveFavoriteVibe(String vibe) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(favoriteVibeKey, vibe);
  }

  static Future<String?> getFavoriteVibe() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(favoriteVibeKey);
  }

  static Future<void> reset() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(hasSeenOnboardingKey, false);
  }
}
