import 'dart:convert';

import 'package:http/http.dart' as http;

import 'location_service.dart';

class WeatherService {
  const WeatherService._();

  static const String automaticWeather = 'Automático';
  static const Duration requestTimeout = Duration(seconds: 6);
  static Future<String> Function()? debugAutomaticWeatherResolver;

  static Future<String> getAutomaticWeather() async {
    final debugResolver = debugAutomaticWeatherResolver;
    if (debugResolver != null) {
      return debugResolver();
    }

    try {
      final position = await LocationService.getCurrentPosition();
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': position.latitude.toStringAsFixed(5),
        'longitude': position.longitude.toStringAsFixed(5),
        'current': 'temperature_2m,weather_code',
        'timezone': 'auto',
      });

      final response = await http.get(uri).timeout(requestTimeout);
      if (response.statusCode != 200) {
        return automaticWeather;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) {
        return automaticWeather;
      }

      final temperature = (current['temperature_2m'] as num?)?.toDouble();
      final weatherCode = (current['weather_code'] as num?)?.toInt();
      if (temperature == null || weatherCode == null) {
        return automaticWeather;
      }

      return labelFromWeather(
        weatherCode: weatherCode,
        temperature: temperature,
      );
    } catch (_) {
      return automaticWeather;
    }
  }

  static String labelFromWeather({
    required int weatherCode,
    required double temperature,
  }) {
    if (_isRainCode(weatherCode)) {
      return 'Lluvia';
    }

    if (_isSnowCode(weatherCode) || temperature <= 10) {
      return 'Frío';
    }

    if (temperature >= 30) {
      return 'Calor';
    }

    if (_isCloudCode(weatherCode)) {
      return 'Nublado';
    }

    return 'Soleado';
  }

  static bool _isRainCode(int code) {
    return (code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        (code >= 95 && code <= 99);
  }

  static bool _isSnowCode(int code) {
    return (code >= 71 && code <= 77) || code == 85 || code == 86;
  }

  static bool _isCloudCode(int code) {
    return code == 2 || code == 3 || code == 45 || code == 48;
  }
}
