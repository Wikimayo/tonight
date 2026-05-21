import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/plan_model.dart';
import 'language_service.dart';
import 'mock_plan_generator.dart';

class ChatPlanResult {
  const ChatPlanResult({required this.plan, required this.usedFallback});

  final PlanModel plan;
  final bool usedFallback;
}

class ChatPlanService {
  const ChatPlanService();

  static const Duration requestTimeout = Duration(seconds: 12);
  static Future<ChatPlanResult> Function(String message)?
  debugGeneratePlanFromMessage;

  Future<ChatPlanResult> generatePlanFromMessage(String message) async {
    final trimmedMessage = message.trim();
    final debugGenerator = debugGeneratePlanFromMessage;
    if (debugGenerator != null) {
      return debugGenerator(trimmedMessage);
    }

    if (trimmedMessage.isEmpty) {
      return _fallbackPlan(reason: 'Empty chat message');
    }

    final language = await LanguageService.getCurrentLanguageCode();

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/generate-plan-from-chat'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'message': trimmedMessage, 'language': language}),
          )
          .timeout(requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackPlan(
          reason: 'Backend returned ${response.statusCode}: ${response.body}',
        );
      }

      final decodedBody = jsonDecode(response.body);
      if (decodedBody is! Map<String, dynamic>) {
        return _fallbackPlan(reason: 'Backend response is not a JSON object');
      }

      final planJson = decodedBody['plan'];
      final planBody = Map<String, dynamic>.from(
        planJson is Map<String, dynamic> ? planJson : decodedBody,
      );
      planBody['source'] ??= decodedBody['source'] ?? 'ai';
      planBody['reason'] ??= decodedBody['reason'];

      return ChatPlanResult(
        plan: PlanModel.fromJson(planBody),
        usedFallback: planBody['source'] == 'mock',
      );
    } catch (error, stackTrace) {
      return _fallbackPlan(
        reason: 'Backend chat call failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  ChatPlanResult _fallbackPlan({
    required String reason,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      developer.log(
        '$reason. Using MockPlanGenerator fallback.',
        name: 'ChatPlanService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return ChatPlanResult(
      usedFallback: true,
      plan: MockPlanGenerator.generate(
        mood: 'Sorpresa',
        budget: '€€',
        time: '2h',
        distance: 'Media',
        moment: 'Ahora',
        location: 'tu zona',
        weather: 'Automático',
        reason: reason,
      ),
    );
  }
}
