import 'package:flutter/material.dart';

import '../models/plan_model.dart';
import '../services/local_plan_storage.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/glass_panel.dart';
import 'plan_detail_screen.dart';

class SavedPlansScreen extends StatefulWidget {
  const SavedPlansScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  State<SavedPlansScreen> createState() => _SavedPlansScreenState();
}

class _SavedPlansScreenState extends State<SavedPlansScreen> {
  static const List<String> filters = [
    'Todos',
    'Favoritos',
    'Historial',
    'Cita',
    'Amigos',
    'Solo',
    'Chill',
    'Fiesta',
    'Sorpresa',
    'Viaje',
    'Grupo',
  ];

  final TextEditingController searchController = TextEditingController();
  late Future<_SavedPlansData> savedPlansFuture;
  String selectedFilter = 'Todos';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    savedPlansFuture = _loadSavedPlans();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<_SavedPlansData> _loadSavedPlans() async {
    final results = await Future.wait([
      LocalPlanStorage.getHistory(),
      LocalPlanStorage.getFavorites(),
    ]);

    return _SavedPlansData(history: results[0], favorites: results[1]);
  }

  void _refreshSavedPlans() {
    setState(() {
      savedPlansFuture = _loadSavedPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                if (widget.showBackButton) ...[
                  _BackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(height: 26),
                ] else
                  const SizedBox(height: 10),
                Text(
                  'Guardados',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tus planes recientes y favoritos viven aquí.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                _SearchField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _FilterChips(
                  filters: filters,
                  selectedFilter: selectedFilter,
                  onSelected: (filter) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: FutureBuilder<_SavedPlansData>(
                    future: savedPlansFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: AppEmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'No pudimos cargar tus planes',
                            message:
                                'Algo falló leyendo tus datos locales. Inténtalo de nuevo en un momento.',
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE8B66B),
                          ),
                        );
                      }

                      final savedPlans = snapshot.data!;
                      final viewData = _filterSavedPlans(savedPlans);

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildSavedPlanSections(viewData),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPlanDetail(PlanModel plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlanDetailScreen(plan: plan)),
    );

    if (!mounted) {
      return;
    }

    _refreshSavedPlans();
  }

  _SavedPlansViewData _filterSavedPlans(_SavedPlansData savedPlans) {
    final normalizedQuery = _normalize(searchQuery);
    final filtersAreActive =
        selectedFilter != 'Todos' || normalizedQuery.isNotEmpty;

    var history = savedPlans.history.where((plan) {
      return _matchesSearch(plan, normalizedQuery) &&
          _matchesMoodFilter(plan, selectedFilter);
    }).toList();
    var favorites = savedPlans.favorites.where((plan) {
      return _matchesSearch(plan, normalizedQuery) &&
          _matchesMoodFilter(plan, selectedFilter);
    }).toList();

    if (selectedFilter == 'Favoritos') {
      history = const [];
    } else if (selectedFilter == 'Historial') {
      favorites = const [];
    }

    final combined = _dedupePlans([...favorites, ...history]);

    return _SavedPlansViewData(
      history: history,
      favorites: favorites,
      combined: combined,
      filtersAreActive: filtersAreActive,
    );
  }

  List<Widget> _buildSavedPlanSections(_SavedPlansViewData viewData) {
    if (viewData.filtersAreActive) {
      if (viewData.combined.isEmpty) {
        return const [
          AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No encontramos ningún plan con esos filtros.',
            message: 'Prueba con otro mood, ubicación o palabra clave.',
          ),
        ];
      }

      return [
        _SavedSection(
          title: 'Resultados',
          icon: Icons.travel_explore_rounded,
          plans: viewData.combined,
          onPlanTap: _openPlanDetail,
          showEmptyState: false,
        ),
      ];
    }

    return [
      _SavedSection(
        title: 'Historial',
        icon: Icons.history_rounded,
        plans: viewData.history,
        onPlanTap: _openPlanDetail,
      ),
      const SizedBox(height: 30),
      _SavedSection(
        title: 'Favoritos',
        icon: Icons.favorite_rounded,
        plans: viewData.favorites,
        onPlanTap: _openPlanDetail,
      ),
    ];
  }

  bool _matchesSearch(PlanModel plan, String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchableText = [
      plan.title,
      plan.description,
      plan.mood,
      plan.location,
      plan.moment,
      plan.vibe,
    ].map(_normalize).join(' ');

    return searchableText.contains(normalizedQuery);
  }

  bool _matchesMoodFilter(PlanModel plan, String filter) {
    const moodFilters = {
      'Cita',
      'Amigos',
      'Solo',
      'Chill',
      'Fiesta',
      'Sorpresa',
      'Viaje',
      'Grupo',
    };

    if (!moodFilters.contains(filter)) {
      return true;
    }

    return plan.mood == filter;
  }

  List<PlanModel> _dedupePlans(List<PlanModel> plans) {
    final seenIds = <String>{};
    final uniquePlans = <PlanModel>[];

    for (final plan in plans) {
      if (seenIds.add(plan.id)) {
        uniquePlans.add(plan);
      }
    }

    return uniquePlans;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class _SavedPlansData {
  const _SavedPlansData({required this.history, required this.favorites});

  final List<PlanModel> history;
  final List<PlanModel> favorites;
}

class _SavedPlansViewData {
  const _SavedPlansViewData({
    required this.history,
    required this.favorites,
    required this.combined,
    required this.filtersAreActive,
  });

  final List<PlanModel> history;
  final List<PlanModel> favorites;
  final List<PlanModel> combined;
  final bool filtersAreActive;
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      cursorColor: const Color(0xFFE8B66B),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE8B66B)),
        hintText: 'Buscar planes...',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.42),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.055),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFE8B66B), width: 1.2),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected
                  ? const Color(0xFFE8B66B)
                  : Colors.white.withValues(alpha: 0.065),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => onSelected(filter),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE8B66B)
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? const Color(0xFF100D10)
                          : Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SavedSection extends StatelessWidget {
  const _SavedSection({
    required this.title,
    required this.icon,
    required this.plans,
    required this.onPlanTap,
    this.showEmptyState = true,
  });

  final String title;
  final IconData icon;
  final List<PlanModel> plans;
  final ValueChanged<PlanModel> onPlanTap;
  final bool showEmptyState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
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
            ),
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
        if (plans.isEmpty && showEmptyState)
          const _EmptyState()
        else
          ...plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SavedPlanCard(plan: plan, onTap: () => onPlanTap(plan)),
            ),
          ),
      ],
    );
  }
}

class _SavedPlanCard extends StatelessWidget {
  const _SavedPlanCard({required this.plan, required this.onTap});

  final PlanModel plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: GlassPanel(
          padding: const EdgeInsets.all(20),
          borderRadius: 30,
          opacity: 0.055,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: const Color(0xFFE8B66B).withValues(alpha: 0.19),
                      ),
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: Color(0xFFE8B66B),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      plan.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniTag(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Mood',
                    value: plan.mood,
                  ),
                  _MiniTag(
                    icon: Icons.location_on_rounded,
                    label: 'Ubicación',
                    value: plan.location,
                  ),
                  _MiniTag(
                    icon: Icons.wb_twilight_rounded,
                    label: 'Momento',
                    value: plan.moment,
                  ),
                  _MiniTag(
                    icon: Icons.payments_rounded,
                    label: 'Coste',
                    value: plan.estimatedCost,
                  ),
                  _MiniTag(
                    icon: Icons.schedule_rounded,
                    label: 'Duración',
                    value: plan.estimatedDuration,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8B66B).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFF1D7A6), size: 14),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFFF1D7A6),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      borderRadius: 30,
      opacity: 0.04,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFE8B66B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.bookmarks_rounded,
                color: Color(0xFFE8B66B),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no has guardado ningún plan',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando crees o marques favoritos, aparecerán aquí.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.58),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todavía no hay planes guardados.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.38),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
