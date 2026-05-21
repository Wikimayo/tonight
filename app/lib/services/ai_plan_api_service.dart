import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/plan_model.dart';
import 'mock_plan_generator.dart';

// No guardar API keys en Flutter.
// OpenAI se conectará desde backend.
// Para móvil físico usar la IP local del PC, por ejemplo http://192.168.1.X:3000
class AiPlanApiService {
  const AiPlanApiService();

  static const Duration requestTimeout = Duration(seconds: 10);

  Future<PlanModel> generatePlan({
    required String mood,
    required String budget,
    required String time,
    required String distance,
    required String moment,
    required String location,
    required String weather,
    required String language,
    String? groupSize,
  }) async {
    final requestBody = <String, dynamic>{
      'mood': mood,
      'budget': budget,
      'time': time,
      'distance': distance,
      'moment': moment,
      'location': location,
      'weather': weather,
      'groupSize': groupSize,
      'language': language,
    };

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/generate-plan'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackPlan(
          reason: 'Backend returned ${response.statusCode}: ${response.body}',
          mood: mood,
          budget: budget,
          time: time,
          distance: distance,
          moment: moment,
          location: location,
          weather: weather,
          groupSize: groupSize,
        );
      }

      final decodedBody = jsonDecode(response.body);
      if (decodedBody is! Map<String, dynamic>) {
        return _fallbackPlan(
          reason: 'Backend response is not a JSON object',
          mood: mood,
          budget: budget,
          time: time,
          distance: distance,
          moment: moment,
          location: location,
          weather: weather,
          groupSize: groupSize,
        );
      }

      final planJson = decodedBody['plan'];
      final planBody = Map<String, dynamic>.from(
        planJson is Map<String, dynamic> ? planJson : decodedBody,
      );
      planBody['source'] ??= decodedBody['source'] ?? 'ai';
      planBody['reason'] ??= decodedBody['reason'];
      return PlanModel.fromJson(planBody);
    } catch (error, stackTrace) {
      return _fallbackPlan(
        reason: 'Backend call failed',
        error: error,
        stackTrace: stackTrace,
        mood: mood,
        budget: budget,
        time: time,
        distance: distance,
        moment: moment,
        location: location,
        weather: weather,
        groupSize: groupSize,
      );
    }
  }

  PlanModel _fallbackPlan({
    required String reason,
    required String mood,
    required String budget,
    required String time,
    required String distance,
    required String moment,
    required String location,
    required String weather,
    String? groupSize,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      developer.log(
        '$reason. Using MockPlanGenerator fallback.',
        name: 'AiPlanApiService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return MockPlanGenerator.generate(
      mood: mood,
      budget: budget,
      time: time,
      distance: distance,
      moment: moment,
      location: location,
      weather: weather,
      groupSize: groupSize,
      reason: reason,
    );
  }
}
