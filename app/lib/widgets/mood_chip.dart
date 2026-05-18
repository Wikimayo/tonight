import 'package:flutter/material.dart';

class MoodChip extends StatefulWidget {
  const MoodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<MoodChip> createState() => _MoodChipState();
}

class _MoodChipState extends State<MoodChip> {
  bool isPressed = false;

  IconData get icon {
    switch (widget.label) {
      case 'Cita':
        return Icons.favorite_rounded;
      case 'Amigos':
        return Icons.groups_rounded;
      case 'Solo':
        return Icons.self_improvement_rounded;
      case 'Chill':
        return Icons.spa_rounded;
      case 'Fiesta':
        return Icons.celebration_rounded;
      case 'Sorpresa':
        return Icons.auto_awesome_rounded;
      case 'Viaje':
        return Icons.flight_takeoff_rounded;
      case 'Grupo':
        return Icons.diversity_3_rounded;
      case 'Gratis':
      case '€':
      case '€€':
      case '€€€':
        return Icons.payments_rounded;
      case '1h':
      case '2h':
      case '3h':
      case 'Toda la noche':
        return Icons.schedule_rounded;
      case 'Cerca':
      case 'Media':
      case 'Me da igual':
        return Icons.near_me_rounded;
      case 'Ahora':
      case 'Mañana':
      case 'Tarde':
      case 'Noche':
      case 'Fin de semana':
        return Icons.wb_twilight_rounded;
      case '2-3':
      case '4-6':
      case '7+':
        return Icons.groups_rounded;
      default:
        return Icons.tune_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final textColor = isSelected ? const Color(0xFF161016) : Colors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: isPressed ? 0.97 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF6DDAE), Color(0xFFE8B66B)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.105),
                      Colors.white.withValues(alpha: 0.055),
                    ],
                  ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.38)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.24),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                setState(() {
                  isPressed = value;
                });
              },
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: textColor, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
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
