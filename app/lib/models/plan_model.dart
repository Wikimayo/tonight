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
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      estimatedCost: json['estimatedCost'] as String,
      estimatedDuration: json['estimatedDuration'] as String,
      estimatedDistance: json['estimatedDistance'] as String,
      mood: json['mood'] as String,
      budget: json['budget'] as String,
      time: json['time'] as String,
      distance: json['distance'] as String,
      moment: json['moment'] as String,
      location: json['location'] as String,
      weather: json['weather'] as String? ?? 'Automático',
      groupSize: json['groupSize'] as String?,
      source: json['source'] as String?,
      reason: json['reason'] as String?,
      places: (json['places'] as List? ?? [])
          .map((place) => PlaceModel.fromJson(place as Map<String, dynamic>))
          .toList(),
      itinerarySteps: List<String>.from(json['itinerarySteps'] as List),
      whyItFits: json['whyItFits'] as String,
      vibe: json['vibe'] as String,
    );
  }
}
