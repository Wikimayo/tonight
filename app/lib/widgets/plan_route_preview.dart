import 'package:flutter/material.dart';

import '../models/plan_model.dart';
import 'glass_panel.dart';

class PlanRoutePreview extends StatelessWidget {
  const PlanRoutePreview({required this.plan, super.key});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final steps = plan.itinerarySteps.take(3).toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 560),
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
      child: GlassPanel(
        padding: const EdgeInsets.all(22),
        borderRadius: 32,
        opacity: 0.055,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: Color(0xFFE8B66B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ruta del plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                _DistancePill(distance: plan.estimatedDistance),
              ],
            ),
            const SizedBox(height: 22),
            ...steps.indexed.map((entry) {
              final index = entry.$1;
              final step = entry.$2;

              return _RouteStep(
                icon: _iconForIndex(index),
                number: index + 1,
                text: step,
                isLast: index == steps.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _iconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.local_cafe_rounded;
      case 1:
        return Icons.explore_rounded;
      case 2:
      default:
        return Icons.nightlife_rounded;
    }
  }
}

class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.distance});

  final String distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, color: Color(0xFFF1D7A6), size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              distance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFFF1D7A6),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStep extends StatelessWidget {
  const _RouteStep({
    required this.icon,
    required this.number,
    required this.text,
    required this.isLast,
  });

  final IconData icon;
  final int number;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: number == 1
                        ? const Color(0xFFE8B66B)
                        : const Color(0xFFE8B66B).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: const Color(0xFFE8B66B).withValues(alpha: 0.24),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: number == 1
                        ? const Color(0xFF100D10)
                        : const Color(0xFFE8B66B),
                    size: 19,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFE8B66B).withValues(alpha: 0.42),
                            Colors.white.withValues(alpha: 0.06),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parada $number',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFE8B66B),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
