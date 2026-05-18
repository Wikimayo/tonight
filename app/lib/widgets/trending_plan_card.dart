import 'package:flutter/material.dart';

import '../services/mock_trending_service.dart';

class TrendingPlanCard extends StatefulWidget {
  const TrendingPlanCard({
    required this.trendingPlan,
    required this.onTap,
    super.key,
  });

  final TrendingPlan trendingPlan;
  final VoidCallback onTap;

  @override
  State<TrendingPlanCard> createState() => _TrendingPlanCardState();
}

class _TrendingPlanCardState extends State<TrendingPlanCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.trendingPlan.plan;

    return AnimatedScale(
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      scale: isPressed ? 0.975 : 1,
      child: SizedBox(
        width: 286,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) {
              setState(() {
                isPressed = value;
              });
            },
            borderRadius: BorderRadius.circular(32),
            child: Ink(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE8B66B).withValues(alpha: 0.23),
                    Colors.white.withValues(alpha: 0.085),
                    const Color(0xFF1A1021).withValues(alpha: 0.96),
                  ],
                  stops: const [0, 0.42, 1],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MoodIcon(mood: plan.mood),
                      const Spacer(),
                      _Tag(label: widget.trendingPlan.tag),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    plan.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    plan.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniPill(
                        icon: Icons.auto_awesome_rounded,
                        text: plan.mood,
                      ),
                      _MiniPill(
                        icon: Icons.location_on_rounded,
                        text: plan.location,
                      ),
                    ],
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

class _MoodIcon extends StatelessWidget {
  const _MoodIcon({required this.mood});

  final String mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8B66B).withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(_iconForMood(mood), color: const Color(0xFF120D10), size: 22),
    );
  }

  IconData _iconForMood(String mood) {
    switch (mood) {
      case 'Cita':
        return Icons.favorite_rounded;
      case 'Grupo':
        return Icons.diversity_3_rounded;
      case 'Solo':
        return Icons.self_improvement_rounded;
      case 'Viaje':
        return Icons.flight_takeoff_rounded;
      case 'Sorpresa':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.local_fire_department_rounded;
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFFF1D7A6),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 146),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFF1D7A6), size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
