import 'package:flutter/material.dart';

import '../core/constants/app_texts.dart';
import '../services/analytics_service.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import '../services/location_service.dart';
import '../services/premium_service.dart';
import '../services/usage_limits_service.dart';
import '../services/user_preferences_service.dart';
import '../utils/text_sanitizer.dart';
import '../utils/tonight_page_route.dart';
import '../widgets/glass_panel.dart';
import '../widgets/mood_chip.dart';
import '../widgets/primary_cta_button.dart';
import '../widgets/tonight_app_bar.dart';
import 'generating_plan_screen.dart';
import 'premium_screen.dart';

class PlanSetupScreen extends StatefulWidget {
  const PlanSetupScreen({
    String? mood,
    this.initialMood,
    this.initialLocation,
    this.initialMoment,
    this.initialBudget,
    this.initialTime,
    this.initialDistance,
    this.initialWeather,
    this.initialGroupSize,
    super.key,
  }) : mood = mood ?? initialMood ?? 'Cita';

  final String mood;
  final String? initialMood;
  final String? initialLocation;
  final String? initialMoment;
  final String? initialBudget;
  final String? initialTime;
  final String? initialDistance;
  final String? initialWeather;
  final String? initialGroupSize;

  @override
  State<PlanSetupScreen> createState() => _PlanSetupScreenState();
}

class _PlanSetupScreenState extends State<PlanSetupScreen> {
  final TextEditingController locationController = TextEditingController();

  late String selectedMoment;
  late String selectedBudget;
  late String selectedTime;
  late String selectedDistance;
  late String selectedWeather;
  late String selectedGroupSize;
  late Future<String> usageSummaryFuture = _loadUsageSummaryText();
  bool isLocating = false;

  final List<String> moments = const [
    'Ahora',
    'Mañana',
    'Tarde',
    'Noche',
    'Fin de semana',
  ];
  final List<String> budgets = const ['Gratis', '€', '€€', '€€€'];
  final List<String> times = const ['1h', '2h', '3h', 'Toda la noche'];
  final List<String> distances = const ['Cerca', 'Media', 'Me da igual'];
  final List<String> weathers = const [
    'Automático',
    'Soleado',
    'Lluvia',
    'Frío',
    'Calor',
    'Nublado',
  ];
  final List<String> groupSizes = const ['2-3', '4-6', '7+'];

  @override
  void initState() {
    super.initState();
    selectedMoment = _initialSelection(widget.initialMoment, moments, 'Ahora');
    selectedBudget = _initialSelection(widget.initialBudget, budgets, '€€');
    selectedTime = _initialSelection(widget.initialTime, times, '2h');
    selectedDistance = _initialSelection(
      widget.initialDistance,
      distances,
      'Cerca',
    );
    selectedWeather = _initialSelection(
      widget.initialWeather,
      weathers,
      'Automático',
    );
    selectedGroupSize = _initialSelection(
      widget.initialGroupSize,
      groupSizes,
      '4-6',
    );
    locationController.text = widget.initialLocation?.trim() ?? '';
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final preferences = await UserPreferencesService.getPreferences();
    if (!mounted) {
      return;
    }

    setState(() {
      if (widget.initialBudget == null) {
        selectedBudget = _initialSelection(
          preferences.defaultBudget,
          budgets,
          selectedBudget,
        );
      }
      if (widget.initialTime == null) {
        selectedTime = _initialSelection(
          preferences.defaultTime,
          times,
          selectedTime,
        );
      }
      if (widget.initialDistance == null) {
        selectedDistance = _initialSelection(
          preferences.defaultDistance,
          distances,
          selectedDistance,
        );
      }
      if (widget.initialLocation == null) {
        locationController.text = preferences.defaultLocation?.trim() ?? '';
      }
    });
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(LanguageService.currentLanguage);

    return Scaffold(
      appBar: TonightAppBar(title: texts.planSetupTitle),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF211229), Color(0xFF0D0B11), Color(0xFF08080C)],
            stops: [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texts.planSetupHeading,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.06,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${texts.selectedMoodPrefix}: ${texts.moodLabel(widget.mood)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFE8B66B),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 34),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SetupSection(
                          title: texts.moment,
                          options: moments,
                          selectedOption: selectedMoment,
                          labelFor: texts.momentLabel,
                          onSelected: (value) {
                            setState(() {
                              selectedMoment = value;
                            });
                          },
                        ),
                        const SizedBox(height: 28),
                        _LocationSection(
                          texts: texts,
                          controller: locationController,
                          isTravelMood: widget.mood == 'Viaje',
                          isLoading: isLocating,
                          onUseCurrentLocation: _useCurrentLocation,
                        ),
                        const SizedBox(height: 28),
                        _SetupSection(
                          title: texts.weather,
                          options: weathers,
                          selectedOption: selectedWeather,
                          labelFor: texts.weatherLabel,
                          onSelected: (value) {
                            setState(() {
                              selectedWeather = value;
                            });
                          },
                        ),
                        const SizedBox(height: 28),
                        if (widget.mood == 'Grupo') ...[
                          _SetupSection(
                            title: 'Tamaño del grupo',
                            options: groupSizes,
                            selectedOption: selectedGroupSize,
                            onSelected: (value) {
                              setState(() {
                                selectedGroupSize = value;
                              });
                            },
                          ),
                          const SizedBox(height: 28),
                        ],
                        _SetupSection(
                          title: texts.budget,
                          options: budgets,
                          selectedOption: selectedBudget,
                          labelFor: texts.budgetLabel,
                          onSelected: (value) {
                            setState(() {
                              selectedBudget = value;
                            });
                          },
                        ),
                        const SizedBox(height: 28),
                        _SetupSection(
                          title: texts.timeAvailable,
                          options: times,
                          selectedOption: selectedTime,
                          labelFor: texts.timeLabel,
                          onSelected: (value) {
                            setState(() {
                              selectedTime = value;
                            });
                          },
                        ),
                        const SizedBox(height: 28),
                        _SetupSection(
                          title: texts.distance,
                          options: distances,
                          selectedOption: selectedDistance,
                          labelFor: texts.distanceLabel,
                          onSelected: (value) {
                            setState(() {
                              selectedDistance = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                PrimaryCtaButton(
                  label: texts.generatePlan,
                  onPressed: _generatePlan,
                ),
                const SizedBox(height: 10),
                _SetupUsageHint(usageSummaryFuture: usageSummaryFuture),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    if (isLocating) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      isLocating = true;
    });

    try {
      final readableLocation = await LocationService.getReadableLocation();
      if (!mounted) {
        return;
      }

      locationController.text = readableLocation;
      await const AnalyticsService().logLocationUsed();
    } on LocationServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showLocationError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showLocationError(
        'No hemos podido detectar tu ubicación. Puedes escribirla manualmente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLocating = false;
        });
      }
    }
  }

  Future<void> _generatePlan() async {
    FocusScope.of(context).unfocus();
    HapticService.heavyImpact();
    final canGenerate = await UsageLimitsService.canGeneratePlan();
    if (!mounted) {
      return;
    }

    if (!canGenerate) {
      await const AnalyticsService().logFreePlanLimitReached(
        source: 'plan_setup',
      );
      if (!mounted) {
        return;
      }

      await Navigator.of(
        context,
      ).push(tonightPageRoute<void>((_) => const PremiumScreen()));
      _refreshUsageSummary();
      return;
    }

    await Navigator.of(context).push(
      tonightPageRoute<void>(
        (_) => GeneratingPlanScreen(
          mood: widget.mood,
          budget: selectedBudget,
          time: selectedTime,
          distance: selectedDistance,
          moment: selectedMoment,
          location: _resolvedLocation,
          weather: selectedWeather,
          groupSize: widget.mood == 'Grupo' ? selectedGroupSize : null,
        ),
      ),
    );
    _refreshUsageSummary();
  }

  Future<String> _loadUsageSummaryText() async {
    final isPremium = await PremiumService.isPremium();
    final remainingPlans = await UsageLimitsService.getRemainingPlansToday();
    await const AnalyticsService().logRemainingFreePlansViewed(
      remainingPlans: remainingPlans,
      dailyLimit: UsageLimitsService.getDailyLimit(),
      isPremium: isPremium,
      source: 'plan_setup',
    );

    if (isPremium) {
      return 'Premium activo · planes ilimitados';
    }

    return '$remainingPlans planes gratis restantes hoy';
  }

  void _refreshUsageSummary() {
    if (!mounted) {
      return;
    }

    setState(() {
      usageSummaryFuture = _loadUsageSummaryText();
    });
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17131D),
        content: Text(message),
      ),
    );
  }

  String get _resolvedLocation {
    final trimmedLocation = locationController.text.trim();
    return trimmedLocation.isEmpty ? 'tu zona' : trimmedLocation;
  }

  String _initialSelection(
    String? value,
    List<String> options,
    String fallback,
  ) {
    final trimmedValue = TextSanitizer.cleanOptional(value);
    if (trimmedValue != null && options.contains(trimmedValue)) {
      return trimmedValue;
    }

    return fallback;
  }
}

class _SetupSection extends StatelessWidget {
  const _SetupSection({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    this.labelFor,
  });

  final String title;
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onSelected;
  final String Function(String value)? labelFor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(),
      child: GlassPanel(
        padding: const EdgeInsets.all(20),
        borderRadius: 30,
        opacity: 0.045,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionIcon(icon: _iconForTitle(title)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((option) {
                return MoodChip(
                  label: labelFor?.call(option) ?? option,
                  iconKey: option,
                  isSelected: selectedOption == option,
                  onTap: () => onSelected(option),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForTitle(String title) {
    switch (title) {
      case 'Momento':
        return Icons.wb_twilight_rounded;
      case 'Presupuesto':
        return Icons.payments_rounded;
      case 'Tiempo disponible':
        return Icons.schedule_rounded;
      case 'Distancia':
        return Icons.near_me_rounded;
      case 'Clima':
        return Icons.cloud_rounded;
      case 'Tamaño del grupo':
        return Icons.diversity_3_rounded;
      default:
        return Icons.tune_rounded;
    }
  }
}

class _SetupUsageHint extends StatelessWidget {
  const _SetupUsageHint({required this.usageSummaryFuture});

  final Future<String> usageSummaryFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: usageSummaryFuture,
      builder: (context, snapshot) {
        final text = snapshot.data ?? 'Calculando planes restantes...';

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFE8B66B),
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.texts,
    required this.controller,
    required this.isTravelMood,
    required this.isLoading,
    required this.onUseCurrentLocation,
  });

  final AppTextValues texts;
  final TextEditingController controller;
  final bool isTravelMood;
  final bool isLoading;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(),
      child: GlassPanel(
        padding: const EdgeInsets.all(20),
        borderRadius: 30,
        opacity: 0.045,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SectionIcon(icon: Icons.location_on_rounded),
                const SizedBox(width: 12),
                Text(
                  isTravelMood ? '¿A qué ciudad vas?' : '¿Dónde estás?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              cursorColor: const Color(0xFFE8B66B),
              decoration: InputDecoration(
                hintText: isTravelMood
                    ? 'Roma, París, Lisboa, Madrid...'
                    : 'Madrid, Malasaña, Barcelona...',
                helperText:
                    'Usaremos esta zona como referencia, no compartimos tu ubicación exacta públicamente.',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontWeight: FontWeight.w500,
                ),
                helperStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.24),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFFE8B66B),
                    width: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _UseLocationButton(
              texts: texts,
              isLoading: isLoading,
              onPressed: onUseCurrentLocation,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8B66B).withValues(alpha: 0.20),
        ),
      ),
      child: Icon(icon, color: const Color(0xFFE8B66B), size: 20),
    );
  }
}

class _UseLocationButton extends StatelessWidget {
  const _UseLocationButton({
    required this.texts,
    required this.isLoading,
    required this.onPressed,
  });

  final AppTextValues texts;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8B66B).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE8B66B).withValues(alpha: 0.18),
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isLoading ? 0.72 : 1,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isLoading
                  ? Row(
                      key: const ValueKey('loading-location'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Color(0xFFE8B66B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Buscando ubicación...',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('use-location'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFFE8B66B),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Usar mi ubicación',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
