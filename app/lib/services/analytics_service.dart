import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsService {
  const AnalyticsService();

  static FirebaseAnalytics? get _analytics {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    return FirebaseAnalytics.instance;
  }

  Future<void> logAppOpened() {
    return _logEvent('app_opened');
  }

  Future<void> logOnboardingCompleted({required String favoriteVibe}) {
    return _logEvent(
      'onboarding_completed',
      parameters: {'favorite_vibe': favoriteVibe},
    );
  }

  Future<void> logPlanGenerated({
    required String mood,
    required String budget,
    required String time,
    required String distance,
    required String moment,
    required String weather,
  }) {
    return _logEvent(
      'plan_generated',
      parameters: {
        'mood': mood,
        'budget': budget,
        'time': time,
        'distance': distance,
        'moment': moment,
        'weather': weather,
      },
    );
  }

  Future<void> logPlanSharedText({required String mood}) {
    return _logEvent('plan_shared_text', parameters: {'mood': mood});
  }

  Future<void> logPlanSharedImage({required String mood}) {
    return _logEvent('plan_shared_image', parameters: {'mood': mood});
  }

  Future<void> logPlanSavedFavorite({required String mood}) {
    return _logEvent('plan_saved_favorite', parameters: {'mood': mood});
  }

  Future<void> logLocationUsed() {
    return _logEvent('location_used');
  }

  Future<void> logWeatherAutoUsed({required String resolvedWeather}) {
    return _logEvent(
      'weather_auto_used',
      parameters: {'resolved_weather': resolvedWeather},
    );
  }

  Future<void> logSurprisePlanUsed() {
    return _logEvent('surprise_plan_used');
  }

  Future<void> logFreePlanLimitReached({required String source}) {
    return _logEvent('free_plan_limit_reached', parameters: {'source': source});
  }

  Future<void> logPremiumScreenOpened() {
    return _logEvent('premium_screen_opened');
  }

  Future<void> logPremiumPlanSelected({required String plan}) {
    return _logEvent('premium_plan_selected', parameters: {'plan': plan});
  }

  Future<void> logPremiumContinueFree() {
    return _logEvent('premium_continue_free');
  }

  Future<void> logPremiumMockEnabled() {
    return _logEvent('premium_mock_enabled');
  }

  Future<void> logPremiumMockDisabled() {
    return _logEvent('premium_mock_disabled');
  }

  Future<void> logRemainingFreePlansViewed({
    required int remainingPlans,
    required int dailyLimit,
    required bool isPremium,
    required String source,
  }) {
    return _logEvent(
      'remaining_free_plans_viewed',
      parameters: {
        'remaining_plans': remainingPlans,
        'daily_limit': dailyLimit,
        'is_premium': isPremium,
        'source': source,
      },
    );
  }

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      final analytics = _analytics;
      if (analytics == null) {
        return;
      }

      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Analytics must never block or break the core app experience.
    }
  }
}
