import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_texts.dart';
import '../models/place_model.dart';
import '../models/plan_model.dart';
import '../services/analytics_service.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import '../services/local_plan_storage.dart';
import '../services/maps_launcher_service.dart';
import '../utils/plan_text_formatter.dart';
import '../utils/text_sanitizer.dart';
import '../utils/tonight_page_route.dart';
import '../widgets/glass_panel.dart';
import '../widgets/plan_map_preview.dart';
import '../widgets/plan_route_preview.dart';
import '../widgets/plan_source_debug_chip.dart';
import '../widgets/primary_cta_button.dart';
import '../widgets/share_plan_card.dart';
import '../widgets/tonight_app_bar.dart';
import 'plan_setup_screen.dart';

class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({required this.plan, super.key});

  final PlanModel plan;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  final ScreenshotController _shareImageController = ScreenshotController();
  final MapsLauncherService _mapsLauncherService = const MapsLauncherService();
  bool isFavorite = false;
  bool isInHistory = false;
  bool isCheckingFavorite = true;
  bool isSharingImage = false;

  PlanModel get plan => widget.plan;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(LanguageService.currentLanguage);

    return Scaffold(
      appBar: TonightAppBar(title: texts.planDetailTitle),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF251329), Color(0xFF0D0B11), Color(0xFF08080C)],
            stops: [0, 0.46, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TextSanitizer.clean(plan.title),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                height: 1.04,
                              ),
                        ),
                        PlanSourceDebugChip(
                          source: plan.source,
                          reason: plan.reason,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          TextSanitizer.clean(plan.description),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _ContextTag(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Mood',
                              value: plan.mood,
                            ),
                            _ContextTag(
                              icon: Icons.location_on_rounded,
                              label: 'Ubicación',
                              value: plan.location,
                            ),
                            _ContextTag(
                              icon: Icons.wb_twilight_rounded,
                              label: 'Momento',
                              value: plan.moment,
                            ),
                            _ContextTag(
                              icon: Icons.payments_rounded,
                              label: 'Coste',
                              value: plan.estimatedCost,
                            ),
                            _ContextTag(
                              icon: Icons.schedule_rounded,
                              label: 'Duración',
                              value: plan.estimatedDuration,
                            ),
                            _ContextTag(
                              icon: Icons.near_me_rounded,
                              label: 'Distancia',
                              value: plan.estimatedDistance,
                            ),
                            _ContextTag(
                              icon: Icons.cloud_rounded,
                              label: 'Clima',
                              value: plan.weather,
                            ),
                            if (plan.groupSize != null)
                              _ContextTag(
                                icon: Icons.diversity_3_rounded,
                                label: 'Grupo',
                                value: TextSanitizer.clean(plan.groupSize!),
                              ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        PlanMapPreview(places: plan.places),
                        const SizedBox(height: 12),
                        _SecondaryButton(
                          label: 'Abrir ruta',
                          icon: Icons.map_rounded,
                          onPressed: _openRouteInMaps,
                        ),
                        const SizedBox(height: 24),
                        PlanRoutePreview(plan: plan),
                        const SizedBox(height: 24),
                        _InsightPanel(
                          title: 'Por qué te pega',
                          text: plan.whyItFits,
                        ),
                        const SizedBox(height: 14),
                        _InsightPanel(title: 'Vibe del plan', text: plan.vibe),
                        const SizedBox(height: 28),
                        Text(
                          'Itinerario completo',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ...plan.itinerarySteps.indexed.map((entry) {
                          final place = entry.$1 < plan.places.length
                              ? plan.places[entry.$1]
                              : null;

                          return _ItineraryStep(
                            number: entry.$1 + 1,
                            place: place,
                            onOpenPlace: place == null
                                ? null
                                : () => _openPlaceInMaps(place),
                            text: TextSanitizer.clean(entry.$2),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                PrimaryCtaButton(
                  label: texts.useThisPlan,
                  onPressed: _usePlanAsBase,
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: texts.shareText,
                  icon: Icons.ios_share_rounded,
                  onPressed: _shareText,
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: isSharingImage
                      ? texts.preparingImage
                      : texts.shareImage,
                  icon: Icons.ios_share_rounded,
                  onPressed: isSharingImage ? null : _shareImage,
                ),
                if (!isCheckingFavorite) ...[
                  const SizedBox(height: 12),
                  _SecondaryButton(
                    label: isFavorite
                        ? 'Favorito guardado'
                        : 'Guardar favorito',
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    onPressed: _toggleFavorite,
                  ),
                ],
                if (!isCheckingFavorite && (isFavorite || isInHistory)) ...[
                  const SizedBox(height: 12),
                  _SecondaryButton(
                    label: 'Borrar plan',
                    icon: Icons.delete_outline_rounded,
                    onPressed: _confirmDeletePlan,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadFavoriteState() async {
    final results = await Future.wait([
      LocalPlanStorage.isFavorite(plan),
      LocalPlanStorage.isInHistory(plan),
    ]);
    if (!mounted) {
      return;
    }

    setState(() {
      isFavorite = results[0];
      isInHistory = results[1];
      isCheckingFavorite = false;
    });
  }

  Future<void> _toggleFavorite() async {
    HapticService.mediumImpact();
    final savedAsFavorite = await LocalPlanStorage.toggleFavorite(plan);
    if (!mounted) {
      return;
    }

    setState(() {
      isFavorite = savedAsFavorite;
    });
    if (savedAsFavorite) {
      await const AnalyticsService().logPlanSavedFavorite(mood: plan.mood);
    }
    _showSnackBar(
      savedAsFavorite
          ? 'Plan guardado en favoritos'
          : 'Plan quitado de favoritos',
    );
  }

  Future<void> _confirmDeletePlan() async {
    HapticService.mediumImpact();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17131D),
        title: const Text(
          'Borrar plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          _deleteDialogMessage,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    HapticService.heavyImpact();
    await LocalPlanStorage.removePlan(
      plan.id,
      fromHistory: isInHistory,
      fromFavorites: isFavorite,
    );
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  String get _deleteDialogMessage {
    if (isFavorite && isInHistory) {
      return 'Se eliminará de historial y favoritos de este dispositivo.';
    }
    if (isFavorite) {
      return 'Se eliminará de favoritos de este dispositivo.';
    }
    return 'Se eliminará del historial de este dispositivo.';
  }

  void _usePlanAsBase() {
    HapticService.lightImpact();
    Navigator.of(context).push(
      tonightPageRoute<void>(
        (_) => PlanSetupScreen(
          initialMood: plan.mood,
          initialLocation: plan.location,
          initialMoment: plan.moment,
          initialBudget: plan.budget,
          initialTime: plan.time,
          initialDistance: plan.distance,
          initialWeather: plan.weather,
          initialGroupSize: plan.groupSize,
        ),
      ),
    );
  }

  Future<void> _shareText() async {
    HapticService.mediumImpact();
    try {
      final result = await SharePlus.instance.share(
        ShareParams(subject: 'Mi plan en Tonight', text: _shareTextContent),
      );

      if (!mounted) {
        return;
      }

      if (result.status == ShareResultStatus.unavailable) {
        _showShareError();
      } else {
        await const AnalyticsService().logPlanSharedText(mood: plan.mood);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showShareError();
    }
  }

  Future<void> _shareImage() async {
    HapticService.mediumImpact();
    setState(() {
      isSharingImage = true;
    });

    try {
      final imageBytes = await _shareImageController.captureFromWidget(
        Screenshot(
          controller: _shareImageController,
          child: SharePlanCard(plan: plan),
        ),
        context: context,
        pixelRatio: 2,
        targetSize: SharePlanCard.storySize,
      );
      final temporaryDirectory = await getTemporaryDirectory();
      final imageFile = File(
        '${temporaryDirectory.path}/tonight_saved_plan_${DateTime.now().microsecondsSinceEpoch}.png',
      );

      await imageFile.writeAsBytes(imageBytes, flush: true);

      final result = await SharePlus.instance.share(
        ShareParams(
          subject: 'Mi plan en Tonight',
          text: 'Mi plan en Tonight: ${TextSanitizer.clean(plan.title)}',
          files: [XFile(imageFile.path, mimeType: 'image/png')],
          fileNameOverrides: const ['tonight-plan.png'],
        ),
      );

      if (!mounted) {
        return;
      }

      if (result.status == ShareResultStatus.unavailable) {
        _showImageShareError();
      } else {
        await const AnalyticsService().logPlanSharedImage(mood: plan.mood);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showImageShareError();
    } finally {
      if (mounted) {
        setState(() {
          isSharingImage = false;
        });
      }
    }
  }

  Future<void> _openRouteInMaps() async {
    HapticService.mediumImpact();
    final didOpen = await _mapsLauncherService.openRoute(plan.places);
    if (!mounted) {
      return;
    }

    if (!didOpen) {
      _showMapsError();
    }
  }

  Future<void> _openPlaceInMaps(PlaceModel place) async {
    HapticService.mediumImpact();
    final didOpen = await _mapsLauncherService.openPlace(place);
    if (!mounted) {
      return;
    }

    if (!didOpen) {
      _showMapsError();
    }
  }

  String get _shareTextContent => PlanTextFormatter.shareText(plan);

  void _showShareError() {
    _showSnackBar('No se pudo compartir el plan. Inténtalo de nuevo.');
  }

  void _showImageShareError() {
    _showSnackBar('No se pudo preparar la imagen. Inténtalo de nuevo.');
  }

  void _showMapsError() {
    _showSnackBar('No se pudo abrir Google Maps.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17131D),
        content: Text(message),
      ),
    );
  }
}

class _ContextTag extends StatelessWidget {
  const _ContextTag({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFF1D7A6), size: 15),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFF1D7A6),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: 26,
      opacity: 0.045,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryStep extends StatelessWidget {
  const _ItineraryStep({
    required this.number,
    required this.text,
    this.place,
    this.onOpenPlace,
  });

  final int number;
  final String text;
  final PlaceModel? place;
  final VoidCallback? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        opacity: 0.035,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8B66B),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF100D10),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place != null) ...[
                    Text(
                      TextSanitizer.clean(place!.name),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    if (TextSanitizer.cleanOptional(place!.address) !=
                        null) ...[
                      const SizedBox(height: 4),
                      Text(
                        TextSanitizer.clean(place!.address!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(
                            0xFFE8B66B,
                          ).withValues(alpha: 0.78),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                  ],
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                      height: 1.42,
                    ),
                  ),
                  if (place != null) ...[
                    const SizedBox(height: 12),
                    _MapsTextButton(onPressed: onOpenPlace),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapsTextButton extends StatelessWidget {
  const _MapsTextButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFE8B66B),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.map_rounded, size: 17),
        label: const Text(
          'Ver en Maps',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: onPressed == null ? 0.035 : 0.07),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(
                  0xFFE8B66B,
                ).withValues(alpha: onPressed == null ? 0.62 : 1),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white.withValues(
                    alpha: onPressed == null ? 0.62 : 1,
                  ),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
