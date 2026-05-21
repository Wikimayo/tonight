import 'package:shared_preferences/shared_preferences.dart';

import 'premium_service.dart';

class UsageLimitsService {
  const UsageLimitsService._();

  static const int freeDailyPlanLimit = 2;
  static const String _usageDateKey = 'usageLimitsDate';
  static const String _usageCountKey = 'usageLimitsPlanCount';

  static DateTime Function()? debugNowProvider;

  static int getDailyLimit() {
    return freeDailyPlanLimit;
  }

  static Future<bool> canGeneratePlan() async {
    if (await PremiumService.isPremium()) {
      return true;
    }

    return (await getTodayUsage()) < freeDailyPlanLimit;
  }

  static Future<int> getRemainingPlansToday() async {
    final usedToday = await getTodayUsage();
    final remaining = getDailyLimit() - usedToday;
    return remaining < 0 ? 0 : remaining;
  }

  static Future<int> getTodayUsage() async {
    final preferences = await SharedPreferences.getInstance();
    await _resetIfNeeded(preferences);
    return preferences.getInt(_usageCountKey) ?? 0;
  }

  static Future<int> getRemainingPlans() async {
    return getRemainingPlansToday();
  }

  static Future<void> registerPlanGenerated() async {
    if (await PremiumService.isPremium()) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await _resetIfNeeded(preferences);
    final currentCount = preferences.getInt(_usageCountKey) ?? 0;
    await preferences.setInt(_usageCountKey, currentCount + 1);
  }

  static Future<void> resetUsage() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_usageDateKey, _todayKey);
    await preferences.setInt(_usageCountKey, 0);
  }

  static Future<void> _resetIfNeeded(SharedPreferences preferences) async {
    final savedDate = preferences.getString(_usageDateKey);
    if (savedDate == _todayKey) {
      return;
    }

    await preferences.setString(_usageDateKey, _todayKey);
    await preferences.setInt(_usageCountKey, 0);
  }

  static String get _todayKey {
    final now = debugNowProvider?.call() ?? DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
