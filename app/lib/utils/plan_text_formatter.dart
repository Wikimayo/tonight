import '../models/plan_model.dart';
import 'text_sanitizer.dart';

class PlanTextFormatter {
  const PlanTextFormatter._();

  static String shareText(PlanModel plan) {
    final lines = <String>[
      'Mi plan en Tonight',
      '',
      clean(plan.title),
      clean(plan.description),
      '',
      'Datos',
      'Mood: ${clean(plan.mood)}',
      'Ubicación: ${clean(plan.location)}',
      'Momento: ${clean(plan.moment)}',
      'Clima: ${clean(plan.weather)}',
      'Coste estimado: ${clean(plan.estimatedCost)}',
      'Duración estimada: ${clean(plan.estimatedDuration)}',
      'Distancia aproximada: ${clean(plan.estimatedDistance)}',
    ];

    final groupSize = TextSanitizer.cleanOptional(plan.groupSize);
    if (groupSize != null) {
      lines.add('Tamaño del grupo: $groupSize');
    }

    lines
      ..add('')
      ..add('Itinerario');

    for (final entry in plan.itinerarySteps.indexed) {
      final index = entry.$1;
      final step = clean(entry.$2);
      final place = index < plan.places.length ? plan.places[index] : null;
      final placeName = place == null ? null : clean(place.name);
      final address = place == null
          ? null
          : TextSanitizer.cleanOptional(place.address);

      if (placeName == null || placeName.isEmpty) {
        lines.add('${index + 1}. $step');
      } else {
        lines.add('${index + 1}. $placeName');
        if (address != null) {
          lines.add('   $address');
        }
        lines.add('   $step');
      }
    }

    return lines.join('\n').trim();
  }

  static String clean(String value) => TextSanitizer.clean(value);
}
