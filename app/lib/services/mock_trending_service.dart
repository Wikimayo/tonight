import '../models/plan_model.dart';

class MockTrendingService {
  const MockTrendingService._();

  static List<TrendingPlan> getTrendingPlans() {
    final now = DateTime.now();

    return [
      TrendingPlan(
        tag: 'Popular',
        plan: PlanModel(
          id: 'trending-secret-city',
          createdAt: now,
          title: 'Ruta secreta de última hora',
          description:
              'Tres paradas con ambiente, comida fácil y un cierre con vistas para sentir que la ciudad todavía guarda algo.',
          estimatedCost: '25-60 €',
          estimatedDuration: '2 horas',
          estimatedDistance: 'Hasta 30 min',
          mood: 'Sorpresa',
          budget: '€€',
          time: '2h',
          distance: 'Media',
          moment: 'Ahora',
          location: 'Centro',
          weather: 'Nublado',
          itinerarySteps: const [
            'Arranca en una barra escondida con primera recomendación de la casa.',
            'Camina hacia una calle secundaria con tienda, galería o música inesperada.',
            'Termina en una terraza o mirador urbano para cerrar con foto.',
          ],
          whyItFits:
              'Funciona cuando quieres salir sin pensar demasiado, pero con una sensación de plan elegido.',
          vibe: 'Misteriosa, urbana, con final compartible.',
        ),
      ),
      TrendingPlan(
        tag: 'Top esta semana',
        plan: PlanModel(
          id: 'trending-group-dinner',
          createdAt: now,
          title: 'Cena fácil para el grupo',
          description:
              'Un plan pensado para desbloquear el chat: mesa compartida, paseo suave y última parada opcional.',
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
            'Quedad en una mesa informal con platos al centro y ruido agradable.',
            'Pasead hacia una zona con luz bonita para bajar la sobremesa.',
            'Cerrad con helado, copa tranquila o terraza si el grupo sigue.',
          ],
          whyItFits:
              'Evita debates eternos y da a cada persona algo fácil a lo que decir que sí.',
          vibe: 'Comunal, cálida y con cero drama logístico.',
        ),
      ),
      TrendingPlan(
        tag: 'Nuevo',
        plan: PlanModel(
          id: 'trending-date-dessert',
          createdAt: now,
          title: 'La cita del postre',
          description:
              'Una cita ligera con bebida, paseo corto y un final dulce que no parece demasiado planeado.',
          estimatedCost: '10-25 €',
          estimatedDuration: '2 horas',
          estimatedDistance: 'A 10-15 min',
          mood: 'Cita',
          budget: '€',
          time: '2h',
          distance: 'Cerca',
          moment: 'Tarde',
          location: 'Malasaña',
          weather: 'Soleado',
          itinerarySteps: const [
            'Primera bebida en una cafetería o barra con luz cálida.',
            'Paseo por una calle con escaparates, plazas o música de fondo.',
            'Postre para compartir y excusa perfecta para alargar.',
          ],
          whyItFits:
              'Tiene intención sin ponerse intenso: suficiente cuidado, suficiente espontaneidad.',
          vibe: 'Coqueta, luminosa y muy fácil de repetir.',
        ),
      ),
      TrendingPlan(
        tag: 'Popular',
        plan: PlanModel(
          id: 'trending-solo-reset',
          createdAt: now,
          title: 'Reset en solitario',
          description:
              'Un plan para salir solo, caminar con calma y volver con menos ruido mental.',
          estimatedCost: '0-10 €',
          estimatedDuration: '1 hora',
          estimatedDistance: 'A 10-15 min',
          mood: 'Solo',
          budget: 'Gratis',
          time: '1h',
          distance: 'Cerca',
          moment: 'Mañana',
          location: 'Retiro',
          weather: 'Soleado',
          itinerarySteps: const [
            'Empieza con café o bebida para llevar en una esquina tranquila.',
            'Camina hacia una zona verde, librería o calle con poca prisa.',
            'Cierra guardando una foto, nota o canción del momento.',
          ],
          whyItFits:
              'Convierte una hora libre en algo deliberado, sin depender de nadie más.',
          vibe: 'Serena, consciente y de película indie.',
        ),
      ),
      TrendingPlan(
        tag: 'Nuevo',
        plan: PlanModel(
          id: 'trending-travel-local',
          createdAt: now,
          title: 'Lisboa como local',
          description:
              'Una ruta para viajar sin checklist: barrio con carácter, comida sencilla y una parada que parece hallazgo.',
          estimatedCost: '25-60 €',
          estimatedDuration: '3 horas',
          estimatedDistance: 'Hasta 30 min',
          mood: 'Viaje',
          budget: '€€',
          time: '3h',
          distance: 'Media',
          moment: 'Fin de semana',
          location: 'Lisboa',
          weather: 'Calor',
          itinerarySteps: const [
            'Empieza en una cafetería de barrio lejos del circuito automático.',
            'Explora una calle secundaria con azulejos, tiendas pequeñas y miradores.',
            'Termina con una mesa local y una copa tranquila al atardecer.',
          ],
          whyItFits: 'Te da una sensación de ciudad vivida, no solo visitada.',
          vibe: 'Local, cálida, con postal que no parece postal.',
        ),
      ),
    ];
  }
}

class TrendingPlan {
  const TrendingPlan({required this.plan, required this.tag});

  final PlanModel plan;
  final String tag;
}
