import '../models/plan_model.dart';

class DailyPlanService {
  const DailyPlanService._();

  static PlanModel getDailyPlan({DateTime? now}) {
    final currentDate = now ?? DateTime.now();
    final dayKey = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final variants = _dailyPlans(dayKey);
    final index = dayKey.difference(DateTime(2026)).inDays % variants.length;

    return variants[index];
  }

  static List<PlanModel> _dailyPlans(DateTime date) {
    return [
      PlanModel(
        id: _idFor(date, 'daily-soft-reset'),
        createdAt: date,
        title: 'Reset con luz bonita',
        description:
            'Un plan suave para salir sin complicarte: algo rico, un paseo corto y una parada con calma para volver con otra energía.',
        estimatedCost: '10-25 €',
        estimatedDuration: '2 horas',
        estimatedDistance: 'A 10-15 min',
        mood: 'Chill',
        budget: '€',
        time: '2h',
        distance: 'Cerca',
        moment: 'Tarde',
        location: 'tu zona',
        weather: 'Automático',
        itinerarySteps: const [
          'Empieza con café, merienda o bebida tranquila en un sitio con buena luz.',
          'Camina hacia una calle, plaza o parque cercano que se sienta respirable.',
          'Cierra con una parada dulce o una terraza suave antes de volver.',
        ],
        whyItFits:
            'Es un plan diario porque no exige demasiado: tiene intención, poco desplazamiento y deja margen para improvisar.',
        vibe: 'Suave, luminosa y de hombros relajados.',
      ),
      PlanModel(
        id: _idFor(date, 'daily-secret-route'),
        createdAt: date,
        title: 'Ruta secreta para hoy',
        description:
            'Tres paradas con sensación de hallazgo: una entrada fácil, una sorpresa pequeña y un cierre que pide foto.',
        estimatedCost: '25-60 €',
        estimatedDuration: '2 horas',
        estimatedDistance: 'Hasta 30 min',
        mood: 'Sorpresa',
        budget: '€€',
        time: '2h',
        distance: 'Media',
        moment: 'Ahora',
        location: 'tu zona',
        weather: 'Automático',
        itinerarySteps: const [
          'Arranca en una barra, cafetería o local con personalidad cerca de ti.',
          'Busca una segunda parada inesperada: galería, tienda curiosa o rincón con música.',
          'Termina con vistas, postre o una última bebida tranquila.',
        ],
        whyItFits:
            'Funciona cuando quieres que Tonight decida por ti sin sentir que estás siguiendo una lista genérica.',
        vibe: 'Misteriosa, urbana y compartible.',
      ),
      PlanModel(
        id: _idFor(date, 'daily-group-easy'),
        createdAt: date,
        title: 'Plan fácil para juntar al grupo',
        description:
            'Una idea lista para mandar al chat: mesa informal, paseo breve y cierre flexible para quien quiera alargar.',
        estimatedCost: '25-60 €',
        estimatedDuration: '3 horas',
        estimatedDistance: 'A 10-15 min',
        mood: 'Grupo',
        budget: '€€',
        time: '3h',
        distance: 'Cerca',
        moment: 'Noche',
        location: 'tu zona',
        weather: 'Automático',
        groupSize: '4-6',
        itinerarySteps: const [
          'Quedad en un punto fácil y elegid una mesa con platos para compartir.',
          'Pasead hacia una zona con ambiente sin alejaros demasiado.',
          'Cerrad con helado, copa tranquila o última parada si el grupo sigue.',
        ],
        whyItFits:
            'Reduce decisiones y da una estructura simple para que varias personas digan que sí rápido.',
        vibe: 'Comunal, cálida y sin drama logístico.',
      ),
      PlanModel(
        id: _idFor(date, 'daily-solo-main-character'),
        createdAt: date,
        title: 'Modo protagonista',
        description:
            'Un plan para salir a tu ritmo: una bebida, una calle bonita y una pequeña recompensa elegida solo por ti.',
        estimatedCost: '10-25 €',
        estimatedDuration: '1 hora',
        estimatedDistance: 'Cerca',
        mood: 'Solo',
        budget: '€',
        time: '1h',
        distance: 'Cerca',
        moment: 'Mañana',
        location: 'tu zona',
        weather: 'Automático',
        itinerarySteps: const [
          'Empieza con una bebida para llevar o una mesa tranquila.',
          'Camina hacia una librería, parque, mercado o calle que no cruces siempre.',
          'Cierra guardando una foto, una nota o una canción del momento.',
        ],
        whyItFits:
            'Convierte una hora libre en algo deliberado, sin depender de nadie ni montar un gran plan.',
        vibe: 'Serena, independiente y un poco de película indie.',
      ),
    ];
  }

  static String _idFor(DateTime date, String suffix) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'daily-${date.year}$month$day-$suffix';
  }
}
