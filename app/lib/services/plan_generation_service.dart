import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants/api_config.dart';
import '../models/plan_model.dart';
import 'ai_plan_api_service.dart';
import 'language_service.dart';
import 'mock_plan_generator.dart';

class PlanGenerationService {
  const PlanGenerationService({this.useAiBackend = true});

  // No guardar API keys en Flutter.
  // OpenAI se conectará desde backend.
  final bool useAiBackend;

  Future<PlanModel> generatePlan({
    required String mood,
    required String budget,
    required String time,
    required String distance,
    required String moment,
    required String location,
    String weather = 'Automático',
    String? groupSize,
    List<String> avoidSimilarTo = const [],
  }) async {
    final language = await LanguageService.getCurrentLanguageCode();
    final requestId = _newRequestId();
    final randomSeed = Random().nextInt(1 << 32);

    if (useAiBackend) {
      if (kDebugMode) {
        developer.log(
          'useAiBackend=true useProductionBackend='
          '${ApiConfig.useProductionBackend} baseUrl=${ApiConfig.baseUrl}',
          name: 'PlanGenerationService',
        );
      }

      final plan = await const AiPlanApiService().generatePlan(
        mood: mood,
        budget: budget,
        time: time,
        distance: distance,
        moment: moment,
        location: location,
        weather: weather,
        groupSize: groupSize,
        language: language,
        requestId: requestId,
        randomSeed: randomSeed,
        avoidSimilarTo: avoidSimilarTo,
      );
      _logPlanSource(plan);
      return plan;
    }

    final plan = MockPlanGenerator.generate(
      mood: mood,
      budget: budget,
      time: time,
      distance: distance,
      moment: moment,
      location: location,
      weather: weather,
      groupSize: groupSize,
      reason: 'useAiBackend_disabled',
      requestId: requestId,
    );
    _logPlanSource(plan);
    return plan;
  }

  String _newRequestId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'tonight-$micros-$suffix';
  }

  void _logPlanSource(PlanModel plan) {
    if (!kDebugMode) {
      return;
    }

    developer.log(
      'result source=${plan.source ?? 'unknown'}'
      '${plan.reason == null ? '' : ' reason=${plan.reason}'}'
      '${plan.requestId == null ? '' : ' requestId=${plan.requestId}'}',
      name: 'PlanGenerationService',
    );
  }
}
