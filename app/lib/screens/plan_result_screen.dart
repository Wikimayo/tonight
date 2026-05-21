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
import '../services/plan_generation_service.dart';
import '../services/usage_limits_service.dart';
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
import 'premium_screen.dart';

class PlanResultScreen extends StatefulWidget {
  const PlanResultScreen({required this.plan, super.key});

  final PlanModel plan;

  @override
  State<PlanResultScreen> createState() => _PlanResultScreenState();
}

class _PlanResultScreenState extends State<PlanResultScreen> {
  final ScreenshotController _shareImageController = ScreenshotController();
  final PlanGenerationService _planGenerationService =
      const PlanGenerationService();
  final MapsLauncherService _mapsLauncherService = const MapsLauncherService();
  late final PageController _pageController;
  late final List<PlanModel> plans;
  int currentIndex = 0;
  bool isFavorite = false;
  bool isSharingImage = false;
  bool isGeneratingAnother = false;

  PlanModel get plan => plans[currentIndex.clamp(0, plans.length - 1)];

  @override
  void initState() {
    super.initState();
    plans = [widget.plan];
    _pageController = PageController();
    _persistGeneratedPlan(plan);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(LanguageService.currentLanguage);

    return Scaffold(
      appBar: TonightAppBar(title: texts.planReadyTitle),
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
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: isGeneratingAnother
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    itemCount: plans.length + 1,
                    onPageChanged: _handlePageChanged,
                    itemBuilder: (context, index) {
                      if (index >= plans.length) {
                        return _SwipeGeneratePage(
                          texts: texts,
                          isLoading: isGeneratingAnother,
                          onGenerate: isGeneratingAnother
                              ? null
                              : () => _generateAnotherPlan(fromSwipe: true),
                        );
                      }

                      final visiblePlan = plans[index];
                      return SingleChildScrollView(
                        key: PageStorageKey('plan-result-${visiblePlan.id}'),
                        child: _buildPlanContent(visiblePlan, texts),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _PlanPagerIndicator(
                  currentIndex: currentIndex,
                  count: plans.length,
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: isGeneratingAnother
                      ? const Padding(
                          key: ValueKey('generating-another'),
                          padding: EdgeInsets.only(bottom: 12),
                          child: _GeneratingAnotherState(),
                        )
                      : const SizedBox.shrink(key: ValueKey('idle')),
                ),
                _FavoriteButton(
                  isFavorite: isFavorite,
                  onPressed: _toggleFavorite,
                ),
                const SizedBox(height: 12),
                PrimaryCtaButton(label: texts.sharePlan, onPressed: _sharePlan),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: isSharingImage
                      ? texts.preparingImage
                      : texts.shareImage,
                  onPressed: isSharingImage ? null : _sharePlanImage,
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: texts.editCriteria,
                  onPressed: _editCriteria,
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: isGeneratingAnother
                      ? texts.generatingAnother
                      : texts.generateAnother,
                  onPressed: isGeneratingAnother
                      ? null
                      : () => _generateAnotherPlan(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanContent(PlanModel visiblePlan, AppTextValues texts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu plan está listo',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 1.02,
          ),
        ),
        PlanSourceDebugChip(
          source: visiblePlan.source,
          reason: visiblePlan.reason,
        ),
        const SizedBox(height: 12),
        Text(
          '${TextSanitizer.clean(visiblePlan.location)} · '
          '${TextSanitizer.clean(visiblePlan.moment)} · '
          '${TextSanitizer.clean(visiblePlan.mood)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.70),
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Mañana · Tarde · Noche',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFFE8B66B),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ContextTag(
              icon: Icons.location_on_rounded,
              label: 'Ubicación',
              value: visiblePlan.location,
            ),
            _ContextTag(
              icon: Icons.wb_twilight_rounded,
              label: 'Momento',
              value: visiblePlan.moment,
            ),
            _ContextTag(
              icon: Icons.auto_awesome_rounded,
              label: 'Mood',
              value: visiblePlan.mood,
            ),
            _ContextTag(
              icon: Icons.payments_rounded,
              label: 'Presupuesto',
              value: visiblePlan.budget,
            ),
            _ContextTag(
              icon: Icons.schedule_rounded,
              label: 'Tiempo',
              value: visiblePlan.time,
            ),
            _ContextTag(
              icon: Icons.near_me_rounded,
              label: 'Distancia',
              value: visiblePlan.distance,
            ),
            _ContextTag(
              icon: Icons.cloud_rounded,
              label: 'Clima',
              value: visiblePlan.weather,
            ),
            if (visiblePlan.groupSize != null)
              _ContextTag(
                icon: Icons.diversity_3_rounded,
                label: 'Grupo',
                value: TextSanitizer.clean(visiblePlan.groupSize!),
              ),
          ],
        ),
        const SizedBox(height: 28),
        _PlanCard(plan: visiblePlan),
        const SizedBox(height: 24),
        PlanMapPreview(places: visiblePlan.places),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: 'Abrir ruta',
          onPressed: () => _openRouteInMaps(visiblePlan),
        ),
        const SizedBox(height: 24),
        PlanRoutePreview(plan: visiblePlan),
        const SizedBox(height: 24),
        _InsightPanel(title: 'Por qué te pega', text: visiblePlan.whyItFits),
        const SizedBox(height: 14),
        _InsightPanel(title: 'Vibe del plan', text: visiblePlan.vibe),
        const SizedBox(height: 30),
        Text(
          'Itinerario',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        ...visiblePlan.itinerarySteps.indexed.map((entry) {
          final index = entry.$1;
          final step = entry.$2;

          return _ItineraryStep(
            number: '${index + 1}',
            title: _stepTitleFor(visiblePlan, index),
            address: _stepAddressFor(visiblePlan, index),
            description: TextSanitizer.clean(step),
            place: index < visiblePlan.places.length
                ? visiblePlan.places[index]
                : null,
            onOpenPlace: index < visiblePlan.places.length
                ? () => _openPlaceInMaps(visiblePlan.places[index])
                : null,
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _handlePageChanged(int index) async {
    if (index >= plans.length) {
      if (!isGeneratingAnother) {
        await _generateAnotherPlan(fromSwipe: true);
      }
      return;
    }

    HapticService.selectionClick();
    final selectedPlan = plans[index];
    final savedAsFavorite = await LocalPlanStorage.isFavorite(selectedPlan);
    if (!mounted) {
      return;
    }

    setState(() {
      currentIndex = index;
      isFavorite = savedAsFavorite;
    });
  }

  Future<void> _persistGeneratedPlan(PlanModel generatedPlan) async {
    await LocalPlanStorage.addToHistory(generatedPlan);
    final savedAsFavorite = await LocalPlanStorage.isFavorite(generatedPlan);
    if (!mounted) {
      return;
    }

    setState(() {
      isFavorite = savedAsFavorite;
    });
  }

  Future<void> _generateAnotherPlan({bool fromSwipe = false}) async {
    if (isGeneratingAnother) {
      return;
    }

    if (!fromSwipe) {
      HapticService.heavyImpact();
    }
    setState(() {
      isGeneratingAnother = true;
    });

    final canGenerate = await UsageLimitsService.canGeneratePlan();
    if (!mounted) {
      return;
    }

    if (!canGenerate) {
      await const AnalyticsService().logFreePlanLimitReached(
        source: 'generate_another',
      );
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).push(tonightPageRoute<void>((_) => const PremiumScreen()));
      if (fromSwipe) {
        await _animateToCurrentPlan();
      }
      if (mounted) {
        setState(() {
          isGeneratingAnother = false;
        });
      }
      return;
    }

    try {
      final startedAt = DateTime.now();
      final nextPlan = await _generateDifferentPlan();
      final elapsed = DateTime.now().difference(startedAt);
      final remainingDelay = const Duration(milliseconds: 700) - elapsed;

      if (remainingDelay > Duration.zero) {
        await Future<void>.delayed(remainingDelay);
      }

      await UsageLimitsService.registerPlanGenerated();
      await LocalPlanStorage.addToHistory(nextPlan);
      await const AnalyticsService().logPlanGenerated(
        mood: nextPlan.mood,
        budget: nextPlan.budget,
        time: nextPlan.time,
        distance: nextPlan.distance,
        moment: nextPlan.moment,
        weather: nextPlan.weather,
      );
      HapticService.success();
      final savedAsFavorite = await LocalPlanStorage.isFavorite(nextPlan);
      if (!mounted) {
        return;
      }

      final nextIndex = plans.length;
      setState(() {
        plans.add(nextPlan);
        currentIndex = nextIndex;
        isFavorite = savedAsFavorite;
      });
      if (!fromSwipe) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) {
          return;
        }
        await _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (fromSwipe) {
        await _animateToCurrentPlan();
      }
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF17131D),
          content: Text('No se pudo generar otro plan. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingAnother = false;
        });
      }
    }
  }

  Future<void> _animateToCurrentPlan() async {
    if (!_pageController.hasClients) {
      return;
    }

    await _pageController.animateToPage(
      currentIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<PlanModel> _generateDifferentPlan() async {
    PlanModel nextPlan = plan;

    for (var attempt = 0; attempt < 5; attempt++) {
      nextPlan = await _planGenerationService.generatePlan(
        mood: plan.mood,
        budget: plan.budget,
        time: plan.time,
        distance: plan.distance,
        moment: plan.moment,
        location: plan.location,
        weather: plan.weather,
        groupSize: plan.groupSize,
      );

      if (!plans.any((savedPlan) => _isSamePlan(nextPlan, savedPlan))) {
        return nextPlan;
      }
    }

    return nextPlan;
  }

  void _editCriteria() {
    HapticService.lightImpact();
    Navigator.of(context).pushReplacement(
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

  bool _isSamePlan(PlanModel firstPlan, PlanModel secondPlan) {
    return firstPlan.title == secondPlan.title &&
        firstPlan.description == secondPlan.description;
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
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17131D),
        content: Text(
          savedAsFavorite
              ? 'Plan guardado en favoritos'
              : 'Plan quitado de favoritos',
        ),
      ),
    );
  }

  String _stepTitleFor(PlanModel targetPlan, int index) {
    if (targetPlan.places.length > index) {
      return TextSanitizer.clean(targetPlan.places[index].name);
    }

    switch (index) {
      case 0:
        return 'Primer sitio';
      case 1:
        return 'Segundo sitio';
      case 2:
      default:
        return 'Tercer sitio';
    }
  }

  String? _stepAddressFor(PlanModel targetPlan, int index) {
    if (targetPlan.places.length <= index) {
      return null;
    }

    return TextSanitizer.cleanOptional(targetPlan.places[index].address);
  }

  Future<void> _sharePlan() async {
    HapticService.mediumImpact();
    try {
      final result = await SharePlus.instance.share(
        ShareParams(subject: 'Mi plan en Tonight', text: _shareText),
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

  Future<void> _openRouteInMaps(PlanModel targetPlan) async {
    HapticService.mediumImpact();
    final didOpen = await _mapsLauncherService.openRoute(targetPlan.places);
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

  Future<void> _sharePlanImage() async {
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
        '${temporaryDirectory.path}/tonight_plan_${DateTime.now().microsecondsSinceEpoch}.png',
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
        _showShareImageError();
      } else {
        await const AnalyticsService().logPlanSharedImage(mood: plan.mood);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showShareImageError();
    } finally {
      if (mounted) {
        setState(() {
          isSharingImage = false;
        });
      }
    }
  }

  String get _shareText {
    return PlanTextFormatter.shareText(plan);
  }

  void _showShareError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF17131D),
        content: Text('No se pudo compartir el plan. Inténtalo de nuevo.'),
      ),
    );
  }

  void _showShareImageError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF17131D),
        content: Text('No se pudo preparar la imagen. Inténtalo de nuevo.'),
      ),
    );
  }

  void _showMapsError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF17131D),
        content: Text('No se pudo abrir Google Maps.'),
      ),
    );
  }
}

class _GeneratingAnotherState extends StatelessWidget {
  const _GeneratingAnotherState();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 22,
      opacity: 0.045,
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFFE8B66B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Preparando una nueva opción con la misma vibe...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.74),
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanPagerIndicator extends StatelessWidget {
  const _PlanPagerIndicator({required this.currentIndex, required this.count});

  final int currentIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Plan ${currentIndex + 1} de $count',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            ...List.generate(count, (index) {
              final isSelected = index == currentIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: isSelected ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8B66B)
                      : Colors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SwipeGeneratePage extends StatelessWidget {
  const _SwipeGeneratePage({
    required this.texts,
    required this.isLoading,
    required this.onGenerate,
  });

  final AppTextValues texts;
  final bool isLoading;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        borderRadius: 30,
        opacity: 0.05,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
                ),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Color(0xFFE8B66B),
                      ),
                    )
                  : const Icon(
                      Icons.swipe_left_rounded,
                      color: Color(0xFFE8B66B),
                      size: 30,
                    ),
            ),
            const SizedBox(height: 18),
            Text(
              isLoading ? texts.generatingAnother : texts.generateAnother,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mismos criterios, nueva combinación.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (!isLoading) ...[
              const SizedBox(height: 18),
              _SecondaryButton(
                label: texts.generatePlan,
                onPressed: onGenerate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                color: const Color(0xFFE8B66B),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                isFavorite ? 'Favorito guardado' : 'Guardar favorito',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(24),
      borderRadius: 34,
      opacity: 0.075,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Color(0xFFE8B66B),
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Plan recomendado',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFE8B66B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            TextSanitizer.clean(plan.title),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            TextSanitizer.clean(plan.description),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.48,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                icon: Icons.payments_rounded,
                label: 'Coste estimado',
                value: plan.estimatedCost,
              ),
              _MetricPill(
                icon: Icons.schedule_rounded,
                label: 'Duración',
                value: plan.estimatedDuration,
              ),
              _MetricPill(
                icon: Icons.near_me_rounded,
                label: 'Distancia',
                value: plan.estimatedDistance,
              ),
            ],
          ),
        ],
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

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8B66B).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFE8B66B), size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.56),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItineraryStep extends StatelessWidget {
  const _ItineraryStep({
    required this.number,
    required this.title,
    this.address,
    required this.description,
    this.place,
    this.onOpenPlace,
  });

  final String number;
  final String title;
  final String? address;
  final String description;
  final PlaceModel? place;
  final VoidCallback? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8B66B),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF100D10),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GlassPanel(
              padding: const EdgeInsets.all(16),
              borderRadius: 22,
              opacity: 0.035,
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
                  if (address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      address!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFE8B66B).withValues(alpha: 0.78),
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.64),
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
          ),
        ],
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
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
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
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(
                alpha: onPressed == null ? 0.62 : 1,
              ),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
