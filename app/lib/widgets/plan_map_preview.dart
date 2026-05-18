import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/place_model.dart';
import 'glass_panel.dart';

class PlanMapPreview extends StatelessWidget {
  const PlanMapPreview({required this.places, super.key});

  final List<PlaceModel> places;

  @override
  Widget build(BuildContext context) {
    final mappedPlaces = places
        .where((place) => place.latitude != null && place.longitude != null)
        .toList();
    final canShowMap =
        places.isNotEmpty && mappedPlaces.length == places.length;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GlassPanel(
        padding: const EdgeInsets.all(18),
        borderRadius: 30,
        opacity: 0.05,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFFE8B66B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mapa del plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (canShowMap)
              _GoogleMapPreview(places: mappedPlaces)
            else
              const _MapUnavailableState(),
          ],
        ),
      ),
    );
  }
}

class _GoogleMapPreview extends StatelessWidget {
  const _GoogleMapPreview({required this.places});

  final List<PlaceModel> places;

  @override
  Widget build(BuildContext context) {
    final firstPlace = places.first;
    final initialPosition = LatLng(firstPlace.latitude!, firstPlace.longitude!);
    final markers = places.indexed.map((entry) {
      final index = entry.$1;
      final place = entry.$2;

      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.latitude!, place.longitude!),
        infoWindow: InfoWindow(
          title: '${index + 1}. ${place.name}',
          snippet: place.category,
        ),
      );
    }).toSet();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 230,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 13.6,
          ),
          markers: markers,
          compassEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          trafficEnabled: false,
          zoomControlsEnabled: false,
          liteModeEnabled: true,
        ),
      ),
    );
  }
}

class _MapUnavailableState extends StatelessWidget {
  const _MapUnavailableState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: Color(0xFFE8B66B),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Mapa no disponible para este plan',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w800,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
