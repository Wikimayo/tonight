import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/plan_model.dart';
import '../services/analytics_service.dart';
import '../services/local_plan_storage.dart';
import '../services/plan_generation_service.dart';
import '../services/usage_limits_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/plan_map_preview.dart';
import '../widgets/plan_route_preview.dart';
import '../widgets/plan_source_debug_chip.dart';
import '../widgets/primary_cta_button.dart';
import '../widgets/share_plan_card.dart';
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
  late PlanModel plan;
  bool isFavorite = false;
  bool isSharingImage = false;
  bool isGeneratingAnother = false;

  @override
  void initState() {
    super.initState();
    plan = widget.plan;
    _persistGeneratedPlan(plan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slideAnimation = Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      key: ValueKey(plan.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu plan está listo',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  height: 1.02,
                                ),
                          ),
                          PlanSourceDebugChip(
                            source: plan.source,
                            reason: plan.reason,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${plan.location} · ${plan.moment} · ${plan.mood}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Mañana · Tarde · Noche',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
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
                                value: plan.location,
                              ),
                              _ContextTag(
                                icon: Icons.wb_twilight_rounded,
                                label: 'Momento',
                                value: plan.moment,
                              ),
                              _ContextTag(
                                icon: Icons.auto_awesome_rounded,
                                label: 'Mood',
                                value: plan.mood,
                              ),
                              _ContextTag(
                                icon: Icons.payments_rounded,
                                label: 'Presupuesto',
                                value: plan.budget,
                              ),
                              _ContextTag(
                                icon: Icons.schedule_rounded,
                                label: 'Tiempo',
                                value: plan.time,
                              ),
                              _ContextTag(
                                icon: Icons.near_me_rounded,
                                label: 'Distancia',
                                value: plan.distance,
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
                                  value: plan.groupSize!,
                                ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _PlanCard(plan: plan),
                          const SizedBox(height: 24),
                          PlanMapPreview(places: plan.places),
                          const SizedBox(height: 24),
                          PlanRoutePreview(plan: plan),
                          const SizedBox(height: 24),
                          _InsightPanel(
                            title: 'Por qué te pega',
                            text: plan.whyItFits,
                          ),
                          const SizedBox(height: 14),
                          _InsightPanel(
                            title: 'Vibe del plan',
                            text: plan.vibe,
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Itinerario',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...plan.itinerarySteps.indexed.map((entry) {
                            final index = entry.$1;
                            final step = entry.$2;

                            return _ItineraryStep(
                              number: '${index + 1}',
                              title: _stepTitleFor(index),
                              description: step,
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
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
                  onPressed: _saveFavorite,
                ),
                const SizedBox(height: 12),
                PrimaryCtaButton(
                  label: 'Compartir plan',
                  onPressed: _sharePlan,
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: isSharingImage
                      ? 'Preparando imagen...'
                      : 'Compartir imagen',
                  onPressed: isSharingImage ? null : _sharePlanImage,
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: isGeneratingAnother
                      ? 'Generando otro...'
                      : 'Generar otro',
                  onPressed: isGeneratingAnother ? null : _generateAnotherPlan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> _generateAnotherPlan() async {
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
      ).push(MaterialPageRoute<void>(builder: (_) => const PremiumScreen()));
      return;
    }

    setState(() {
      isGeneratingAnother = true;
    });

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
      final savedAsFavorite = await LocalPlanStorage.isFavorite(nextPlan);
      if (!mounted) {
        return;
      }

      setState(() {
        plan = nextPlan;
        isFavorite = savedAsFavorite;
      });
    } catch (_) {
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

      if (!_isSamePlan(nextPlan, plan)) {
        return nextPlan;
      }
    }

    return nextPlan;
  }

  bool _isSamePlan(PlanModel firstPlan, PlanModel secondPlan) {
    return firstPlan.title == secondPlan.title &&
        firstPlan.description == secondPlan.description;
  }

  Future<void> _saveFavorite() async {
    await LocalPlanStorage.addToFavorites(plan);
    if (!mounted) {
      return;
    }

    setState(() {
      isFavorite = true;
    });
    await const AnalyticsService().logPlanSavedFavorite(mood: plan.mood);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF17131D),
        content: Text('Plan guardado en favoritos'),
      ),
    );
  }

  String _stepTitleFor(int index) {
    if (plan.places.length > index) {
      return plan.places[index].name;
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

  Future<void> _sharePlan() async {
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

  Future<void> _sharePlanImage() async {
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
        pixelRatio: 3,
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
          text: 'Mi plan en Tonight: ${plan.title}',
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
    final itinerary = plan.itinerarySteps.indexed
        .map((entry) {
          return '${entry.$1 + 1}. ${entry.$2}';
        })
        .join('\n');

    return '''
Mi plan en Tonight

${plan.title}
${plan.description}

Mood: ${plan.mood}
Ubicación: ${plan.location}
Momento: ${plan.moment}
Clima: ${plan.weather}
Coste estimado: ${plan.estimatedCost}
Duración estimada: ${plan.estimatedDuration}
${plan.groupSize == null ? '' : 'Tamaño del grupo: ${plan.groupSize}\n'}

Itinerario:
$itinerary
''';
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
            plan.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            plan.description,
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
    required this.description,
  });

  final String number;
  final String title;
  final String description;

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
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.64),
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
