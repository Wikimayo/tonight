import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  const LocationService._();

  static Future<String> getReadableLocation() async {
    final position = await getCurrentPosition();

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      throw const LocationServiceException(
        'No hemos podido convertir tu ubicación en una zona legible.',
      );
    }

    final place = placemarks.first;
    final city = _firstNotEmpty([
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ]);
    final area = _firstNotEmpty([place.subLocality, place.thoroughfare]);

    if (city == null && area == null) {
      throw const LocationServiceException(
        'No hemos podido detectar tu ciudad o zona.',
      );
    }

    if (city != null && area != null && city != area) {
      return '$city, $area';
    }

    return city ?? area!;
  }

  static Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Activa la ubicación del dispositivo para usar esta opción.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'No podemos acceder a tu ubicación. Puedes escribir tu zona manualmente.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'No podemos acceder a tu ubicación. Puedes escribir tu zona manualmente.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  static String? _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final trimmedValue = value?.trim();
      if (trimmedValue != null && trimmedValue.isNotEmpty) {
        return trimmedValue;
      }
    }

    return null;
  }
}
