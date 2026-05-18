import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  const PremiumService._();

  static const String monthlyPlan = 'monthly';
  static const String annualPlan = 'annual';

  static const String _isPremiumKey = 'premiumMockEnabled';
  static const String _selectedPlanKey = 'premiumSelectedPlan';

  static Future<bool> isPremium() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_isPremiumKey) ?? false;
  }

  static Future<void> setPremiumMock(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_isPremiumKey, value);
  }

  static Future<String> getSelectedPlan() async {
    final preferences = await SharedPreferences.getInstance();
    final selectedPlan = preferences.getString(_selectedPlanKey);
    if (selectedPlan == annualPlan || selectedPlan == monthlyPlan) {
      return selectedPlan!;
    }

    return annualPlan;
  }

  static Future<void> setSelectedPlan(String plan) async {
    if (plan != monthlyPlan && plan != annualPlan) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_selectedPlanKey, plan);
  }
}
