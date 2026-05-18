import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan_model.dart';

class LocalPlanStorage {
  const LocalPlanStorage._();

  static const String _historyKey = 'tonight_history';
  static const String _favoritesKey = 'tonight_favorites';

  static Future<void> addToHistory(PlanModel plan) async {
    final history = await getHistory();
    final nextHistory = [
      plan,
      ...history.where((savedPlan) => savedPlan.id != plan.id),
    ];
    await _savePlans(_historyKey, nextHistory);
  }

  static Future<void> addToFavorites(PlanModel plan) async {
    final favorites = await getFavorites();
    final alreadySaved = favorites.any((savedPlan) => savedPlan.id == plan.id);
    if (alreadySaved) {
      return;
    }

    await _savePlans(_favoritesKey, [plan, ...favorites]);
  }

  static Future<List<PlanModel>> getHistory() {
    return _loadPlans(_historyKey);
  }

  static Future<List<PlanModel>> getFavorites() {
    return _loadPlans(_favoritesKey);
  }

  static Future<void> clearHistory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_historyKey);
  }

  static Future<void> clearFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_favoritesKey);
  }

  static Future<void> clear() async {
    await Future.wait([clearHistory(), clearFavorites()]);
  }

  static Future<bool> isFavorite(PlanModel plan) async {
    final favorites = await getFavorites();
    return favorites.any((savedPlan) => savedPlan.id == plan.id);
  }

  static Future<List<PlanModel>> _loadPlans(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedPlans = preferences.getStringList(key) ?? [];

    return encodedPlans.map((encodedPlan) {
      final json = jsonDecode(encodedPlan) as Map<String, dynamic>;
      return PlanModel.fromJson(json);
    }).toList();
  }

  static Future<void> _savePlans(String key, List<PlanModel> plans) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedPlans = plans.map((plan) {
      return jsonEncode(plan.toJson());
    }).toList();

    await preferences.setStringList(key, encodedPlans);
  }
}
