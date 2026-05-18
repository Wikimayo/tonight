import 'package:flutter/material.dart';

import '../models/plan_model.dart';

class SharePlanCard extends StatelessWidget {
  const SharePlanCard({required this.plan, super.key});

  static const Size storySize = Size(390, 693.33);

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final steps = plan.itinerarySteps.take(3).toList();

    return SizedBox(
      width: storySize.width,
      height: storySize.height,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1232), Color(0xFF111019), Color(0xFF06070B)],
              stops: [0, 0.52, 1],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: -92,
                right: -96,
                child: _Glow(size: 250, color: Color(0xFFE8B66B)),
              ),
              const Positioned(
                bottom: -110,
                left: -105,
                child: _Glow(size: 280, color: Color(0xFF8F4FFF)),
              ),
              Positioned(
                left: 22,
                top: 76,
                bottom: 82,
                child: Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 30, 30, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFE8B66B,
                                ).withValues(alpha: 0.16),
                                blurRadius: 26,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Text(
                            'T',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tonight',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        _MoodBadge(mood: plan.mood),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _viralLineFor(plan.mood),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8B66B),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      plan.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 39,
                        fontWeight: FontWeight.w900,
                        height: 1.01,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      plan.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.66),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.32,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ContextLine(
                            icon: Icons.location_on_rounded,
                            text: plan.location,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ContextLine(
                            icon: Icons.wb_twilight_rounded,
                            text: plan.moment,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ContextLine(
                      icon: Icons.cloud_rounded,
                      text: 'Clima: ${plan.weather}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricChip(
                            icon: Icons.payments_rounded,
                            label: 'Coste',
                            value: plan.estimatedCost,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricChip(
                            icon: Icons.schedule_rounded,
                            label: 'Duración',
                            value: plan.estimatedDuration,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricChip(
                            icon: Icons.near_me_rounded,
                            label: 'Distancia',
                            value: plan.estimatedDistance,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ItineraryPanel(steps: steps),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Creado con Tonight',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE8B66B,
                            ).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(
                                0xFFE8B66B,
                              ).withValues(alpha: 0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.north_east_rounded,
                            color: Color(0xFFE8B66B),
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _viralLineFor(String mood) {
    switch (mood) {
      case 'Amigos':
        return 'El grupo por fin tiene plan.';
      case 'Solo':
        return 'Salir solo también cuenta.';
      case 'Chill':
        return 'Baja revoluciones. Sube el plan.';
      case 'Fiesta':
        return 'La noche empieza aquí.';
      case 'Sorpresa':
        return 'No preguntes. Solo ve.';
      case 'Viaje':
        return 'Viajar sin plan ya es opcional.';
      case 'Grupo':
        return 'Por fin el grupo se ha puesto de acuerdo.';
      case 'Cita':
      default:
        return 'La cita ya no se improvisa.';
    }
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.mood});

  final String mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF120D10),
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              mood,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF120D10),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _ContextLine extends StatelessWidget {
  const _ContextLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF1D7A6), size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
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
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8B66B).withValues(alpha: 0.19),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF1D7A6), size: 13),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryPanel extends StatelessWidget {
  const _ItineraryPanel({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itinerario',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 13),
          ...steps.indexed.map((entry) {
            return _ShareStep(number: entry.$1 + 1, text: entry.$2);
          }),
        ],
      ),
    );
  }
}

class _ShareStep extends StatelessWidget {
  const _ShareStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: number == 3 ? 0 : 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8B66B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Color(0xFF100D10),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.24,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
