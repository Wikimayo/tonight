import 'dart:async';

import 'package:flutter/material.dart';

import '../models/plan_model.dart';
import '../services/analytics_service.dart';
import '../services/plan_generation_service.dart';
import '../services/usage_limits_service.dart';
import '../services/weather_service.dart';
import '../widgets/glass_panel.dart';
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

class _GeneratingPlanScreenState extends State<GeneratingPlanScreen> {
  static const Duration _minimumLoadingDuration = Duration(milliseconds: 2500);

  final PlanGenerationService _planGenerationService =
      const PlanGenerationService();
  final List<Timer> _timers = [];
  int visiblePhraseCount = 1;

  final List<String> phrases = const [
    'Buscando sitios con buena vibra',
    'Calculando tiempos y distancia',
    'Preparando una experiencia diferente',
  ];

  @override
  void initState() {
    super.initState();
    _schedulePhrase(2, const Duration(milliseconds: 750));
    _schedulePhrase(3, const Duration(milliseconds: 1450));
    _generatePlanAndOpenResult();
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _schedulePhrase(int count, Duration delay) {
    _timers.add(
      Timer(delay, () {
        if (!mounted) {
          return;
        }

        setState(() {
          visiblePhraseCount = count;
        });
      }),
    );
  }

  Future<void> _generatePlanAndOpenResult() async {
    final startedAt = DateTime.now();

    try {
      if (!await UsageLimitsService.canGeneratePlan()) {
        await const AnalyticsService().logFreePlanLimitReached(
          source: 'generating_screen',
        );
        _openPremiumScreen();
        return;
      }

      final resolvedWeather = await _resolveWeather();
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

      await UsageLimitsService.registerPlanGenerated();
      await const AnalyticsService().logPlanGenerated(
        mood: plan.mood,
        budget: plan.budget,
        time: plan.time,
        distance: plan.distance,
        moment: plan.moment,
        weather: plan.weather,
      );
      _openResultScreen(plan);
    } catch (_) {
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

  void _openResultScreen(PlanModel plan) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => PlanResultScreen(plan: plan)),
    );
  }

  void _openPremiumScreen() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
    );
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
            stops: [0, 0.48, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  'Creando tu plan',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Analizando mood, zona, clima y momento...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 34),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.94, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.055),
                        border: Border.all(
                          color: const Color(
                            0xFFE8B66B,
                          ).withValues(alpha: 0.20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE8B66B,
                            ).withValues(alpha: 0.18),
                            blurRadius: 34,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: const Color(0xFFE8B66B),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.10,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFE8B66B),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 38),
                GlassPanel(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 30,
                  opacity: 0.05,
                  child: Column(
                    children: phrases.indexed.map((entry) {
                      final index = entry.$1;
                      final phrase = entry.$2;

                      return _LoadingPhrase(
                        text: phrase,
                        isVisible: index < visiblePhraseCount,
                      );
                    }).toList(),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPhrase extends StatelessWidget {
  const _LoadingPhrase({required this.text, required this.isVisible});

  final String text;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      opacity: isVisible ? 1 : 0.28,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isVisible
                    ? const Color(0xFFE8B66B).withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isVisible
                      ? const Color(0xFFE8B66B).withValues(alpha: 0.24)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                isVisible ? Icons.check_rounded : Icons.more_horiz_rounded,
                color: isVisible
                    ? const Color(0xFFE8B66B)
                    : Colors.white.withValues(alpha: 0.34),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(
                    alpha: isVisible ? 0.86 : 0.42,
                  ),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
