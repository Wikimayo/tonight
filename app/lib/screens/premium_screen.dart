import 'package:flutter/material.dart';

import '../core/constants/app_texts.dart';
import '../services/analytics_service.dart';
import '../services/language_service.dart';
import '../services/haptic_service.dart';
import '../services/premium_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_cta_button.dart';
import '../widgets/tonight_app_bar.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const List<_PremiumBenefit> _benefits = [
    _PremiumBenefit(
      icon: Icons.all_inclusive_rounded,
      title: 'Planes ilimitados',
      description: 'Genera ideas sin el límite diario gratuito.',
    ),
    _PremiumBenefit(
      icon: Icons.auto_awesome_rounded,
      title: 'IA más personalizada',
      description: 'Recomendaciones con más contexto y mejor intención.',
    ),
    _PremiumBenefit(
      icon: Icons.flight_takeoff_rounded,
      title: 'Modo viaje avanzado',
      description: 'Rutas más completas para descubrir ciudades nuevas.',
    ),
    _PremiumBenefit(
      icon: Icons.diversity_3_rounded,
      title: 'Planes para grupos',
      description:
          'Ideas pensadas para que varias personas se pongan de acuerdo.',
    ),
    _PremiumBenefit(
      icon: Icons.bolt_rounded,
      title: 'Acceso anticipado a nuevas funciones',
      description: 'Prueba antes las próximas capas de Tonight.',
    ),
  ];

  String selectedPlan = PremiumService.annualPlan;
  bool isLoadingPlan = true;

  @override
  void initState() {
    super.initState();
    const AnalyticsService().logPremiumScreenOpened();
    _loadSelectedPlan();
  }

  Future<void> _loadSelectedPlan() async {
    final plan = await PremiumService.getSelectedPlan();
    if (!mounted) {
      return;
    }

    setState(() {
      selectedPlan = plan;
      isLoadingPlan = false;
    });
  }

  Future<void> _selectPlan(String plan) async {
    HapticService.selectionClick();
    setState(() {
      selectedPlan = plan;
    });
    await PremiumService.setSelectedPlan(plan);
    await const AnalyticsService().logPremiumPlanSelected(plan: plan);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(LanguageService.currentLanguage);

    return Scaffold(
      appBar: TonightAppBar(
        title: texts.premium,
        backIcon: Icons.close_rounded,
        backTooltip: 'Cerrar',
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B1633), Color(0xFF0D0B11), Color(0xFF08080C)],
            stops: [0, 0.48, 1],
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
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroBadge(),
                        const SizedBox(height: 18),
                        Text(
                          texts.premiumTitle,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          texts.premiumSubtitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontWeight: FontWeight.w700,
                                height: 1.28,
                              ),
                        ),
                        const SizedBox(height: 24),
                        _PricingSelector(
                          selectedPlan: selectedPlan,
                          isLoading: isLoadingPlan,
                          onSelected: _selectPlan,
                        ),
                        const SizedBox(height: 26),
                        Text(
                          texts.premiumIncluded,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 14),
                        ..._benefits.map((benefit) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BenefitCard(benefit: benefit),
                          );
                        }),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                PrimaryCtaButton(
                  label: 'Activar próximamente',
                  onPressed: _showComingSoon,
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: 'Seguir gratis',
                  onPressed: _continueFree,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon() {
    HapticService.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF17131D),
        content: Text('Los pagos llegarán próximamente.'),
      ),
    );
  }

  Future<void> _continueFree() async {
    HapticService.lightImpact();
    await const AnalyticsService().logPremiumContinueFree();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }
}

class _PremiumBenefit {
  const _PremiumBenefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _HeroBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        'Freemium preparado',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFFE8B66B),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PricingSelector extends StatelessWidget {
  const _PricingSelector({
    required this.selectedPlan,
    required this.isLoading,
    required this.onSelected,
  });

  final String selectedPlan;
  final bool isLoading;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PricingCard(
            title: 'Mensual',
            price: '4,99 €/mes',
            selected: !isLoading && selectedPlan == PremiumService.monthlyPlan,
            onTap: () => onSelected(PremiumService.monthlyPlan),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PricingCard(
            title: 'Anual',
            price: '29,99 €/año',
            badge: 'Ahorra 50%',
            selected: isLoading || selectedPlan == PremiumService.annualPlan,
            onTap: () => onSelected(PremiumService.annualPlan),
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFFE8B66B)
        : Colors.white.withValues(alpha: 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  selected
                      ? const Color(0xFFE8B66B).withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.035),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: borderColor, width: selected ? 1.3 : 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE8B66B).withValues(alpha: 0.18),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected
                          ? const Color(0xFFE8B66B)
                          : Colors.white.withValues(alpha: 0.42),
                      size: 18,
                    ),
                    const Spacer(),
                    if (badge != null) _SavingsBadge(label: badge!),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFF1D7A6),
                    fontWeight: FontWeight.w900,
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

class _SavingsBadge extends StatelessWidget {
  const _SavingsBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF100D10),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.benefit});

  final _PremiumBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      opacity: 0.05,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE8B66B).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
              ),
            ),
            child: Icon(benefit.icon, color: const Color(0xFFE8B66B), size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  benefit.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w600,
                    height: 1.38,
                  ),
                ),
              ],
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
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
