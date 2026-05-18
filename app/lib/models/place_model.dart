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
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      location: json['location'] as String,
      moodTags: List<String>.from(json['moodTags'] as List),
      weatherTags: List<String>.from(json['weatherTags'] as List),
      priceLevel: json['priceLevel'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
