import 'package:flutter/material.dart';

import '../core/constants/app_texts.dart';
import '../models/plan_model.dart';
import '../models/user_insights_model.dart';
import '../services/analytics_service.dart';
import '../services/daily_plan_service.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import '../services/local_plan_storage.dart';
import '../services/mock_trending_service.dart';
import '../services/onboarding_service.dart';
import '../services/premium_service.dart';
import '../services/usage_limits_service.dart';
import '../services/user_insights_service.dart';
import '../services/user_preferences_service.dart';
import '../utils/text_sanitizer.dart';
import '../utils/tonight_page_route.dart';
import '../widgets/mood_chip.dart';
import '../widgets/primary_cta_button.dart';
import '../widgets/trending_plan_card.dart';
import 'chat_plan_screen.dart';
import 'generating_plan_screen.dart';
import 'plan_detail_screen.dart';
import 'premium_screen.dart';
import 'plan_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedMood = 'Cita';
  late final List<TrendingPlan> trendingPlans =
      MockTrendingService.getTrendingPlans();
  late final PlanModel dailyPlan = DailyPlanService.getDailyPlan();
  late final Future<String?> favoriteVibeFuture =
      OnboardingService.getFavoriteVibe();
  late Future<String> usageSummaryFuture = _loadUsageSummaryText();
  late Future<PlanModel?> lastGeneratedPlanFuture =
      LocalPlanStorage.getLastGeneratedPlan();
  late Future<UserInsightsModel?> userInsightsFuture =
      UserInsightsService.getInsights();

  final List<String> moods = const [
    'Cita',
    'Amigos',
    'Solo',
    'Chill',
    'Fiesta',
    'Sorpresa',
    'Viaje',
    'Grupo',
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, language, child) {
        final texts = AppTexts.of(language);

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF211229),
                  Color(0xFF0D0B11),
                  Color(0xFF08080C),
                ],
                stops: [0, 0.48, 1],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroHeader(texts: texts),
                            const SizedBox(height: 28),
                            _FavoriteVibeSection(
                              favoriteVibeFuture: favoriteVibeFuture,
                              onCreatePlan: _openFavoriteVibePlan,
                            ),
                            _SurpriseMeCard(
                              title: texts.surpriseMe,
                              onTap: _openSurprisePlan,
                            ),
                            const SizedBox(height: 14),
                            _ChatPlanEntryCard(onTap: _openChatPlan),
                            const SizedBox(height: 18),
                            _UsageLimitCard(
                              usageSummaryFuture: usageSummaryFuture,
                            ),
                            _LastPlanSection(
                              title: texts.lastPlan,
                              lastPlanFuture: lastGeneratedPlanFuture,
                              onOpenPlan: _openLastGeneratedPlan,
                              onGenerateSimilar: _generateSimilarToLastPlan,
                            ),
                            _UserInsightsSection(
                              insightsFuture: userInsightsFuture,
                              onCreateRecommendedPlan:
                                  _openRecommendedInsightPlan,
                            ),
                            const SizedBox(height: 34),
                            _DailyPlanSection(
                              title: texts.planOfTheDay,
                              plan: dailyPlan,
                              onOpenPlan: _openDailyPlan,
                              onUsePlan: _useDailyPlan,
                            ),
                            const SizedBox(height: 34),
                            _TrendingSection(
                              plans: trendingPlans,
                              onPlanTap: _openTrendingPlan,
                            ),
                            const SizedBox(height: 34),
                            Text(
                              '¿Qué buscas ahora?',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.08,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Elige el mood y Tonight prepara el punto de partida.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    height: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: moods.map((mood) {
                                return MoodChip(
                                  label: texts.moodLabel(mood),
                                  iconKey: mood,
                                  isSelected: selectedMood == mood,
                                  onTap: () {
                                    setState(() {
                                      selectedMood = mood;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    PrimaryCtaButton(
                      label: texts.createPlan,
                      onPressed: () async {
                        await Navigator.of(context).push(
                          tonightPageRoute<void>(
                            (_) => PlanSetupScreen(mood: selectedMood),
                          ),
                        );
                        _refreshHomeSnapshots();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTrendingPlan(TrendingPlan trendingPlan) async {
    HapticService.lightImpact();
    await Navigator.of(context).push(
      tonightPageRoute<void>((_) => PlanDetailScreen(plan: trendingPlan.plan)),
    );
    _refreshLastGeneratedPlan();
  }

  Future<void> _openSurprisePlan() async {
    HapticService.mediumImpact();
    if (!await _canGenerateOrShowPremium(source: 'home_surprise')) {
      return;
    }

    final preferences = await UserPreferencesService.getPreferences();
    if (!mounted) {
      return;
    }

    await const AnalyticsService().logSurprisePlanUsed();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      tonightPageRoute<void>(
        (_) => GeneratingPlanScreen(
          mood: 'Sorpresa',
          budget: preferences.defaultBudget ?? '€€',
          time: preferences.defaultTime ?? '2h',
          distance: preferences.defaultDistance ?? 'Media',
          moment: 'Ahora',
          location: preferences.defaultLocation ?? 'tu zona',
          weather: 'Automático',
        ),
      ),
    );
    _refreshHomeSnapshots();
  }

  Future<void> _openChatPlan() async {
    HapticService.lightImpact();
    await Navigator.of(
      context,
    ).push(tonightPageRoute<void>((_) => const ChatPlanScreen()));
    _refreshHomeSnapshots();
  }

  Future<void> _openDailyPlan() async {
    HapticService.lightImpact();
    await Navigator.of(
      context,
    ).push(tonightPageRoute<void>((_) => PlanDetailScreen(plan: dailyPlan)));
    _refreshLastGeneratedPlan();
  }

  void _useDailyPlan() {
    HapticService.lightImpact();
    Navigator.of(context).push(
      tonightPageRoute<void>(
        (_) => PlanSetupScreen(
          initialMood: dailyPlan.mood,
          initialLocation: dailyPlan.location,
          initialMoment: dailyPlan.moment,
          initialBudget: dailyPlan.budget,
          initialTime: dailyPlan.time,
          initialDistance: dailyPlan.distance,
          initialWeather: dailyPlan.weather,
          initialGroupSize: dailyPlan.groupSize,
        ),
      ),
    );
  }

  void _openFavoriteVibePlan(String vibe) {
    HapticService.lightImpact();
    Navigator.of(
      context,
    ).push(tonightPageRoute<void>((_) => PlanSetupScreen(initialMood: vibe)));
  }

  Future<void> _openLastGeneratedPlan(PlanModel plan) async {
    HapticService.lightImpact();
    await Navigator.of(
      context,
    ).push(tonightPageRoute<void>((_) => PlanDetailScreen(plan: plan)));
    _refreshLastGeneratedPlan();
  }

  Future<void> _generateSimilarToLastPlan(PlanModel plan) async {
    HapticService.lightImpact();
    await Navigator.of(context).push(
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
    _refreshHomeSnapshots();
  }

  Future<void> _openRecommendedInsightPlan(UserInsightsModel insights) async {
    HapticService.mediumImpact();
    if (!await _canGenerateOrShowPremium(source: 'home_insights')) {
      return;
    }
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      tonightPageRoute<void>(
        (_) => GeneratingPlanScreen(
          mood: insights.mood,
          budget: insights.budget,
          time: insights.time,
          distance: insights.distance,
          moment: insights.moment,
          location: insights.location,
          weather: insights.weather,
          groupSize: insights.groupSize,
        ),
      ),
    );
    _refreshHomeSnapshots();
  }

  Future<bool> _canGenerateOrShowPremium({required String source}) async {
    final canGenerate = await UsageLimitsService.canGeneratePlan();
    if (!mounted) {
      return false;
    }

    if (!canGenerate) {
      await const AnalyticsService().logFreePlanLimitReached(source: source);
      if (!mounted) {
        return false;
      }

      await Navigator.of(
        context,
      ).push(tonightPageRoute<void>((_) => const PremiumScreen()));
      _refreshHomeSnapshots();
      return false;
    }

    return true;
  }

  Future<String> _loadUsageSummaryText() async {
    final isPremium = await PremiumService.isPremium();
    final remainingPlans = await UsageLimitsService.getRemainingPlansToday();
    await const AnalyticsService().logRemainingFreePlansViewed(
      remainingPlans: remainingPlans,
      dailyLimit: UsageLimitsService.getDailyLimit(),
      isPremium: isPremium,
      source: 'home',
    );

    if (isPremium) {
      return 'Premium activo · planes ilimitados';
    }

    return 'Te quedan $remainingPlans planes gratis hoy';
  }

  void _refreshLastGeneratedPlan() {
    if (!mounted) {
      return;
    }

    setState(() {
      lastGeneratedPlanFuture = LocalPlanStorage.getLastGeneratedPlan();
      userInsightsFuture = UserInsightsService.getInsights();
    });
  }

  void _refreshHomeSnapshots() {
    if (!mounted) {
      return;
    }

    setState(() {
      usageSummaryFuture = _loadUsageSummaryText();
      lastGeneratedPlanFuture = LocalPlanStorage.getLastGeneratedPlan();
      userInsightsFuture = UserInsightsService.getInsights();
    });
  }
}

class _UsageLimitCard extends StatelessWidget {
  const _UsageLimitCard({required this.usageSummaryFuture});

  final Future<String> usageSummaryFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: usageSummaryFuture,
      builder: (context, snapshot) {
        final text = snapshot.data ?? 'Calculando planes gratis...';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFE8B66B),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserInsightsSection extends StatelessWidget {
  const _UserInsightsSection({
    required this.insightsFuture,
    required this.onCreateRecommendedPlan,
  });

  final Future<UserInsightsModel?> insightsFuture;
  final ValueChanged<UserInsightsModel> onCreateRecommendedPlan;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserInsightsModel?>(
      future: insightsFuture,
      builder: (context, snapshot) {
        final insights = snapshot.data;
        if (insights == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tonight aprende de ti',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _UserInsightsCard(
                insights: insights,
                onCreateRecommendedPlan: () =>
                    onCreateRecommendedPlan(insights),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserInsightsCard extends StatelessWidget {
  const _UserInsightsCard({
    required this.insights,
    required this.onCreateRecommendedPlan,
  });

  final UserInsightsModel insights;
  final VoidCallback onCreateRecommendedPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3A2143).withValues(alpha: 0.92),
            const Color(0xFF15121C).withValues(alpha: 0.98),
            const Color(0xFFE8B66B).withValues(alpha: 0.14),
          ],
          stops: const [0, 0.62, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Color(0xFFE8B66B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insights.highlights.first,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...insights.highlights.skip(1).map((highlight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFE8B66B),
                    size: 16,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      highlight,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w700,
                        height: 1.32,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DailyMetaPill(
                icon: Icons.auto_awesome_rounded,
                text: insights.mood,
              ),
              _DailyMetaPill(
                icon: Icons.location_on_rounded,
                text: insights.location,
              ),
              _DailyMetaPill(
                icon: Icons.wb_twilight_rounded,
                text: insights.moment,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RecommendedPlanButton(onTap: onCreateRecommendedPlan),
        ],
      ),
    );
  }
}

class _RecommendedPlanButton extends StatelessWidget {
  const _RecommendedPlanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8B66B),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF100D10),
                size: 18,
              ),
              const SizedBox(width: 9),
              Text(
                'Crear plan recomendado',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF100D10),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastPlanSection extends StatelessWidget {
  const _LastPlanSection({
    required this.title,
    required this.lastPlanFuture,
    required this.onOpenPlan,
    required this.onGenerateSimilar,
  });

  final String title;
  final Future<PlanModel?> lastPlanFuture;
  final ValueChanged<PlanModel> onOpenPlan;
  final ValueChanged<PlanModel> onGenerateSimilar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlanModel?>(
      future: lastPlanFuture,
      builder: (context, snapshot) {
        final plan = snapshot.data;
        if (plan == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _LastPlanCard(
                plan: plan,
                onOpenPlan: () => onOpenPlan(plan),
                onGenerateSimilar: () => onGenerateSimilar(plan),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LastPlanCard extends StatelessWidget {
  const _LastPlanCard({
    required this.plan,
    required this.onOpenPlan,
    required this.onGenerateSimilar,
  });

  final PlanModel plan;
  final VoidCallback onOpenPlan;
  final VoidCallback onGenerateSimilar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.075),
            const Color(0xFF3A2143).withValues(alpha: 0.72),
            const Color(0xFFE8B66B).withValues(alpha: 0.12),
          ],
          stops: const [0, 0.62, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFFE8B66B),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  TextSanitizer.clean(plan.title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            TextSanitizer.clean(plan.description),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
              fontWeight: FontWeight.w700,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DailyMetaPill(
                icon: Icons.auto_awesome_rounded,
                text: TextSanitizer.clean(plan.mood),
              ),
              _DailyMetaPill(
                icon: Icons.location_on_rounded,
                text: TextSanitizer.clean(plan.location),
              ),
              _DailyMetaPill(
                icon: Icons.wb_twilight_rounded,
                text: TextSanitizer.clean(plan.moment),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LastPlanActionButton(
                label: 'Ver plan',
                icon: Icons.open_in_new_rounded,
                isPrimary: true,
                onTap: onOpenPlan,
              ),
              _LastPlanActionButton(
                label: 'Generar parecido',
                icon: Icons.tune_rounded,
                isPrimary: false,
                onTap: onGenerateSimilar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LastPlanActionButton extends StatelessWidget {
  const _LastPlanActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary
        ? const Color(0xFFE8B66B)
        : Colors.white.withValues(alpha: 0.075);
    final foregroundColor = isPrimary ? const Color(0xFF100D10) : Colors.white;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPrimary
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor, size: 17),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteVibeSection extends StatelessWidget {
  const _FavoriteVibeSection({
    required this.favoriteVibeFuture,
    required this.onCreatePlan,
  });

  final Future<String?> favoriteVibeFuture;
  final ValueChanged<String> onCreatePlan;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: favoriteVibeFuture,
      builder: (context, snapshot) {
        final favoriteVibe = snapshot.data;
        if (favoriteVibe == null || favoriteVibe.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: _FavoriteVibeCard(
            favoriteVibe: favoriteVibe,
            onCreatePlan: () => onCreatePlan(favoriteVibe),
          ),
        );
      },
    );
  }
}

class _FavoriteVibeCard extends StatelessWidget {
  const _FavoriteVibeCard({
    required this.favoriteVibe,
    required this.onCreatePlan,
  });

  final String favoriteVibe;
  final VoidCallback onCreatePlan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.065),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onCreatePlan,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE8B66B).withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.045),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE8B66B),
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu vibe favorita: $favoriteVibe',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Crear plan con esta vibe',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFE8B66B),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFFE8B66B),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurpriseMeCard extends StatefulWidget {
  const _SurpriseMeCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  State<_SurpriseMeCard> createState() => _SurpriseMeCardState();
}

class _SurpriseMeCardState extends State<_SurpriseMeCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      scale: isPressed ? 0.985 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(34),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            setState(() {
              isPressed = value;
            });
          },
          borderRadius: BorderRadius.circular(34),
          child: Ink(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8B66B).withValues(alpha: 0.92),
                  const Color(0xFFFF7A59).withValues(alpha: 0.62),
                  const Color(0xFF211229).withValues(alpha: 0.96),
                ],
                stops: const [0, 0.48, 1],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Un plan rápido para ahora',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: const Icon(
                    Icons.shuffle_rounded,
                    color: Colors.white,
                    size: 20,
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

class _ChatPlanEntryCard extends StatelessWidget {
  const _ChatPlanEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        key: const ValueKey('home-chat-plan-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.075),
                const Color(0xFF2E1A36).withValues(alpha: 0.86),
                const Color(0xFFE8B66B).withValues(alpha: 0.10),
              ],
              stops: const [0, 0.62, 1],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Color(0xFFE8B66B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escribe lo que te apetece y Tonight lo convierte en plan.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.64),
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFFE8B66B),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyPlanSection extends StatelessWidget {
  const _DailyPlanSection({
    required this.title,
    required this.plan,
    required this.onOpenPlan,
    required this.onUsePlan,
  });

  final String title;
  final PlanModel plan;
  final VoidCallback onOpenPlan;
  final VoidCallback onUsePlan;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _DailyPlanCard(
            plan: plan,
            onOpenPlan: onOpenPlan,
            onUsePlan: onUsePlan,
          ),
        ],
      ),
    );
  }
}

class _DailyPlanCard extends StatefulWidget {
  const _DailyPlanCard({
    required this.plan,
    required this.onOpenPlan,
    required this.onUsePlan,
  });

  final PlanModel plan;
  final VoidCallback onOpenPlan;
  final VoidCallback onUsePlan;

  @override
  State<_DailyPlanCard> createState() => _DailyPlanCardState();
}

class _DailyPlanCardState extends State<_DailyPlanCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return AnimatedScale(
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      scale: isPressed ? 0.986 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(34),
        child: InkWell(
          onTap: widget.onOpenPlan,
          onHighlightChanged: (value) {
            setState(() {
              isPressed = value;
            });
          },
          borderRadius: BorderRadius.circular(34),
          child: Ink(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3A2143).withValues(alpha: 0.96),
                  const Color(0xFF17131D).withValues(alpha: 0.98),
                  const Color(0xFFE8B66B).withValues(alpha: 0.16),
                ],
                stops: const [0, 0.58, 1],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B66B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: const Color(
                            0xFFE8B66B,
                          ).withValues(alpha: 0.24),
                        ),
                      ),
                      child: const Icon(
                        Icons.today_rounded,
                        color: Color(0xFFE8B66B),
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    _DailyChip(label: 'Hoy'),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  plan.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.06,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  plan.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DailyMetaPill(
                      icon: Icons.auto_awesome_rounded,
                      text: plan.mood,
                    ),
                    _DailyMetaPill(
                      icon: Icons.location_on_rounded,
                      text: plan.location,
                    ),
                    _DailyMetaPill(
                      icon: Icons.wb_twilight_rounded,
                      text: plan.moment,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _UseDailyPlanButton(onTap: widget.onUsePlan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyChip extends StatelessWidget {
  const _DailyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF100D10),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DailyMetaPill extends StatelessWidget {
  const _DailyMetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFF1D7A6), size: 14),
          const SizedBox(width: 7),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UseDailyPlanButton extends StatelessWidget {
  const _UseDailyPlanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE8B66B).withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.tune_rounded,
                color: Color(0xFFE8B66B),
                size: 18,
              ),
              const SizedBox(width: 9),
              Text(
                'Usar este plan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingSection extends StatelessWidget {
  const _TrendingSection({required this.plans, required this.onPlanTap});

  final List<TrendingPlan> plans;
  final ValueChanged<TrendingPlan> onPlanTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending ahora',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 320,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 10),
              itemCount: plans.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final trendingPlan = plans[index];

                return TrendingPlanCard(
                  trendingPlan: trendingPlan,
                  onTap: () => onPlanTap(trendingPlan),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.texts});

  final AppTextValues texts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Text(
            'AI plan finder',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFFE8B66B),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          texts.appName,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            height: 0.96,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          texts.tagline,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Deja que la IA encuentre el plan perfecto para este momento.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.74),
            fontSize: 19,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Mañana · Tarde · Noche',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFFE8B66B),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8B66B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            '2 planes gratis al día',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFF1D7A6),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
