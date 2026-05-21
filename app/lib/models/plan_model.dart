import '../utils/text_sanitizer.dart';
import 'place_model.dart';

class PlanModel {
  const PlanModel({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.estimatedCost,
    required this.estimatedDuration,
    required this.estimatedDistance,
    required this.mood,
    required this.budget,
    required this.time,
    required this.distance,
    required this.moment,
    required this.location,
    this.weather = 'Automático',
    this.groupSize,
    this.source,
    this.reason,
    this.places = const [],
    required this.itinerarySteps,
    required this.whyItFits,
    required this.vibe,
  });

  final String id;
  final DateTime createdAt;
  final String title;
  final String description;
  final String estimatedCost;
  final String estimatedDuration;
  final String estimatedDistance;
  final String mood;
  final String budget;
  final String time;
  final String distance;
  final String moment;
  final String location;
  final String weather;
  final String? groupSize;
  final String? source;
  final String? reason;
  final List<PlaceModel> places;
  final List<String> itinerarySteps;
  final String whyItFits;
  final String vibe;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'description': description,
      'estimatedCost': estimatedCost,
      'estimatedDuration': estimatedDuration,
      'estimatedDistance': estimatedDistance,
      'mood': mood,
      'budget': budget,
      'time': time,
      'distance': distance,
      'moment': moment,
      'location': location,
      'weather': weather,
      'groupSize': groupSize,
      'source': source,
      'reason': reason,
      'places': places.map((place) => place.toJson()).toList(),
      'itinerarySteps': itinerarySteps,
      'whyItFits': whyItFits,
      'vibe': vibe,
    };
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: TextSanitizer.clean(json['id'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: TextSanitizer.clean(json['title'] as String),
      description: TextSanitizer.clean(json['description'] as String),
      estimatedCost: TextSanitizer.clean(json['estimatedCost'] as String),
      estimatedDuration: TextSanitizer.clean(
        json['estimatedDuration'] as String,
      ),
      estimatedDistance: TextSanitizer.clean(
        json['estimatedDistance'] as String,
      ),
      mood: TextSanitizer.clean(json['mood'] as String),
      budget: TextSanitizer.clean(json['budget'] as String),
      time: TextSanitizer.clean(json['time'] as String),
      distance: TextSanitizer.clean(json['distance'] as String),
      moment: TextSanitizer.clean(json['moment'] as String),
      location: TextSanitizer.clean(json['location'] as String),
      weather: TextSanitizer.clean(json['weather'] as String? ?? 'Automático'),
      groupSize: TextSanitizer.cleanOptional(json['groupSize']?.toString()),
      source: TextSanitizer.cleanOptional(json['source']?.toString()),
      reason: TextSanitizer.cleanOptional(json['reason']?.toString()),
      places: (json['places'] as List? ?? [])
          .map((place) => PlaceModel.fromJson(place as Map<String, dynamic>))
          .toList(),
      itinerarySteps: List<String>.from(
        (json['itinerarySteps'] as List).map(
          (step) => TextSanitizer.clean('$step'),
        ),
      ),
      whyItFits: TextSanitizer.clean(json['whyItFits'] as String),
      vibe: TextSanitizer.clean(json['vibe'] as String),
    );
  }
}
