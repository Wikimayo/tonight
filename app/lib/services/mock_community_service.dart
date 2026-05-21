import '../models/plan_model.dart';

class MockCommunityService {
  const MockCommunityService._();

  static List<CommunityPlan> getPublicPlans() {
    final now = DateTime.now();

    return [
      CommunityPlan(
        tag: 'Popular',
        likes: 248,
        plan: _plan(
          now: now,
          id: 'community-madrid-date-rooftop',
          title: 'Cita con terraza escondida',
          description:
              'Una ruta corta por Madrid con primera copa, paseo bonito y final con vistas.',
          mood: 'Cita',
          location: 'Madrid',
          moment: 'Noche',
          budget: '€€',
          weather: 'Nublado',
        ),
      ),
      CommunityPlan(
        tag: 'Top Madrid',
        likes: 312,
        plan: _plan(
          now: now,
          id: 'community-madrid-chill-retiro',
          title: 'Chill por Retiro y café',
          description:
              'Paseo suave, café de especialidad y una parada tranquila para bajar revoluciones.',
          mood: 'Chill',
          location: 'Madrid',
          moment: 'Tarde',
          budget: '€',
          weather: 'Soleado',
        ),
      ),
      CommunityPlan(
        tag: 'Nuevo',
        likes: 86,
        plan: _plan(
          now: now,
          id: 'community-barcelona-friends-born',
          title: 'Tarde de amigos en El Born',
          description:
              'Tapas, calles con ambiente y una última parada sin convertirlo en una noche enorme.',
          mood: 'Amigos',
          location: 'Barcelona',
          moment: 'Tarde',
          budget: '€€',
          weather: 'Automático',
        ),
      ),
      CommunityPlan(
        tag: 'Popular',
        likes: 205,
        plan: _plan(
          now: now,
          id: 'community-valencia-date-russafa',
          title: 'Cita ligera en Russafa',
          description:
              'Algo fácil: bebida, paseo por calles con luz y un postre para compartir.',
          mood: 'Cita',
          location: 'Valencia',
          moment: 'Tarde',
          budget: '€',
          weather: 'Soleado',
        ),
      ),
      CommunityPlan(
        tag: 'Nuevo',
        likes: 64,
        plan: _plan(
          now: now,
          id: 'community-barcelona-travel-gracia',
          title: 'Gràcia sin checklist',
          description:
              'Una ruta de viaje local con plazas pequeñas, tienda curiosa y cena informal.',
          mood: 'Viaje',
          location: 'Barcelona',
          moment: 'Fin de semana',
          budget: '€€',
          weather: 'Calor',
        ),
      ),
      CommunityPlan(
        tag: 'Top Madrid',
        likes: 178,
        plan: _plan(
          now: now,
          id: 'community-madrid-friends-latina',
          title: 'La Latina sin debate',
          description:
              'Tres paradas para grupos que quieren verse, comer algo y dejarse llevar.',
          mood: 'Amigos',
          location: 'Madrid',
          moment: 'Noche',
          budget: '€€',
          weather: 'Automático',
        ),
      ),
      CommunityPlan(
        tag: 'Popular',
        likes: 141,
        plan: _plan(
          now: now,
          id: 'community-valencia-chill-turia',
          title: 'Turia en modo tranquilo',
          description:
              'Caminar sin prisa, merienda sencilla y cierre con una vista bonita de ciudad.',
          mood: 'Chill',
          location: 'Valencia',
          moment: 'Mañana',
          budget: 'Gratis',
          weather: 'Soleado',
        ),
      ),
      CommunityPlan(
        tag: 'Nuevo',
        likes: 57,
        plan: _plan(
          now: now,
          id: 'community-madrid-travel-centro',
          title: 'Madrid de primera vez',
          description:
              'Para quien visita la ciudad y quiere sentir centro, comida y una sorpresa urbana.',
          mood: 'Viaje',
          location: 'Madrid',
          moment: 'Ahora',
          budget: '€€',
          weather: 'Nublado',
        ),
      ),
      CommunityPlan(
        tag: 'Popular',
        likes: 119,
        plan: _plan(
          now: now,
          id: 'community-barcelona-chill-sea',
          title: 'Mar, café y calma',
          description:
              'Plan fácil cerca del mar con pausa larga, paseo y cero presión.',
          mood: 'Chill',
          location: 'Barcelona',
          moment: 'Mañana',
          budget: '€',
          weather: 'Soleado',
        ),
      ),
      CommunityPlan(
        tag: 'Nuevo',
        likes: 73,
        plan: _plan(
          now: now,
          id: 'community-valencia-friends-market',
          title: 'Amigos con mercado y terraza',
          description:
              'Quedada informal con algo para picar, paseo corto y terraza de cierre.',
          mood: 'Amigos',
          location: 'Valencia',
          moment: 'Tarde',
          budget: '€€',
          weather: 'Calor',
        ),
      ),
      CommunityPlan(
        tag: 'Popular',
        likes: 154,
        plan: _plan(
          now: now,
          id: 'community-barcelona-date-viewpoint',
          title: 'Cita con mirador',
          description:
              'Una cita con ruta ascendente, conversación fácil y final con foto inevitable.',
          mood: 'Cita',
          location: 'Barcelona',
          moment: 'Noche',
          budget: '€',
          weather: 'Nublado',
        ),
      ),
      CommunityPlan(
        tag: 'Top Madrid',
        likes: 221,
        plan: _plan(
          now: now,
          id: 'community-madrid-chill-bookshop',
          title: 'Librería, paseo y vermut',
          description:
              'Chill cultural para una tarde tranquila con una parada que parece hallazgo.',
          mood: 'Chill',
          location: 'Madrid',
          moment: 'Tarde',
          budget: '€',
          weather: 'Automático',
        ),
      ),
    ];
  }

  static PlanModel _plan({
    required DateTime now,
    required String id,
    required String title,
    required String description,
    required String mood,
    required String location,
    required String moment,
    required String budget,
    required String weather,
  }) {
    return PlanModel(
      id: id,
      createdAt: now,
      title: title,
      description: description,
      estimatedCost: _estimatedCostFor(budget),
      estimatedDuration: '2 horas',
      estimatedDistance: 'A 10-20 min',
      mood: mood,
      budget: budget,
      time: '2h',
      distance: 'Media',
      moment: moment,
      location: location,
      weather: weather,
      source: 'Comunidad mock',
      reason: 'Plan público popular de la comunidad mock de Tonight.',
      itinerarySteps: [
        'Empieza con una primera parada fácil para entrar en ambiente.',
        'Sigue con un paseo o sitio cercano que mantenga la vibe.',
        'Cierra con una última parada sencilla y compartible.',
      ],
      whyItFits:
          'Es un plan probado por otros usuarios y adaptado a una salida rápida.',
      vibe: 'Social, local y fácil de repetir.',
    );
  }

  static String _estimatedCostFor(String budget) {
    switch (budget) {
      case 'Gratis':
        return '0-10 €';
      case '€':
        return '10-25 €';
      case '€€':
        return '25-60 €';
      case '€€€':
        return '+60 €';
      default:
        return '10-25 €';
    }
  }
}

class CommunityPlan {
  const CommunityPlan({
    required this.plan,
    required this.likes,
    required this.tag,
  });

  final PlanModel plan;
  final int likes;
  final String tag;
}
