import '../utils/text_sanitizer.dart';

class PlaceModel {
  const PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.moodTags,
    required this.weatherTags,
    required this.priceLevel,
    required this.description,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String category;
  final String location;
  final List<String> moodTags;
  final List<String> weatherTags;
  final String priceLevel;
  final String description;
  final String? address;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'location': location,
      'moodTags': moodTags,
      'weatherTags': weatherTags,
      'priceLevel': priceLevel,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: TextSanitizer.clean(json['id'] as String),
      name: TextSanitizer.clean(json['name'] as String),
      category: TextSanitizer.clean(json['category'] as String),
      location: TextSanitizer.clean(json['location'] as String),
      moodTags: List<String>.from(
        (json['moodTags'] as List).map((tag) => TextSanitizer.clean('$tag')),
      ),
      weatherTags: List<String>.from(
        (json['weatherTags'] as List).map((tag) => TextSanitizer.clean('$tag')),
      ),
      priceLevel: TextSanitizer.clean(json['priceLevel'] as String),
      description: TextSanitizer.clean(json['description'] as String),
      address: TextSanitizer.cleanOptional(json['address']?.toString()),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
