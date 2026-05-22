import 'dart:async';
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

  static const Duration requestTimeout = Duration(seconds: 25);

  Future<bool> testHealth() async {
    final healthUrl = Uri.parse('${ApiConfig.baseUrl}/health');

    try {
      if (kDebugMode) {
        developer.log('GET $healthUrl', name: 'AiPlanApiService');
      }

      final response = await http.get(healthUrl).timeout(requestTimeout);
      if (kDebugMode) {
        developer.log(
          'health statusCode=${response.statusCode}',
          name: 'AiPlanApiService',
        );
        if (response.statusCode != 200) {
          developer.log(
            'health error body=${response.body}',
            name: 'AiPlanApiService',
          );
        }
      }

      if (response.statusCode != 200) {
        return false;
      }

      final decodedBody = jsonDecode(response.body);
      return decodedBody is Map<String, dynamic> &&
          decodedBody['status'] == 'ok';
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        developer.log(
          'Health check failed',
          name: 'AiPlanApiService',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return false;
    }
  }

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
    required String requestId,
    required int randomSeed,
    List<String> avoidSimilarTo = const [],
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
      'requestId': requestId,
      'randomSeed': randomSeed,
      'avoidSimilarTo': avoidSimilarTo,
    };

    final generatePlanUrl = Uri.parse('${ApiConfig.baseUrl}/generate-plan');

    try {
      if (kDebugMode) {
        developer.log('POST $generatePlanUrl', name: 'AiPlanApiService');
        developer.log(
          'request body keys=${requestBody.keys.join(', ')}',
          name: 'AiPlanApiService',
        );
      }

      final response = await http
          .post(
            generatePlanUrl,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(requestTimeout);

      if (kDebugMode) {
        developer.log(
          'statusCode=${response.statusCode}',
          name: 'AiPlanApiService',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          developer.log(
            'error body=${response.body}',
            name: 'AiPlanApiService',
          );
        }
        return _fallbackPlan(
          reason: 'non_200_status',
          mood: mood,
          budget: budget,
          time: time,
          distance: distance,
          moment: moment,
          location: location,
          weather: weather,
          groupSize: groupSize,
          requestId: requestId,
        );
      }

      final Object? decodedBody;
      try {
        decodedBody = jsonDecode(response.body);
      } on FormatException catch (error, stackTrace) {
        return _fallbackPlan(
          reason: 'invalid_json',
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
          requestId: requestId,
        );
      }

      if (decodedBody is! Map<String, dynamic>) {
        return _fallbackPlan(
          reason: 'invalid_json',
          mood: mood,
          budget: budget,
          time: time,
          distance: distance,
          moment: moment,
          location: location,
          weather: weather,
          groupSize: groupSize,
          requestId: requestId,
        );
      }

      final planJson = decodedBody['plan'];
      final planBody = Map<String, dynamic>.from(
        planJson is Map<String, dynamic> ? planJson : decodedBody,
      );
      planBody['source'] ??= decodedBody['source'] ?? 'ai';
      planBody['reason'] ??= decodedBody['reason'];
      planBody['requestId'] ??= decodedBody['requestId'] ?? requestId;
      if (kDebugMode && planBody['source'] == 'mock') {
        developer.log(
          'Backend returned mock fallback'
          '${planBody['reason'] == null ? '' : ' reason=${planBody['reason']}'}'
          ' requestId=${planBody['requestId']}',
          name: 'AiPlanApiService',
        );
      }
      try {
        return PlanModel.fromJson(planBody);
      } on Object catch (error, stackTrace) {
        return _fallbackPlan(
          reason: 'invalid_json',
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
          requestId: requestId,
        );
      }
    } on TimeoutException catch (error, stackTrace) {
      return _fallbackPlan(
        reason: 'timeout',
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
        requestId: requestId,
      );
    } on http.ClientException catch (error, stackTrace) {
      return _fallbackPlan(
        reason: 'network_error',
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
        requestId: requestId,
      );
    } catch (error, stackTrace) {
      return _fallbackPlan(
        reason: _reasonForUnexpectedError(error),
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
        requestId: requestId,
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
    String? requestId,
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
      requestId: requestId,
    );
  }

  String _reasonForUnexpectedError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network') ||
        message.contains('xmlhttprequest')) {
      return 'network_error';
    }

    return 'backend_call_failed';
  }
}
