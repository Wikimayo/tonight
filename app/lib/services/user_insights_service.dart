import '../models/plan_model.dart';
import '../models/user_insights_model.dart';
import '../utils/text_sanitizer.dart';
import 'local_plan_storage.dart';
import 'weather_service.dart';

class UserInsightsService {
  const UserInsightsService._();

  static const int minimumPlansForInsights = 2;

  static Future<UserInsightsModel?> getInsights() async {
    final results = await Future.wait([
      LocalPlanStorage.getHistory(),
      LocalPlanStorage.getFavorites(),
    ]);
    final plans = _uniquePlans([...results[0], ...results[1]]);

    if (plans.length < minimumPlansForInsights) {
      return null;
    }

    return UserInsightsModel(
      mood: _mostCommon(plans.map((plan) => plan.mood), fallback: 'Chill'),
      location: _mostCommon(
        plans.map((plan) => plan.location),
        fallback: 'tu zona',
      ),
      weather: _mostCommon(
        plans.map((plan) => plan.weather),
        fallback: WeatherService.automaticWeather,
      ),
      budget: _mostCommon(plans.map((plan) => plan.budget), fallback: '€€'),
      moment: _mostCommon(plans.map((plan) => plan.moment), fallback: 'Ahora'),
      time: _mostCommon(plans.map((plan) => plan.time), fallback: '2h'),
      distance: _mostCommon(
        plans.map((plan) => plan.distance),
        fallback: 'Media',
      ),
      groupSize: _mostCommonOptional(plans.map((plan) => plan.groupSize)),
      planCount: plans.length,
    );
  }

  static List<PlanModel> _uniquePlans(List<PlanModel> plans) {
    final byId = <String, PlanModel>{};
    for (final plan in plans) {
      byId.putIfAbsent(plan.id, () => plan);
    }

    return byId.values.toList();
  }

  static String _mostCommon(
    Iterable<String> values, {
    required String fallback,
  }) {
    return _mostCommonOptional(values) ?? fallback;
  }

  static String? _mostCommonOptional(Iterable<String?> values) {
    final counts = <String, int>{};

    for (final value in values) {
      final cleanValue = TextSanitizer.cleanOptional(value);
      if (cleanValue == null) {
        continue;
      }

      counts[cleanValue] = (counts[cleanValue] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return null;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((first, second) {
        final countComparison = second.value.compareTo(first.value);
        if (countComparison != 0) {
          return countComparison;
        }

        return first.key.compareTo(second.key);
      });

    return sortedEntries.first.key;
  }
}
