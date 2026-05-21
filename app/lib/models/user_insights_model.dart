class UserInsightsModel {
  const UserInsightsModel({
    required this.mood,
    required this.location,
    required this.weather,
    required this.budget,
    required this.moment,
    required this.time,
    required this.distance,
    this.groupSize,
    required this.planCount,
  });

  final String mood;
  final String location;
  final String weather;
  final String budget;
  final String moment;
  final String time;
  final String distance;
  final String? groupSize;
  final int planCount;

  List<String> get highlights {
    return [
      'Últimamente te van los planes $mood',
      'Sueles buscar planes por $location',
      'Tu momento favorito parece ser ${moment.toLowerCase()}',
    ];
  }
}
