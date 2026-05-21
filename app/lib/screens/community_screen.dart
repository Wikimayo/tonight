import 'package:flutter/material.dart';

import '../core/constants/app_texts.dart';
import '../models/plan_model.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import '../services/mock_community_service.dart';
import '../utils/text_sanitizer.dart';
import '../utils/tonight_page_route.dart';
import '../widgets/glass_panel.dart';
import 'plan_detail_screen.dart';
import 'plan_setup_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const List<String> filters = [
    'Todos',
    'Madrid',
    'Barcelona',
    'Valencia',
    'Cita',
    'Amigos',
    'Chill',
    'Viaje',
  ];

  late final List<CommunityPlan> plans = MockCommunityService.getPublicPlans();
  String selectedFilter = 'Todos';

  List<CommunityPlan> get filteredPlans {
    if (selectedFilter == 'Todos') {
      return plans;
    }

    return plans.where((communityPlan) {
      final plan = communityPlan.plan;
      return plan.location == selectedFilter || plan.mood == selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(LanguageService.currentLanguage);
    final visiblePlans = filteredPlans;

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
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            itemCount: visiblePlans.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CommunityHeader(
                  texts: texts,
                  filters: filters,
                  selectedFilter: selectedFilter,
                  onSelected: _selectFilter,
                );
              }

              final communityPlan = visiblePlans[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CommunityPlanCard(
                  texts: texts,
                  communityPlan: communityPlan,
                  onOpen: () => _openPlan(communityPlan.plan),
                  onUsePlan: () => _usePlan(communityPlan.plan),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _selectFilter(String filter) {
    HapticService.selectionClick();
    setState(() {
      selectedFilter = filter;
    });
  }

  void _openPlan(PlanModel plan) {
    HapticService.lightImpact();
    Navigator.of(
      context,
    ).push(tonightPageRoute<void>((_) => PlanDetailScreen(plan: plan)));
  }

  void _usePlan(PlanModel plan) {
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
}

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({
    required this.texts,
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final AppTextValues texts;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts.community,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Planes que están probando otros usuarios',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Comunidad próximamente en tiempo real',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFE8B66B),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          _CommunityFilters(
            texts: texts,
            filters: filters,
            selectedFilter: selectedFilter,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _CommunityFilters extends StatelessWidget {
  const _CommunityFilters({
    required this.texts,
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final AppTextValues texts;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(texts.filterLabel(filter)),
              onSelected: (_) => onSelected(filter),
              showCheckmark: false,
              backgroundColor: Colors.white.withValues(alpha: 0.065),
              selectedColor: const Color(0xFFE8B66B),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFFE8B66B)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF100D10) : Colors.white,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CommunityPlanCard extends StatelessWidget {
  const _CommunityPlanCard({
    required this.texts,
    required this.communityPlan,
    required this.onOpen,
    required this.onUsePlan,
  });

  final AppTextValues texts;
  final CommunityPlan communityPlan;
  final VoidCallback onOpen;
  final VoidCallback onUsePlan;

  @override
  Widget build(BuildContext context) {
    final plan = communityPlan.plan;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(28),
        child: GlassPanel(
          padding: const EdgeInsets.all(18),
          borderRadius: 28,
          opacity: 0.055,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CommunityTag(label: communityPlan.tag),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE8B66B),
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${communityPlan.likes}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                TextSanitizer.clean(plan.title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                TextSanitizer.clean(plan.description),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.66),
                  fontWeight: FontWeight.w600,
                  height: 1.36,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CommunityMetaPill(
                    icon: Icons.auto_awesome_rounded,
                    text: texts.moodLabel(TextSanitizer.clean(plan.mood)),
                  ),
                  _CommunityMetaPill(
                    icon: Icons.location_on_rounded,
                    text: TextSanitizer.clean(plan.location),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _UseCommunityPlanButton(label: texts.usePlan, onTap: onUsePlan),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityTag extends StatelessWidget {
  const _CommunityTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF100D10),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CommunityMetaPill extends StatelessWidget {
  const _CommunityMetaPill({required this.icon, required this.text});

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

class _UseCommunityPlanButton extends StatelessWidget {
  const _UseCommunityPlanButton({required this.label, required this.onTap});

  final String label;
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
                label,
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
