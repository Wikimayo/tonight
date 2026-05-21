import 'package:url_launcher/url_launcher.dart';

import '../models/place_model.dart';
import '../utils/text_sanitizer.dart';

class MapsLauncherService {
  const MapsLauncherService();

  static const String _mapsHost = 'www.google.com';

  Future<bool> openPlace(PlaceModel place) {
    final uri = _hasCoordinates(place)
        ? _mapsSearchUri('${place.latitude},${place.longitude}')
        : _mapsSearchUri(_searchQueryForPlace(place));

    return _launch(uri);
  }

  Future<bool> openRoute(List<PlaceModel> places) {
    final placesWithCoordinates = places.where(_hasCoordinates).toList();

    if (placesWithCoordinates.length >= 2) {
      final origin = placesWithCoordinates.first;
      final destination = placesWithCoordinates.last;
      final waypoints = placesWithCoordinates
          .skip(1)
          .take(placesWithCoordinates.length - 2)
          .map(_coordinatePair)
          .toList();

      return _launch(
        Uri.https(_mapsHost, '/maps/dir/', {
          'api': '1',
          'origin': _coordinatePair(origin),
          'destination': _coordinatePair(destination),
          'travelmode': 'walking',
          if (waypoints.isNotEmpty) 'waypoints': waypoints.join('|'),
        }),
      );
    }

    final fallbackQuery = places
        .map(_searchQueryForPlace)
        .where((query) => query.isNotEmpty)
        .join(' ');

    if (fallbackQuery.isEmpty) {
      return Future.value(false);
    }

    return _launch(_mapsSearchUri(fallbackQuery));
  }

  static bool _hasCoordinates(PlaceModel place) {
    final latitude = place.latitude;
    final longitude = place.longitude;

    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static String _coordinatePair(PlaceModel place) {
    return '${place.latitude},${place.longitude}';
  }

  static String _searchQueryForPlace(PlaceModel place) {
    return [
      TextSanitizer.clean(place.name),
      TextSanitizer.cleanOptional(place.address),
      TextSanitizer.clean(place.location),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
  }

  static Uri _mapsSearchUri(String query) {
    return Uri.https(_mapsHost, '/maps/search/', {'api': '1', 'query': query});
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
