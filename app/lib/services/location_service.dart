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

    final address = _formatPlacemark(placemarks.first);

    if (address == null) {
      throw const LocationServiceException(
        'No hemos podido detectar tu ciudad o zona.',
      );
    }

    return address;
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

  static String? _formatPlacemark(Placemark place) {
    final street = _streetLine(place);
    final neighborhood = _firstNotEmpty([place.subLocality]);
    final city = _firstNotEmpty([
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ]);
    final administrativeArea = _firstNotEmpty([place.administrativeArea]);

    final parts = <String>[
      ?street,
      ?neighborhood,
      ?city,
      if (city == null && administrativeArea != null) administrativeArea,
    ];
    final uniqueParts = <String>[];
    for (final part in parts) {
      if (!uniqueParts.any((savedPart) => _samePlacePart(savedPart, part))) {
        uniqueParts.add(part);
      }
    }

    return uniqueParts.isEmpty ? null : uniqueParts.join(', ');
  }

  static String? _streetLine(Placemark place) {
    final thoroughfare = _firstNotEmpty([place.thoroughfare]);
    final street = _firstNotEmpty([place.street]);
    final streetName = thoroughfare ?? street;
    final number = _firstNotEmpty([place.subThoroughfare]);

    if (streetName == null) {
      return null;
    }

    if (number == null || _containsPlacePart(streetName, number)) {
      return streetName;
    }

    return '$streetName $number';
  }

  static bool _samePlacePart(String first, String second) {
    return _normalizePlacePart(first) == _normalizePlacePart(second);
  }

  static bool _containsPlacePart(String value, String part) {
    return _normalizePlacePart(value).contains(_normalizePlacePart(part));
  }

  static String _normalizePlacePart(String value) {
    return value.trim().toLowerCase();
  }
}
