import '../models/plan_model.dart';
import 'ai_plan_api_service.dart';
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
  }) async {
    if (useAiBackend) {
      return const AiPlanApiService().generatePlan(
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

    return MockPlanGenerator.generate(
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
