import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  const UserPreferences({
    this.defaultLocation,
    this.defaultBudget,
    this.defaultTime,
    this.defaultDistance,
  });

  final String? defaultLocation;
  final String? defaultBudget;
  final String? defaultTime;
  final String? defaultDistance;
}

class UserPreferencesService {
  const UserPreferencesService._();

  static const String defaultLocationKey = 'defaultLocation';
  static const String defaultBudgetKey = 'defaultBudget';
  static const String defaultTimeKey = 'defaultTime';
  static const String defaultDistanceKey = 'defaultDistance';

  static Future<UserPreferences> getPreferences() async {
    final preferences = await SharedPreferences.getInstance();

    return UserPreferences(
      defaultLocation: preferences.getString(defaultLocationKey),
      defaultBudget: preferences.getString(defaultBudgetKey),
      defaultTime: preferences.getString(defaultTimeKey),
      defaultDistance: preferences.getString(defaultDistanceKey),
    );
  }

  static Future<void> saveDefaultLocation(String location) async {
    final preferences = await SharedPreferences.getInstance();
    final trimmedLocation = location.trim();

    if (trimmedLocation.isEmpty) {
      await preferences.remove(defaultLocationKey);
      return;
    }

    await preferences.setString(defaultLocationKey, trimmedLocation);
  }

  static Future<void> saveDefaultBudget(String budget) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(defaultBudgetKey, budget);
  }

  static Future<void> saveDefaultTime(String time) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(defaultTimeKey, time);
  }

  static Future<void> saveDefaultDistance(String distance) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(defaultDistanceKey, distance);
  }
}
