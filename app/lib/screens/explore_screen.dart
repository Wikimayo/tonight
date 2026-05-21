import 'package:flutter/material.dart';

import '../core/constants/app_texts.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import '../services/mock_trending_service.dart';
import '../utils/tonight_page_route.dart';
import '../widgets/glass_panel.dart';
import '../widgets/trending_plan_card.dart';
import 'plan_detail_screen.dart';
import 'plan_setup_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final List<TrendingPlan> trendingPlans =
      MockTrendingService.getTrendingPlans();

  final List<_MoodCategory> categories = const [
    _MoodCategory(
      title: 'Cita',
      description: 'Planes con intención, química y cero rigidez.',
      icon: Icons.favorite_rounded,
      accent: Color(0xFFFF8AAE),
    ),
    _MoodCategory(
      title: 'Amigos',
      description: 'Ideas fáciles para activar el grupo sin debate eterno.',
      icon: Icons.groups_rounded,
      accent: Color(0xFFFFC56E),
    ),
    _MoodCategory(
      title: 'Solo',
      description: 'Salidas para resetear, explorar y elegirte un rato.',
      icon: Icons.self_improvement_rounded,
      accent: Color(0xFF8AD7FF),
    ),
    _MoodCategory(
      title: 'Chill',
      description: 'Planes suaves, acogedores y con buen ritmo.',
      icon: Icons.spa_rounded,
      accent: Color(0xFFA8E6A1),
    ),
    _MoodCategory(
      title: 'Fiesta',
      description: 'Rutas con energía, música y final abierto.',
      icon: Icons.local_fire_department_rounded,
      accent: Color(0xFFFF7A59),
    ),
    _MoodCategory(
      title: 'Sorpresa',
      description: 'Una idea inesperada cuando no quieres decidir demasiado.',
      icon: Icons.auto_awesome_rounded,
      accent: Color(0xFFE8B66B),
    ),
    _MoodCategory(
      title: 'Viaje',
      description: 'Descubre una ciudad sin caer en el checklist automático.',
      icon: Icons.flight_takeoff_rounded,
      accent: Color(0xFFB493FF),
    ),
    _MoodCategory(
      title: 'Grupo',
      description: 'Para poner de acuerdo a varias personas por fin.',
      icon: Icons.diversity_3_rounded,
      accent: Color(0xFF6EE7D8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(LanguageService.currentLanguage);

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texts.explore,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  texts.exploreSubtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                _TrendingExplorer(
                  title: texts.trending,
                  plans: trendingPlans,
                  onPlanTap: _openTrendingPlan,
                ),
                const SizedBox(height: 32),
                _MoodCategories(
                  texts: texts,
                  categories: categories,
                  onCategoryTap: _openMoodSetup,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTrendingPlan(TrendingPlan trendingPlan) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      tonightPageRoute<void>((_) => PlanDetailScreen(plan: trendingPlan.plan)),
    );
  }

  void _openMoodSetup(String mood) {
    HapticService.selectionClick();
    Navigator.of(
      context,
    ).push(tonightPageRoute<void>((_) => PlanSetupScreen(initialMood: mood)));
  }
}

class _TrendingExplorer extends StatelessWidget {
  const _TrendingExplorer({
    required this.title,
    required this.plans,
    required this.onPlanTap,
  });

  final String title;
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
          Row(
            children: [
              _SectionIcon(icon: Icons.local_fire_department_rounded),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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

class _MoodCategories extends StatelessWidget {
  const _MoodCategories({
    required this.texts,
    required this.categories,
    required this.onCategoryTap,
  });

  final AppTextValues texts;
  final List<_MoodCategory> categories;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionIcon(icon: Icons.auto_awesome_rounded),
            const SizedBox(width: 12),
            Text(
              texts.startByVibe,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Toca una categoría y Tonight prepara el plan con ese mood desde el primer paso.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.64),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 560
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: categories.map((category) {
                return SizedBox(
                  width: cardWidth,
                  child: _MoodCategoryCard(
                    texts: texts,
                    category: category,
                    onTap: () => onCategoryTap(category.title),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MoodCategoryCard extends StatefulWidget {
  const _MoodCategoryCard({
    required this.texts,
    required this.category,
    required this.onTap,
  });

  final AppTextValues texts;
  final _MoodCategory category;
  final VoidCallback onTap;

  @override
  State<_MoodCategoryCard> createState() => _MoodCategoryCardState();
}

class _MoodCategoryCardState extends State<_MoodCategoryCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return AnimatedScale(
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      scale: isPressed ? 0.985 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: () {
            HapticService.selectionClick();
            widget.onTap();
          },
          onHighlightChanged: (value) {
            setState(() {
              isPressed = value;
            });
          },
          borderRadius: BorderRadius.circular(30),
          child: GlassPanel(
            padding: const EdgeInsets.all(18),
            borderRadius: 30,
            opacity: 0.052,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    category.accent.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.035),
                    Colors.black.withValues(alpha: 0.08),
                  ],
                  stops: const [0, 0.54, 1],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: category.accent.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: category.accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.texts.moodLabel(category.title),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            category.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.64),
                                  fontWeight: FontWeight.w600,
                                  height: 1.32,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.38),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodCategory {
  const _MoodCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
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
