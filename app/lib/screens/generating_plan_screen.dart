import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_texts.dart';
import '../models/plan_model.dart';
import '../services/analytics_service.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import '../services/plan_generation_service.dart';
import '../services/usage_limits_service.dart';
import '../services/weather_service.dart';
import '../utils/tonight_page_route.dart';
import '../widgets/glass_panel.dart';
import '../widgets/tonight_app_bar.dart';
import 'premium_screen.dart';
import 'plan_result_screen.dart';

class GeneratingPlanScreen extends StatefulWidget {
  const GeneratingPlanScreen({
    required this.mood,
    required this.budget,
    required this.time,
    required this.distance,
    required this.moment,
    required this.location,
    required this.weather,
    this.groupSize,
    super.key,
  });

  final String mood;
  final String budget;
  final String time;
  final String distance;
  final String moment;
  final String location;
  final String weather;
  final String? groupSize;

  @override
  State<GeneratingPlanScreen> createState() => _GeneratingPlanScreenState();
}

class _GeneratingPlanScreenState extends State<GeneratingPlanScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumLoadingDuration = Duration(milliseconds: 2500);

  final PlanGenerationService _planGenerationService =
      const PlanGenerationService();
  late final AnimationController _ambientController;
  Timer? _phaseTimer;
  Timer? _progressTimer;
  int phaseIndex = 0;
  double progress = 0.02;
  bool isCancelled = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _startPhaseLoop();
    _startProgressLoop();
    _generatePlanAndOpenResult();
  }

  @override
  void dispose() {
    isCancelled = true;
    _phaseTimer?.cancel();
    _progressTimer?.cancel();
    _ambientController.dispose();
    super.dispose();
  }

  void _startPhaseLoop() {
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1150), (_) {
      if (!mounted || isCancelled) {
        return;
      }

      setState(() {
        final phases = AppTexts.of(
          LanguageService.currentLanguage,
        ).generatingPhases;
        phaseIndex = (phaseIndex + 1) % phases.length;
      });
    });
  }

  void _startProgressLoop() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted || isCancelled) {
        return;
      }

      setState(() {
        progress = (progress + ((0.94 - progress) * 0.035)).clamp(0.02, 0.94);
      });
    });
  }

  Future<void> _completeProgress() async {
    _phaseTimer?.cancel();
    _progressTimer?.cancel();
    if (!mounted || isCancelled) {
      return;
    }

    setState(() {
      phaseIndex =
          AppTexts.of(LanguageService.currentLanguage).generatingPhases.length -
          1;
      progress = 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 240));
  }

  Future<void> _generatePlanAndOpenResult() async {
    final startedAt = DateTime.now();

    try {
      if (!await UsageLimitsService.canGeneratePlan()) {
        if (isCancelled || !mounted) {
          return;
        }
        await const AnalyticsService().logFreePlanLimitReached(
          source: 'generating_screen',
        );
        _openPremiumScreen();
        return;
      }

      final resolvedWeather = await _resolveWeather();
      if (isCancelled || !mounted) {
        return;
      }

      final plan = await _planGenerationService.generatePlan(
        mood: widget.mood,
        budget: widget.budget,
        time: widget.time,
        distance: widget.distance,
        moment: widget.moment,
        location: widget.location,
        weather: resolvedWeather,
        groupSize: widget.groupSize,
      );
      final elapsed = DateTime.now().difference(startedAt);
      final remainingLoadingTime = _minimumLoadingDuration - elapsed;

      if (remainingLoadingTime > Duration.zero) {
        await Future<void>.delayed(remainingLoadingTime);
      }
      if (isCancelled || !mounted) {
        return;
      }

      await UsageLimitsService.registerPlanGenerated();
      await const AnalyticsService().logPlanGenerated(
        mood: plan.mood,
        budget: plan.budget,
        time: plan.time,
        distance: plan.distance,
        moment: plan.moment,
        weather: plan.weather,
      );
      await _completeProgress();
      if (isCancelled || !mounted) {
        return;
      }
      HapticService.success();
      _openResultScreen(plan);
    } catch (_) {
      if (isCancelled) {
        return;
      }
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF17131D),
          content: Text('No se pudo generar el plan. Inténtalo de nuevo.'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<String> _resolveWeather() async {
    if (widget.weather != WeatherService.automaticWeather) {
      return widget.weather;
    }

    final resolvedWeather = await WeatherService.getAutomaticWeather();
    await const AnalyticsService().logWeatherAutoUsed(
      resolvedWeather: resolvedWeather,
    );
    return resolvedWeather;
  }

  void _cancelGeneration({bool pop = true}) {
    HapticService.lightImpact();
    isCancelled = true;
    _phaseTimer?.cancel();
    _progressTimer?.cancel();
    _ambientController.stop();

    if (pop && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _openResultScreen(PlanModel plan) {
    if (!mounted || isCancelled) {
      return;
    }

    Navigator.of(context).pushReplacement(
      tonightPageRoute<void>((_) => PlanResultScreen(plan: plan)),
    );
  }

  void _openPremiumScreen() {
    if (!mounted || isCancelled) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(tonightPageRoute<void>((_) => const PremiumScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(LanguageService.currentLanguage);
    final phases = texts.generatingPhases;

    return PopScope<void>(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _cancelGeneration(pop: false);
        }
      },
      child: Scaffold(
        appBar: TonightAppBar(
          title: texts.generatingTitle,
          backIcon: Icons.close_rounded,
          backTooltip: texts.cancel,
          onBack: _cancelGeneration,
          actions: [
            TextButton(
              onPressed: _cancelGeneration,
              child: Text(
                texts.cancel,
                style: const TextStyle(
                  color: Color(0xFFE8B66B),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            final value = _ambientController.value;
            final begin = Alignment.lerp(
              Alignment.topLeft,
              Alignment.topRight,
              value,
            )!;
            final end = Alignment.lerp(
              Alignment.bottomRight,
              Alignment.bottomLeft,
              value,
            )!;

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: begin,
                  end: end,
                  colors: const [
                    Color(0xFF2B1633),
                    Color(0xFF111019),
                    Color(0xFF07080D),
                  ],
                  stops: const [0, 0.52, 1],
                ),
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: Stack(
              children: [
                _AmbientGlow(animation: _ambientController),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texts.creatingYourPlan,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.02,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La IA está cruzando señales para que Tonight no parezca una lista cualquiera.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                      ),
                      const SizedBox(height: 18),
                      GlassPanel(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        borderRadius: 34,
                        opacity: 0.065,
                        child: Column(
                          children: [
                            _AiSparkleOrb(animation: _ambientController),
                            const SizedBox(height: 16),
                            _PhaseMessage(text: phases[phaseIndex]),
                            const SizedBox(height: 16),
                            _ProgressBar(progress: progress),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _LiveSignalRow(progress: progress),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;

        return Stack(
          children: [
            Positioned(
              top: -120 + (24 * value),
              right: -95,
              child: _GlowDisk(
                size: 280,
                color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              bottom: -130,
              left: -110 + (32 * value),
              child: _GlowDisk(
                size: 310,
                color: const Color(0xFF8F4FFF).withValues(alpha: 0.18),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowDisk extends StatelessWidget {
  const _GlowDisk({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _AiSparkleOrb extends StatelessWidget {
  const _AiSparkleOrb({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final pulse =
            0.94 + (0.08 * Curves.easeInOut.transform(animation.value));

        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.09),
                    border: Border.all(
                      color: const Color(0xFFE8B66B).withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8B66B).withValues(alpha: 0.20),
                        blurRadius: 42,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 66,
                  height: 66,
                  child: CircularProgressIndicator(
                    value: null,
                    strokeWidth: 3,
                    color: const Color(0xFFE8B66B),
                    backgroundColor: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFE8B66B),
                  size: 30,
                ),
                Positioned(
                  top: 13,
                  right: 15,
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.white.withValues(alpha: 0.70),
                    size: 15,
                  ),
                ),
                Positioned(
                  bottom: 18,
                  left: 14,
                  child: Icon(
                    Icons.brightness_7_rounded,
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.62),
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhaseMessage extends StatelessWidget {
  const _PhaseMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.16),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Text(
        text,
        key: ValueKey(text),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          height: 1.12,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round().clamp(0, 100);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: progress,
            color: const Color(0xFFE8B66B),
            backgroundColor: Colors.white.withValues(alpha: 0.09),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'IA trabajando',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.58),
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFFE8B66B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LiveSignalRow extends StatelessWidget {
  const _LiveSignalRow({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final label = progress < 0.72
        ? 'Afinando señales en tiempo real'
        : 'Si tarda un poco, estoy buscando una opción mejor';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.graphic_eq_rounded,
            color: Color(0xFFE8B66B),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.66),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
