import 'dart:math';

import '../models/plan_model.dart';
import '../models/place_model.dart';
import 'mock_places_service.dart';

class MockPlanGenerator {
  const MockPlanGenerator._();

  static final Random _random = Random();

  static PlanModel generate({
    required String mood,
    required String budget,
    required String time,
    required String distance,
    required String moment,
    required String location,
    String weather = 'Automático',
    String? groupSize,
    String? reason,
  }) {
    final context = _PlanContext(
      mood: mood,
      budget: budget,
      time: time,
      distance: distance,
      moment: moment,
      location: _resolvedLocation(location),
      weather: weather,
      groupSize: mood == 'Grupo' ? groupSize ?? '4-6' : null,
    );
    final variants = _variantsByMood[mood] ?? _variantsByMood['Cita']!;
    final variant = variants[_random.nextInt(variants.length)];
    final now = DateTime.now();
    final selectedPlaces = MockPlacesService.findCompatiblePlaces(
      mood: mood,
      weather: weather,
      budget: budget,
      location: context.location,
    )..shuffle(_random);
    final places = selectedPlaces.take(3).toList();
    final fallbackSteps = _adaptStepsForWeather(
      variant.itinerarySteps(context),
      context,
    );
    final itinerarySteps = places.length >= 3
        ? _itineraryStepsFromPlaces(places, context)
        : fallbackSteps;

    return PlanModel(
      id: '${now.microsecondsSinceEpoch}-${_random.nextInt(9999)}',
      createdAt: now,
      title: variant.title(context),
      description: '${variant.description(context)} ${context.weatherSentence}',
      estimatedCost: _estimatedCostFor(budget),
      estimatedDuration: _estimatedDurationFor(time),
      estimatedDistance: _estimatedDistanceFor(distance),
      mood: mood,
      budget: budget,
      time: time,
      distance: distance,
      moment: moment,
      location: context.location,
      weather: context.weather,
      groupSize: context.groupSize,
      source: 'mock',
      reason: reason,
      places: places.length >= 3 ? places : const [],
      itinerarySteps: itinerarySteps,
      whyItFits: '${variant.whyItFits(context)} ${context.weatherWhyItFits}',
      vibe: '${variant.vibe(context)} ${context.weatherVibe}',
    );
  }

  static List<String> _itineraryStepsFromPlaces(
    List<PlaceModel> places,
    _PlanContext context,
  ) {
    return places.indexed.map((entry) {
      final index = entry.$1;
      final place = entry.$2;
      final intro = switch (index) {
        0 => 'Empieza en',
        1 => 'Sigue por',
        _ => 'Cierra en',
      };

      return '$intro ${place.name}, ${place.description.toLowerCase()} '
          'Encaja con ${context.momentCopy}, mood ${context.mood} y presupuesto ${context.budget}.';
    }).toList();
  }

  static List<String> _adaptStepsForWeather(
    List<String> steps,
    _PlanContext context,
  ) {
    if (steps.isEmpty) {
      return steps;
    }

    return steps.indexed.map((entry) {
      final index = entry.$1;
      final step = entry.$2;

      switch (context.weather) {
        case 'Lluvia':
          if (index == 0) {
            return '$step Prioriza un sitio cubierto, cálido y fácil de alcanzar sin mojarse demasiado.';
          }
          if (index == 1) {
            return '$step Cambia cualquier paseo largo por galería, mercado, cine pequeño o barra interior.';
          }
          return '$step Cierra bajo techo, con luz baja y cero prisa por salir.';
        case 'Calor':
          if (index == 0) {
            return '$step Arranca cuando baje un poco el sol o busca sombra desde el primer minuto.';
          }
          if (index == 1) {
            return '$step Mantén el tramo fresco: terraza ventilada, helado, bebida fría o interior con aire.';
          }
          return '$step Mejor al atardecer o de noche, cuando la ciudad vuelve a respirar.';
        case 'Frío':
          if (index == 0) {
            return '$step Elige un primer sitio acogedor, con bebida caliente o mesa protegida.';
          }
          if (index == 1) {
            return '$step Reduce exteriores y busca interiores con sofá, barra cómoda o luz cálida.';
          }
          return '$step Termina en un lugar cálido donde apetezca quedarse un rato más.';
        case 'Soleado':
          if (index == 0) {
            return '$step Aprovecha la luz con terraza, plaza o punto exterior agradable.';
          }
          if (index == 1) {
            return '$step Deja espacio para caminar al aire libre y mirar la zona sin encierros.';
          }
          return '$step Cierra con vistas, paseo o mesa exterior si el tiempo acompaña.';
        case 'Nublado':
          if (index == 0) {
            return '$step Mantén una alternativa cubierta cerca por si cambia el cielo.';
          }
          if (index == 1) {
            return '$step Funciona bien con paseo corto y parada interior flexible.';
          }
          return '$step Termina en un sitio cómodo que no dependa del sol para tener encanto.';
        case 'Automático':
        default:
          return step;
      }
    }).toList();
  }

  static final Map<String, List<_PlanVariant>> _variantsByMood = {
    'Cita': [
      _PlanVariant(
        title: (c) => 'Dos luces y una mesa',
        description: (c) =>
            'Una ruta con intención para ${c.momentCopy} en ${c.location}: '
            'conversación fácil, rincones con encanto y un ritmo ${c.timeTone} '
            'para que la química aparezca sin forzar.',
        itinerarySteps: (c) => [
          'Empezad con una bebida tranquila en una barra íntima de ${c.location}.',
          'Compartid algo rico en un sitio ${c.budgetTone}, con luz baja y mesa pequeña.',
          '${c.finalStop} para cerrar con una excusa perfecta para seguir hablando.',
        ],
        whyItFits: (c) =>
            'Encaja con una cita porque combina intimidad, movimiento ${c.distanceTone} '
            'y decisiones sencillas: suficiente estructura para sentirse cuidado, '
            'suficiente aire para que pase algo natural.',
        vibe: (c) => 'Cinemática, cercana, con química de plano final.',
      ),
      _PlanVariant(
        title: (c) => 'La excusa del postre',
        description: (c) =>
            'Un plan dulce y ligero para ${c.momentCopy}: empezar sin presión, '
            'subir un poco la apuesta y terminar en ${c.location} con esa sensación '
            'de "esto habría que repetirlo".',
        itinerarySteps: (c) => [
          'Café, vermut o copa suave en un local bonito y poco ruidoso.',
          'Paseo ${c.distanceTone} por una calle con escaparates, plazas o luces cálidas.',
          'Postre para compartir o helado de autor como cierre ${c.budgetTone}.',
        ],
        whyItFits: (c) =>
            'Funciona porque no se siente demasiado solemne: deja espacio para bromear, '
            'mirarse y cambiar de plan si ${c.momentCopy} pide otra cosa.',
        vibe: (c) =>
            'Coqueta, luminosa, como una escena que empieza caminando.',
      ),
      _PlanVariant(
        title: (c) => 'Mesa secreta, paseo lento',
        description: (c) =>
            'Una cita elegante en ${c.location}, pensada para ${c.timeLabel}: '
            'sitios escogidos, trayecto amable y un final que no depende de grandes gestos.',
        itinerarySteps: (c) => [
          'Reserva improvisada en un bistró, taberna o barra con encanto local.',
          'Parada breve en una tienda, galería pequeña o mirador urbano.',
          'Última bebida en un sitio con música baja y asientos cómodos.',
        ],
        whyItFits: (c) =>
            'Tiene una progresión clara: primero comodidad, luego descubrimiento y '
            'después calma. Ideal si quieres que ${c.momentCopy} tenga intención sin pesar.',
        vibe: (c) =>
            'Sofisticada, lenta, con confidencias entre luces cálidas.',
      ),
      _PlanVariant(
        title: (c) => 'Cita sin guion',
        description: (c) =>
            'Un recorrido flexible por ${c.location} para dejar que ${c.momentCopy} '
            'decida el tono: algo rico, una parada inesperada y cero sensación de agenda.',
        itinerarySteps: (c) => [
          'Primera parada fácil: bebida, tapa o café especial según el momento.',
          'Mini paseo hacia una zona con ambiente ${c.distanceTone}.',
          'Cierre espontáneo: terraza, postre o segunda ronda si hay chispa.',
        ],
        whyItFits: (c) =>
            'Está hecho para una cita que no quiere parecer demasiado diseñada. '
            'El presupuesto ${c.budget} y el tiempo ${c.time} marcan límites claros sin cortar el flow.',
        vibe: (c) => 'Natural, juguetona, con final abierto.',
      ),
    ],
    'Amigos': [
      _PlanVariant(
        title: (c) => 'Brindis sin mapa',
        description: (c) =>
            'Un plan de grupo para ${c.momentCopy} en ${c.location}: picar, cambiar de escena '
            'y acabar con una historia fácil de contar mañana.',
        itinerarySteps: (c) => [
          'Arranque con picoteo ${c.budgetTone} en una barra con energía.',
          'Segundo sitio con música buena, conversación fácil y espacio para reír alto.',
          '${c.finalStop} para la foto, el dulce compartido o la última ronda.',
        ],
        whyItFits: (c) =>
            'Da ritmo al grupo sin complicarlo: trayectos ${c.distanceTone}, duración ${c.timeLabel} '
            'y suficientes cambios para que nadie mire el reloj.',
        vibe: (c) => 'Social, eléctrico, con final de sobremesa larga.',
      ),
      _PlanVariant(
        title: (c) => 'Mesa grande, cero drama',
        description: (c) =>
            'La versión fácil de reunir a todo el mundo en ${c.location}: comida para compartir, '
            'un sitio con ambiente y un cierre que permite alargar o cortar a tiempo.',
        itinerarySteps: (c) => [
          'Quedad en una plaza o calle reconocible para arrancar sin pérdidas.',
          'Id a una mesa informal con platos al centro y precio ${c.budgetTone}.',
          'Terminad con una actividad corta: karaoke suave, billar, terraza o helado.',
        ],
        whyItFits: (c) =>
            'Está pensado para grupos con ritmos distintos: nadie queda atrapado, '
            'pero el plan tiene una dirección clara para ${c.momentCopy}.',
        vibe: (c) => 'Cómoda, cómplice, con bromas internas en construcción.',
      ),
      _PlanVariant(
        title: (c) => 'Ruta de risas rápidas',
        description: (c) =>
            'Un plan ágil por ${c.location} para cuando queréis veros, desconectar y no convertirlo '
            'en una operación logística.',
        itinerarySteps: (c) => [
          'Primera parada con bebida rápida y algo para compartir.',
          'Paseo ${c.distanceTone} hacia un local con ambiente más vivo.',
          'Cierre con snack nocturno, foto grupal o última parada dulce.',
        ],
        whyItFits: (c) =>
            'Aprovecha bien ${c.timeLabel} y mantiene el presupuesto ${c.budget} bajo control, '
            'sin perder sensación de plan especial.',
        vibe: (c) => 'Rápida, brillante, de esas que empiezan con "solo una".',
      ),
      _PlanVariant(
        title: (c) => 'El comité del buen plan',
        description: (c) =>
            'Una ruta compartible en ${c.location}, con paradas que funcionan para el que quiere comer, '
            'el que quiere hablar y el que quiere subir un punto la energía.',
        itinerarySteps: (c) => [
          'Bar o mercado con opciones variadas para que nadie negocie demasiado.',
          'Actividad social corta: trivia, exposición pop, arcade o música en directo.',
          'Última ronda en una terraza o barra con buena luz.',
        ],
        whyItFits: (c) =>
            'Equilibra gustos distintos y evita el clásico "¿qué hacemos ahora?". '
            'Tiene margen para improvisar según cómo esté ${c.location} ${c.momentCopy}.',
        vibe: (c) => 'Plural, viva, con energía de chat lleno de audios.',
      ),
    ],
    'Solo': [
      _PlanVariant(
        title: (c) => 'Cita contigo',
        description: (c) =>
            'Un plan íntimo para ${c.momentCopy} por ${c.location}: bajar el ruido, '
            'descubrir un sitio nuevo y volver con la sensación de haberte elegido.',
        itinerarySteps: (c) => [
          'Café, té o vino en una esquina tranquila donde puedas estar sin prisa.',
          'Paseo ${c.distanceTone} por una calle bonita o una librería cercana.',
          'Cierre con comida ligera, postre especial o una parada cultural pequeña.',
        ],
        whyItFits: (c) =>
            'Respeta tu ritmo y usa ${c.timeLabel} para darte presencia, no tareas. '
            'Es especial sin exigir compañía ni demasiada energía.',
        vibe: (c) => 'Calma premium, introspectiva, muy de película indie.',
      ),
      _PlanVariant(
        title: (c) => 'Modo protagonista',
        description: (c) =>
            'Una salida en ${c.location} para reconectar con tu propio criterio: '
            'algo bonito, algo rico y una pequeña decisión solo para ti.',
        itinerarySteps: (c) => [
          'Empieza con una bebida en barra mirando hacia la calle.',
          'Visita una galería, tienda cuidada, cine pequeño o rincón cultural.',
          'Compra o prueba un capricho ${c.budgetTone} para cerrar con ritual.',
        ],
        whyItFits: (c) =>
            'Convierte ${c.momentCopy} en una pausa con intención. La distancia ${c.distance} '
            'mantiene el plan cómodo y el presupuesto ${c.budget} lo hace fácil de aceptar.',
        vibe: (c) =>
            'Serena, segura, con auriculares y mirada de escena inicial.',
      ),
      _PlanVariant(
        title: (c) => 'Una hora para volver',
        description: (c) =>
            'Un plan de recarga por ${c.location}, ideal si quieres salir sin socializar '
            'pero volver con algo nuevo en la cabeza.',
        itinerarySteps: (c) => [
          'Bebida caliente o fresca en un sitio con buena luz.',
          'Paseo con objetivo: mirador, parque, librería o calle tranquila.',
          'Nota mental final: escribe una idea, haz una foto o guarda una canción.',
        ],
        whyItFits: (c) =>
            'No intenta llenar el día entero: aprovecha ${c.timeLabel} con calma y '
            'convierte un plan simple en un pequeño reset emocional.',
        vibe: (c) =>
            'Ligera, consciente, como respirar después de mucho ruido.',
      ),
      _PlanVariant(
        title: (c) => 'Exploración en silencio',
        description: (c) =>
            'Una mini aventura personal por ${c.location}: mirar más lento, probar algo nuevo '
            'y dejar que ${c.momentCopy} tenga textura propia.',
        itinerarySteps: (c) => [
          'Elige una calle que no suelas cruzar y empieza con una parada pequeña.',
          'Busca una mesa, banco o barra donde puedas observar sin explicar nada.',
          'Cierra con un paseo ${c.distanceTone} y una compra simbólica o foto favorita.',
        ],
        whyItFits: (c) =>
            'Va contigo porque no fuerza interacción. Solo propone señales, lugares y '
            'un ritmo ${c.timeTone} para sentir que has salido de verdad.',
        vibe: (c) => 'Misteriosa, tranquila, con ciudad de fondo.',
      ),
    ],
    'Chill': [
      _PlanVariant(
        title: (c) => 'Baja frecuencia',
        description: (c) =>
            'Un recorrido suave y bonito para ${c.momentCopy} por ${c.location}: '
            'el tipo de plan que no grita, pero deja el cuerpo más ligero.',
        itinerarySteps: (c) => [
          'Algo rico en un lugar con luz cálida y asientos cómodos.',
          'Paseo lento ${c.distanceTone} por una zona tranquila.',
          'Cierre suave con terraza, música baja o bebida sin prisa.',
        ],
        whyItFits: (c) =>
            'Reduce fricción, evita exceso de estímulo y usa el presupuesto ${c.budget} '
            'para mantener el plan especial sin convertirlo en misión.',
        vibe: (c) => 'Suave, cálida, minimalista y muy fácil de disfrutar.',
      ),
      _PlanVariant(
        title: (c) => 'Domingo aunque no sea domingo',
        description: (c) =>
            'Una pausa estética en ${c.location}, perfecta para ${c.momentCopy}: '
            'comer algo bueno, caminar poco y dejar que el plan respire.',
        itinerarySteps: (c) => [
          'Brunch, merienda o cena ligera según el momento.',
          'Parada en parque, plaza o calle calmada para bajar revoluciones.',
          'Último sitio con sofá, té, vino suave o postre casero.',
        ],
        whyItFits: (c) =>
            'Tiene ritmo ${c.timeTone}, distancias ${c.distanceTone} y cero presión. '
            'Ideal cuando quieres salir sin acabar agotado.',
        vibe: (c) => 'Algodón, luz baja y conversaciones en voz pequeña.',
      ),
      _PlanVariant(
        title: (c) => 'Plan manta, pero fuera',
        description: (c) =>
            'La comodidad de quedarse en casa, trasladada a ${c.location}: '
            'sitios cálidos, decisiones fáciles y un cierre redondo.',
        itinerarySteps: (c) => [
          'Empieza con un local acogedor: cafetería, vinoteca suave o ramen tranquilo.',
          'Camina solo lo justo hacia un punto bonito y poco concurrido.',
          'Termina con algo dulce o una bebida caliente para sellar el mood.',
        ],
        whyItFits: (c) =>
            'El plan entiende que chill no significa aburrido: significa cuidado, '
            'buen ambiente y gastar energía de forma inteligente.',
        vibe: (c) => 'Acogedora, lenta, como playlist de lluvia sin lluvia.',
      ),
      _PlanVariant(
        title: (c) => 'Respirar la zona',
        description: (c) =>
            'Un paseo con intención por ${c.location}, diseñado para mirar alrededor, '
            'comer algo simple y volver con menos ruido mental.',
        itinerarySteps: (c) => [
          'Primera parada ${c.budgetTone} para algo sencillo y bien hecho.',
          'Ruta corta por una calle bonita, plaza o zona verde.',
          'Cierre con banco, terraza o rincón tranquilo para quedarte un rato.',
        ],
        whyItFits: (c) =>
            'Ajusta ${c.timeLabel} a una experiencia ligera y mantiene la distancia ${c.distance} '
            'como aliada para que nada pese.',
        vibe: (c) => 'Clara, aireada, con final de hombros relajados.',
      ),
    ],
    'Fiesta': [
      _PlanVariant(
        title: (c) => 'Subida de volumen',
        description: (c) =>
            'Un plan con entrada progresiva para ${c.momentCopy} en ${c.location}: '
            'empieza con chispa, encuentra su punto fuerte y termina cuando el cuerpo pida más.',
        itinerarySteps: (c) => [
          'Primera bebida en un sitio con ambiente entrando en calor.',
          'Local con música alta y pista accesible ${c.distanceTone}.',
          'Sesión final, bar con DJ o sitio con energía para rematar.',
        ],
        whyItFits: (c) =>
            'Prioriza energía ascendente, trayectos ${c.distanceTone} y un coste ${c.budgetTone} '
            'para que la noche no se quede a medias.',
        vibe: (c) => 'Alta energía, luces bajas, canciones que se gritan.',
      ),
      _PlanVariant(
        title: (c) => 'Luces, bajo y última ronda',
        description: (c) =>
            'Una ruta de fiesta por ${c.location} con calentamiento, pico de energía '
            'y cierre potente sin perder el control del plan.',
        itinerarySteps: (c) => [
          'Quedada inicial en una barra animada para juntar al grupo.',
          'Movimiento a un sitio con DJ, música latina, electrónica o hits sin vergüenza.',
          'Cierre con comida rápida buena o una última copa si ${c.timeLabel} da margen.',
        ],
        whyItFits: (c) =>
            'Lee bien el mood Fiesta: menos conversación eterna, más movimiento, '
            'más cambio de luces y una estructura clara para ${c.momentCopy}.',
        vibe: (c) => 'Brillante, acelerada, con eco de bajo al salir.',
      ),
      _PlanVariant(
        title: (c) => 'La previa que se convirtió en plan',
        description: (c) =>
            'Ideal para ${c.location} cuando no quieres prometer una gran noche pero sí '
            'darle opciones reales de convertirse en una.',
        itinerarySteps: (c) => [
          'Previa corta con bebida y algo salado para entrar bien.',
          'Bar con gente, música y suficiente espacio para moverse.',
          'Decisión final: bailar, cambiar de zona o cerrar con snack de madrugada.',
        ],
        whyItFits: (c) =>
            'Se adapta a ${c.timeLabel}: puede ser compacto o escalar. Además, '
            'el presupuesto ${c.budget} marca una fiesta con cabeza.',
        vibe: (c) => 'Improvisada, contagiosa, de "venga, una más".',
      ),
      _PlanVariant(
        title: (c) => 'Circuito de alto voltaje',
        description: (c) =>
            'Una secuencia directa para activar ${c.momentCopy} en ${c.location}: '
            'poca espera, mucha señal y paradas con ambiente reconocible.',
        itinerarySteps: (c) => [
          'Arranque en un local concurrido con primera ronda fácil.',
          'Cambio ${c.distanceTone} hacia el sitio con más música del plan.',
          'Cierre arriba: terraza animada, club pequeño o barra con última canción.',
        ],
        whyItFits: (c) =>
            'Funciona porque no dispersa la energía. Cada parada sube un punto y '
            'mantiene el plan memorable sin depender de suerte pura.',
        vibe: (c) => 'Neón, movimiento y mensajes al día siguiente.',
      ),
    ],
    'Sorpresa': [
      _PlanVariant(
        title: (c) => 'Plan fuera de guion',
        description: (c) =>
            'Una ruta para ${c.momentCopy} por ${c.location} con un punto inesperado, '
            'perfecta para salir sin saber qué versión del día te espera.',
        itinerarySteps: (c) => [
          'Primera parada poco obvia: barra escondida, tienda curiosa o café de autor.',
          'Actividad pequeña: exposición, microconcierto, mercado o local secreto.',
          'Cierre con vistas, mesa improvisada o brindis por la decisión rara.',
        ],
        whyItFits: (c) =>
            'Mezcla seguridad y sorpresa: estructura suficiente para fluir y misterio '
            'suficiente para que apetezca compartirlo.',
        vibe: (c) =>
            'Curiosa, inesperada, con ese punto de "tenías que venir".',
      ),
      _PlanVariant(
        title: (c) => 'La puerta que no estaba en el mapa',
        description: (c) =>
            'Un plan con descubrimiento suave en ${c.location}: entrar por una idea simple '
            'y salir con una anécdota que no habrías elegido en automático.',
        itinerarySteps: (c) => [
          'Elige una calle secundaria y busca una primera parada con personalidad.',
          'Sigue con algo cultural, raro o sensorial según lo que esté vivo ${c.momentCopy}.',
          'Termina con comida o bebida ${c.budgetTone} en un sitio que parezca hallazgo.',
        ],
        whyItFits: (c) =>
            'La sorpresa está dosificada: no te lanza al caos, pero sí rompe la rutina '
            'con una distancia ${c.distanceTone}.',
        vibe: (c) =>
            'Secreta, elegante, como recomendación que no se manda al grupo.',
      ),
      _PlanVariant(
        title: (c) => 'Ruleta bonita',
        description: (c) =>
            'Una propuesta flexible para ${c.location}, con paradas que pueden cambiar '
            'según el clima, la hora y las ganas del momento.',
        itinerarySteps: (c) => [
          'Empieza con una moneda mental: dulce si vienes bajo, salado si vienes alto.',
          'Busca una actividad corta: librería, galería, tienda vintage, mirador o música.',
          'Cierra con una parada que no estaba prevista pero queda cerca.',
        ],
        whyItFits: (c) =>
            'Es sorpresa sin estrés. Usa ${c.timeLabel}, presupuesto ${c.budget} y zona '
            'para darte libertad con bordes claros.',
        vibe: (c) => 'Juguetona, fotogénica, con final de casualidad perfecta.',
      ),
      _PlanVariant(
        title: (c) => 'Misión secreta en ${c.location}',
        description: (c) =>
            'Una mini misión urbana para ${c.momentCopy}: tres pistas, cero mapas complicados '
            'y una sensación de haber encontrado algo propio.',
        itinerarySteps: (c) => [
          'Pista 1: busca un sitio con una fachada, carta o escaparate que te llame.',
          'Pista 2: camina ${c.distanceTone} hacia una actividad pequeña y poco obvia.',
          'Pista 3: finaliza con una bebida, postre o vista que cierre la historia.',
        ],
        whyItFits: (c) =>
            'Convierte el contexto en juego: ${c.location}, ${c.momentCopy}, ${c.timeLabel} '
            'y ${c.budget} funcionan como reglas creativas.',
        vibe: (c) =>
            'Narrativa, misteriosa, con energía de secreto bien guardado.',
      ),
    ],
    'Viaje': [
      _PlanVariant(
        title: (c) => '${c.location} en modo esencial',
        description: (c) =>
            'Una ruta turística rápida para descubrir ${c.location} ${c.momentCopy}: '
            'iconos de la ciudad, una pausa bonita y un cierre con sensación de haber aprovechado el viaje.',
        itinerarySteps: (c) => [
          'Empieza por un punto reconocible del centro histórico para orientarte rápido.',
          'Camina ${c.distanceTone} hacia una plaza, mirador o calle imprescindible.',
          'Cierra con una bebida o foto final en una zona con buena vista de ${c.location}.',
        ],
        whyItFits: (c) =>
            'Es perfecto para viajar con poco margen: condensa lo esencial en ${c.timeLabel}, '
            'respeta un presupuesto ${c.budgetTone} y te da una primera lectura clara de la ciudad.',
        vibe: (c) => 'Postal viva, pasos ligeros y cámara lista.',
      ),
      _PlanVariant(
        title: (c) => 'Sabores de ${c.location}',
        description: (c) =>
            'Un plan gastronómico para probar la ciudad sin caer en lo obvio: '
            'mercado, mesa local y un final dulce o líquido que se recuerde.',
        itinerarySteps: (c) => [
          'Arranca en un mercado, panadería o barra local para probar algo típico.',
          'Sigue con una comida ${c.budgetTone} en una zona con movimiento real.',
          'Termina con postre, café especial o copa tranquila cerca del paseo principal.',
        ],
        whyItFits: (c) =>
            'Viaje también es comer bien. Este plan usa ${c.location} como mapa de sabores, '
            'sin exigir demasiados traslados y con ritmo ${c.timeTone}.',
        vibe: (c) =>
            'Gastro, cálida, con servilletas manchadas y sonrisa fácil.',
      ),
      _PlanVariant(
        title: (c) => '${c.location} sin romper la tarjeta',
        description: (c) =>
            'Un plan low-cost para sentir la ciudad con presupuesto ajustado: '
            'calles bonitas, paradas gratis y una recompensa pequeña al final.',
        itinerarySteps: (c) => [
          'Haz una ruta a pie por una zona icónica con plazas, fachadas y vida local.',
          'Busca una parada gratuita o barata: mirador, parque, museo libre o mercado.',
          'Cierra con snack, helado o bebida económica en una calle con ambiente.',
        ],
        whyItFits: (c) =>
            'Está pensado para viajar con cabeza: maximiza experiencia, minimiza gasto y '
            'mantiene la distancia ${c.distanceTone} para no perder tiempo moviéndote.',
        vibe: (c) =>
            'Ligera, lista, de viajero que encuentra oro sin pagar entrada.',
      ),
      _PlanVariant(
        title: (c) => 'El lado local de ${c.location}',
        description: (c) =>
            'Una ruta oculta para salir del circuito automático: barrio con carácter, '
            'sitios pequeños y una sensación más local que turística.',
        itinerarySteps: (c) => [
          'Empieza en un barrio menos evidente con cafetería, tienda o plaza con vida real.',
          'Explora una calle secundaria, galería pequeña, librería o patio escondido.',
          'Termina en una barra o terraza donde parezca que la gente repite.',
        ],
        whyItFits: (c) =>
            'Si ya no quieres otra lista de imprescindibles, esta ruta te acerca a ${c.location} '
            'desde dentro: menos checklist, más historia para contar.',
        vibe: (c) =>
            'Local, secreta, con mapa mental en vez de mapa turístico.',
      ),
    ],
    'Grupo': [
      _PlanVariant(
        title: (c) => 'Plan barato para ${c.groupCopy}',
        description: (c) =>
            'Una ruta fácil para ${c.groupCopy} en ${c.location}: gastar poco, '
            'moverse sin líos y que nadie tenga que defender demasiado la idea en el chat.',
        itinerarySteps: (c) => [
          'Quedad en un punto céntrico con opciones baratas cerca.',
          'Compartid algo sencillo: pizza, tapas, bocatas buenos o mercado informal.',
          'Cerrad con paseo ${c.distanceTone}, mirador o postre económico para todos.',
        ],
        whyItFits: (c) =>
            'Está pensado para ${c.groupCopy}: presupuesto ${c.budgetTone}, ritmo ${c.timeTone} '
            'y decisiones simples para que nadie se quede fuera.',
        vibe: (c) => 'Democrática, ligera, con energía de acuerdo improbable.',
      ),
      _PlanVariant(
        title: (c) => 'Cena y paseo sin debate',
        description: (c) =>
            'Un plan de grupo clásico, pero bien armado: cena compartida, paseo con aire '
            'y un cierre flexible para ${c.groupCopy}.',
        itinerarySteps: (c) => [
          'Reservad o elegid una mesa cómoda con platos al centro en ${c.location}.',
          'Salid a caminar por una zona agradable para bajar el ruido de la mesa.',
          'Última parada opcional: helado, copa tranquila o terraza si el grupo sigue.',
        ],
        whyItFits: (c) =>
            'Funciona porque evita extremos: todos comen, todos caminan un poco y '
            'el final permite alargar sin obligar a nadie.',
        vibe: (c) =>
            'Comunal, cálida, con sobremesa que se mueve por la ciudad.',
      ),
      _PlanVariant(
        title: (c) => 'La actividad que desbloquea al grupo',
        description: (c) =>
            'Un plan para cuando ${c.groupCopy} necesita algo más que sentarse: '
            'actividad breve, risas rápidas y una parada final para comentar la jugada.',
        itinerarySteps: (c) => [
          'Empezad con una actividad: bolos, karaoke suave, arcade, escape corto o trivia.',
          'Seguid con bebida o picoteo cerca para comentar los mejores momentos.',
          'Cerrad con foto grupal, paseo corto o última ronda según la energía.',
        ],
        whyItFits: (c) =>
            'El grupo no tiene que generar conversación desde cero: la actividad hace de motor '
            'y el resto del plan acompaña sin complicarse.',
        vibe: (c) =>
            'Juguetona, ruidosa, con bromas que sobreviven al día siguiente.',
      ),
      _PlanVariant(
        title: (c) => 'Última hora, buen resultado',
        description: (c) =>
            'Un plan improvisado para ${c.groupCopy} cuando ya es tarde para discutir: '
            'punto de encuentro claro, primera parada segura y final abierto.',
        itinerarySteps: (c) => [
          'Mandad una ubicación fácil de encontrar y poned hora límite de llegada.',
          'Entrad en un sitio versátil: barra, terraza, mercado o local con mesas libres.',
          'Decidid el cierre en movimiento: paseo, postre, copa o vuelta tranquila.',
        ],
        whyItFits: (c) =>
            'Está hecho para desbloquear el chat: pocas decisiones, distancia ${c.distanceTone} '
            'y margen para que el plan se adapte al tamaño ${c.groupSizeLabel}.',
        vibe: (c) => 'Espontánea, práctica, de "vale, este sí".',
      ),
    ],
  };

  static String _resolvedLocation(String location) {
    final trimmedLocation = location.trim();
    return trimmedLocation.isEmpty ? 'tu zona' : trimmedLocation;
  }

  static String _momentCopyFor(String moment) {
    switch (moment) {
      case 'Ahora':
        return 'ahora mismo';
      case 'Mañana':
        return 'mañana';
      case 'Tarde':
        return 'esta tarde';
      case 'Noche':
        return 'esta noche';
      case 'Fin de semana':
        return 'este fin de semana';
      default:
        return moment.toLowerCase();
    }
  }

  static String _estimatedCostFor(String budget) {
    switch (budget) {
      case 'Gratis':
        return '0-10 €';
      case '€':
        return '10-25 €';
      case '€€€':
        return '60 €+';
      case '€€':
      default:
        return '25-60 €';
    }
  }

  static String _estimatedDurationFor(String time) {
    switch (time) {
      case '1h':
        return '1 hora';
      case '3h':
        return '3 horas';
      case 'Toda la noche':
        return 'Toda la noche';
      case '2h':
      default:
        return '2 horas';
    }
  }

  static String _estimatedDistanceFor(String distance) {
    switch (distance) {
      case 'Cerca':
        return 'A 10-15 min';
      case 'Media':
        return 'Hasta 30 min';
      case 'Me da igual':
      default:
        return 'Sin límite fijo';
    }
  }
}

class _PlanContext {
  const _PlanContext({
    required this.mood,
    required this.budget,
    required this.time,
    required this.distance,
    required this.moment,
    required this.location,
    required this.weather,
    this.groupSize,
  });

  final String mood;
  final String budget;
  final String time;
  final String distance;
  final String moment;
  final String location;
  final String weather;
  final String? groupSize;

  String get momentCopy => MockPlanGenerator._momentCopyFor(moment);

  String get timeLabel => MockPlanGenerator._estimatedDurationFor(time);

  String get groupSizeLabel => groupSize ?? '4-6';

  String get groupCopy => 'un grupo de $groupSizeLabel personas';

  String get timeTone {
    switch (time) {
      case '1h':
        return 'compacto y directo';
      case '3h':
        return 'pausado, con espacio para improvisar';
      case 'Toda la noche':
        return 'amplio, con margen para alargar sin mirar el reloj';
      case '2h':
      default:
        return 'equilibrado';
    }
  }

  String get budgetTone {
    switch (budget) {
      case 'Gratis':
        return 'sin gastar casi nada';
      case '€':
        return 'asequible';
      case '€€€':
        return 'más especial y cuidado';
      case '€€':
      default:
        return 'con margen para algo memorable';
    }
  }

  String get distanceTone {
    switch (distance) {
      case 'Cerca':
        return 'cerca y sin grandes desplazamientos';
      case 'Media':
        return 'con un pequeño cambio de zona';
      case 'Me da igual':
      default:
        return 'sin miedo a moverse un poco más';
    }
  }

  String get finalStop {
    switch (moment) {
      case 'Mañana':
        return 'Un cierre con panadería, mercado o paseo soleado';
      case 'Tarde':
        return 'Una última parada de merienda, terraza o librería';
      case 'Noche':
        return 'Una última copa, mirador o postre con luces bajas';
      case 'Fin de semana':
        return 'Un cierre largo: terraza, sobremesa o paseo sin mirar la hora';
      case 'Ahora':
      default:
        return 'Una parada final fácil de decidir sobre la marcha';
    }
  }

  String get weatherSentence {
    switch (weather) {
      case 'Lluvia':
        return 'Perfecto para un día de lluvia: más indoor, más refugio y menos calle innecesaria.';
      case 'Calor':
        return 'Pensado para calor: mejor tarde/noche, bebidas frías y paradas donde respirar.';
      case 'Frío':
        return 'Ideal si hace frío: sitios acogedores, luz cálida y trayectos sin castigo.';
      case 'Soleado':
        return 'Aprovecha el buen tiempo con más exterior, luz natural y una ruta que se siente abierta.';
      case 'Nublado':
        return 'Con cielo nublado funciona especialmente bien: flexible, cómodo y sin depender del sol.';
      case 'Automático':
      default:
        return 'Si el clima cambia, el plan mantiene alternativas fáciles para seguir fluyendo.';
    }
  }

  String get weatherWhyItFits {
    switch (weather) {
      case 'Lluvia':
        return 'Además, el clima empuja el plan hacia interiores con buena vibra.';
      case 'Calor':
        return 'El calor pide horarios más amables y lugares frescos, así que el ritmo evita agotarte.';
      case 'Frío':
        return 'El frío se compensa con paradas acogedoras y desplazamientos más inteligentes.';
      case 'Soleado':
        return 'El sol suma energía exterior sin perder la estructura del plan.';
      case 'Nublado':
        return 'El clima nublado deja margen para alternar calle e interiores sin que el plan pierda encanto.';
      case 'Automático':
      default:
        return 'El contexto de clima queda preparado para ajustar la experiencia sin complicarte.';
    }
  }

  String get weatherVibe {
    switch (weather) {
      case 'Lluvia':
        return 'Refugio elegante, cristales mojados y conversación larga.';
      case 'Calor':
        return 'Atardecer, hielo en el vaso y energía ligera.';
      case 'Frío':
        return 'Abrigo, madera, luz cálida y plan de quedarse.';
      case 'Soleado':
        return 'Aire libre, piel al sol y ciudad abierta.';
      case 'Nublado':
        return 'Suave, fotogénica y un poco misteriosa.';
      case 'Automático':
      default:
        return 'Flexible, lista para lo que marque el cielo.';
    }
  }
}

class _PlanVariant {
  const _PlanVariant({
    required this.title,
    required this.description,
    required this.itinerarySteps,
    required this.whyItFits,
    required this.vibe,
  });

  final String Function(_PlanContext context) title;
  final String Function(_PlanContext context) description;
  final List<String> Function(_PlanContext context) itinerarySteps;
  final String Function(_PlanContext context) whyItFits;
  final String Function(_PlanContext context) vibe;
}
