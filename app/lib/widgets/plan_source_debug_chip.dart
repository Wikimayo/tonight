import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlanSourceDebugChip extends StatelessWidget {
  const PlanSourceDebugChip({required this.source, this.reason, super.key});

  final String? source;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final trimmedReason = reason?.trim();
    final hasReason = trimmedReason != null && trimmedReason.isNotEmpty;
    final label = switch (source) {
      'ai' => hasReason ? 'IA real: $trimmedReason' : 'IA real',
      'mock' => hasReason ? 'Mock: $trimmedReason' : 'Mock',
      _ => null,
    };

    if (label == null) {
      return const SizedBox.shrink();
    }

    final isAi = source == 'ai';
    final color = isAi ? const Color(0xFFE8B66B) : Colors.white70;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.40)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
