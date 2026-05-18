import '../models/place_model.dart';

class MockPlacesService {
  const MockPlacesService._();

  static List<PlaceModel> getPlaces() {
    return List<PlaceModel>.unmodifiable(_places);
  }

  static List<PlaceModel> findCompatiblePlaces({
    required String mood,
    required String weather,
    required String budget,
    required String location,
  }) {
    final userLocation = _cleanLocation(location);
    final targetCity = _cityFromUserLocation(userLocation);
    final exactMatches = _rankedPlaces(
      places: _places,
      mood: mood,
      weather: weather,
      budget: budget,
      location: userLocation,
      targetCity: targetCity,
      requireCity: true,
    );

    if (exactMatches.length >= 3) {
      return exactMatches;
    }

    final relaxedCityMatches = _rankedPlaces(
      places: _places,
      mood: mood,
      weather: weather,
      budget: budget,
      location: userLocation,
      targetCity: targetCity,
      requireCity: true,
      relaxWeather: true,
    );

    if (relaxedCityMatches.length >= 3) {
      return relaxedCityMatches;
    }

    final fallbackPlaces = _rankedPlaces(
      places: _genericPlaces,
      mood: mood,
      weather: weather,
      budget: budget,
      location: userLocation,
      targetCity: null,
      requireCity: false,
      relaxWeather: true,
    );
    final relaxedFallbackPlaces = fallbackPlaces.length >= 3
        ? fallbackPlaces
        : _mergeUniquePlaces([
            fallbackPlaces,
            _rankedPlaces(
              places: _genericPlaces,
              mood: mood,
              weather: weather,
              budget: '€€€',
              location: userLocation,
              targetCity: null,
              requireCity: false,
              relaxWeather: true,
            ),
          ]);

    final fallbackLocation = userLocation.isEmpty ? 'tu zona' : userLocation;
    return relaxedFallbackPlaces
        .map((place) => _copyPlaceWithLocation(place, fallbackLocation))
        .toList();
  }

  static List<PlaceModel> _mergeUniquePlaces(List<List<PlaceModel>> groups) {
    final mergedPlaces = <PlaceModel>[];
    final seenPlaceIds = <String>{};

    for (final group in groups) {
      for (final place in group) {
        if (seenPlaceIds.add(place.id)) {
          mergedPlaces.add(place);
        }
      }
    }

    return mergedPlaces;
  }

  static List<PlaceModel> _rankedPlaces({
    required List<PlaceModel> places,
    required String mood,
    required String weather,
    required String budget,
    required String location,
    required String? targetCity,
    required bool requireCity,
    bool relaxWeather = false,
  }) {
    final matches = <_ScoredPlace>[];
    final seenPlaceIds = <String>{};

    for (final place in places) {
      if (!seenPlaceIds.add(place.id)) {
        continue;
      }

      if (requireCity && !_matchesCity(place, location, targetCity)) {
        continue;
      }

      if (!_matchesBudget(place, budget)) {
        continue;
      }

      final moodScore = _moodScore(place, mood);
      if (moodScore == 0) {
        continue;
      }

      final weatherScore = _weatherScore(place, weather);
      if (weatherScore == 0 && !relaxWeather) {
        continue;
      }

      final score =
          moodScore +
          (relaxWeather && weatherScore == 0 ? 1 : weatherScore) +
          _budgetScore(place, budget) +
          _locationScore(place, location, targetCity);
      matches.add(_ScoredPlace(place: place, score: score));
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.map((match) => match.place).toList();
  }

  static bool _matchesCity(
    PlaceModel place,
    String userLocation,
    String? targetCity,
  ) {
    if (userLocation.isEmpty || userLocation == 'tu zona') {
      return true;
    }

    final normalizedPlace = _normalize(place.location);
    final normalizedUserLocation = _normalize(userLocation);
    final normalizedTargetCity = targetCity == null
        ? null
        : _normalize(targetCity);

    return normalizedPlace == normalizedTargetCity ||
        normalizedUserLocation.contains(normalizedPlace) ||
        normalizedPlace.contains(normalizedUserLocation);
  }

  static int _locationScore(
    PlaceModel place,
    String userLocation,
    String? targetCity,
  ) {
    if (userLocation.isEmpty || userLocation == 'tu zona') {
      return 1;
    }

    final normalizedPlace = _normalize(place.location);
    final normalizedUserLocation = _normalize(userLocation);
    final normalizedTargetCity = targetCity == null
        ? null
        : _normalize(targetCity);

    if (normalizedPlace == normalizedTargetCity) {
      return 6;
    }
    if (normalizedUserLocation.contains(normalizedPlace) ||
        normalizedPlace.contains(normalizedUserLocation)) {
      return 5;
    }
    return 0;
  }

  static int _moodScore(PlaceModel place, String mood) {
    if (place.moodTags.contains(mood)) {
      return 8;
    }
    if (place.moodTags.contains('Todos')) {
      return 3;
    }
    return 0;
  }

  static int _weatherScore(PlaceModel place, String weather) {
    if (weather == 'Automático' || weather == 'AutomÃ¡tico') {
      return 3;
    }
    if (place.weatherTags.contains(weather)) {
      return 5;
    }
    if (place.weatherTags.contains('Todos')) {
      return 2;
    }
    return 0;
  }

  static bool _matchesBudget(PlaceModel place, String budget) {
    return _priceRank(place.priceLevel) <= _priceRank(budget);
  }

  static int _budgetScore(PlaceModel place, String budget) {
    return 4 - (_priceRank(budget) - _priceRank(place.priceLevel)).abs();
  }

  static String _cleanLocation(String location) {
    final trimmedLocation = location.trim();
    return trimmedLocation.isEmpty ? 'tu zona' : trimmedLocation;
  }

  static String? _cityFromUserLocation(String userLocation) {
    final normalizedLocation = _normalize(userLocation);
    if (normalizedLocation.isEmpty || normalizedLocation == 'tu zona') {
      return null;
    }

    for (final entry in _cityAliases.entries) {
      final normalizedCity = _normalize(entry.key);
      if (normalizedLocation.contains(normalizedCity)) {
        return entry.key;
      }

      for (final alias in entry.value) {
        final normalizedAlias = _normalize(alias);
        if (normalizedLocation.contains(normalizedAlias)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ç', 'c');
  }

  static int _priceRank(String priceLevel) {
    switch (priceLevel) {
      case 'Gratis':
        return 0;
      case '€':
      case 'â‚¬':
        return 1;
      case '€€€':
      case 'â‚¬â‚¬â‚¬':
        return 3;
      case '€€':
      case 'â‚¬â‚¬':
      default:
        return 2;
    }
  }

  static PlaceModel _copyPlaceWithLocation(PlaceModel place, String location) {
    return PlaceModel(
      id: '${place.id}-${_normalize(location).replaceAll(' ', '-')}',
      name: place.name,
      category: place.category,
      location: location,
      moodTags: place.moodTags,
      weatherTags: place.weatherTags,
      priceLevel: place.priceLevel,
      description: place.description,
      latitude: place.latitude,
      longitude: place.longitude,
    );
  }

  static List<PlaceModel> _buildCityPlaces(_CitySeed city) {
    return [
      _place(
        city,
        suffix: 'cafe',
        name: city.cafeName,
        category: 'café',
        moodTags: const ['Cita', 'Solo', 'Chill'],
        weatherTags: const ['Lluvia', 'Frío', 'Nublado', 'Todos'],
        priceLevel: '€',
        description: city.cafeDescription,
        latOffset: 0.001,
        lngOffset: -0.001,
      ),
      _place(
        city,
        suffix: 'brunch',
        name: city.brunchName,
        category: 'brunch',
        moodTags: const ['Amigos', 'Chill', 'Solo', 'Grupo'],
        weatherTags: const ['Soleado', 'Nublado', 'Todos'],
        priceLevel: '€€',
        description: city.brunchDescription,
        latOffset: -0.001,
        lngOffset: 0.002,
      ),
      _place(
        city,
        suffix: 'restaurant',
        name: city.restaurantName,
        category: 'restaurante',
        moodTags: const ['Cita', 'Grupo', 'Amigos', 'Viaje'],
        weatherTags: const ['Frío', 'Lluvia', 'Nublado', 'Todos'],
        priceLevel: '€€',
        description: city.restaurantDescription,
        latOffset: 0.002,
        lngOffset: 0.001,
      ),
      _place(
        city,
        suffix: 'rooftop',
        name: city.rooftopName,
        category: 'rooftop',
        moodTags: const ['Cita', 'Amigos', 'Fiesta', 'Viaje'],
        weatherTags: const ['Soleado', 'Calor', 'Nublado'],
        priceLevel: '€€€',
        description: city.rooftopDescription,
        latOffset: 0.003,
        lngOffset: -0.002,
      ),
      _place(
        city,
        suffix: 'bar',
        name: city.barName,
        category: 'bar',
        moodTags: const ['Amigos', 'Fiesta', 'Grupo', 'Sorpresa'],
        weatherTags: const ['Lluvia', 'Frío', 'Nublado', 'Todos'],
        priceLevel: '€€',
        description: city.barDescription,
        latOffset: -0.002,
        lngOffset: -0.001,
      ),
      _place(
        city,
        suffix: 'museum',
        name: city.museumName,
        category: 'museo',
        moodTags: const ['Solo', 'Chill', 'Cita', 'Viaje', 'Sorpresa'],
        weatherTags: const ['Lluvia', 'Frío', 'Nublado'],
        priceLevel: city.freeMuseum ? 'Gratis' : '€',
        description: city.museumDescription,
        latOffset: 0.004,
        lngOffset: 0.003,
      ),
      _place(
        city,
        suffix: 'park',
        name: city.parkName,
        category: 'parque',
        moodTags: const ['Solo', 'Chill', 'Cita', 'Amigos'],
        weatherTags: const ['Soleado', 'Nublado'],
        priceLevel: 'Gratis',
        description: city.parkDescription,
        latOffset: -0.003,
        lngOffset: 0.004,
      ),
      _place(
        city,
        suffix: 'viewpoint',
        name: city.viewpointName,
        category: 'mirador',
        moodTags: const ['Cita', 'Solo', 'Viaje', 'Sorpresa', 'Chill'],
        weatherTags: const ['Soleado', 'Calor', 'Nublado'],
        priceLevel: 'Gratis',
        description: city.viewpointDescription,
        latOffset: 0.005,
        lngOffset: -0.004,
      ),
      _place(
        city,
        suffix: 'indoor',
        name: city.indoorName,
        category: 'actividad indoor',
        moodTags: const ['Sorpresa', 'Grupo', 'Amigos', 'Solo'],
        weatherTags: const ['Lluvia', 'Frío', 'Calor', 'Nublado'],
        priceLevel: '€€',
        description: city.indoorDescription,
        latOffset: -0.004,
        lngOffset: -0.003,
      ),
      _place(
        city,
        suffix: 'low-cost',
        name: city.lowCostName,
        category: 'plan low-cost',
        moodTags: const ['Amigos', 'Grupo', 'Viaje', 'Solo', 'Chill'],
        weatherTags: const ['Soleado', 'Calor', 'Nublado', 'Todos'],
        priceLevel: 'Gratis',
        description: city.lowCostDescription,
        latOffset: 0.006,
        lngOffset: 0.002,
      ),
      _place(
        city,
        suffix: 'walk',
        name: city.walkName,
        category: 'paseo',
        moodTags: const ['Cita', 'Solo', 'Chill', 'Viaje', 'Amigos'],
        weatherTags: const ['Soleado', 'Nublado', 'Calor'],
        priceLevel: 'Gratis',
        description: city.walkDescription,
        latOffset: -0.005,
        lngOffset: 0.001,
      ),
      _place(
        city,
        suffix: 'local',
        name: city.localName,
        category: 'experiencia local',
        moodTags: const ['Viaje', 'Sorpresa', 'Amigos', 'Grupo', 'Solo'],
        weatherTags: const ['Todos'],
        priceLevel: '€',
        description: city.localDescription,
        latOffset: 0.002,
        lngOffset: -0.005,
      ),
    ];
  }

  static PlaceModel _place(
    _CitySeed city, {
    required String suffix,
    required String name,
    required String category,
    required List<String> moodTags,
    required List<String> weatherTags,
    required String priceLevel,
    required String description,
    required double latOffset,
    required double lngOffset,
  }) {
    return PlaceModel(
      id: '${_normalize(city.name).replaceAll(' ', '-')}-$suffix',
      name: name,
      category: category,
      location: city.name,
      moodTags: moodTags,
      weatherTags: weatherTags,
      priceLevel: priceLevel,
      description: description,
      latitude: city.latitude + latOffset,
      longitude: city.longitude + lngOffset,
    );
  }

  static final List<PlaceModel> _places = List<PlaceModel>.unmodifiable(
    _citySeeds.expand(_buildCityPlaces),
  );

  static final List<PlaceModel> _genericPlaces = List<PlaceModel>.unmodifiable([
    PlaceModel(
      id: 'generic-cafe-refugio',
      name: 'Café Refugio',
      category: 'café',
      location: 'tu zona',
      moodTags: const ['Cita', 'Solo', 'Chill', 'Todos'],
      weatherTags: const ['Lluvia', 'Frío', 'Nublado', 'Todos'],
      priceLevel: '€',
      description:
          'Café cálido de barrio con mesas pequeñas y ritmo tranquilo.',
      latitude: 40.4168,
      longitude: -3.7038,
    ),
    PlaceModel(
      id: 'generic-mercado-vivo',
      name: 'Mercado Vivo',
      category: 'plan low-cost',
      location: 'tu zona',
      moodTags: const ['Amigos', 'Grupo', 'Viaje', 'Sorpresa'],
      weatherTags: const ['Todos'],
      priceLevel: '€',
      description:
          'Mercado informal con comida fácil, gente local y opciones para todos.',
      latitude: 41.3851,
      longitude: 2.1734,
    ),
    PlaceModel(
      id: 'generic-paseo-alto',
      name: 'Paseo Alto',
      category: 'paseo',
      location: 'tu zona',
      moodTags: const ['Solo', 'Chill', 'Cita', 'Viaje'],
      weatherTags: const ['Soleado', 'Nublado', 'Calor'],
      priceLevel: 'Gratis',
      description:
          'Ruta breve con aire, escaparates y una parada bonita para mirar la zona.',
      latitude: 38.7223,
      longitude: -9.1393,
    ),
    PlaceModel(
      id: 'generic-sala-luz',
      name: 'Sala Luz',
      category: 'actividad indoor',
      location: 'tu zona',
      moodTags: const ['Sorpresa', 'Grupo', 'Amigos', 'Solo'],
      weatherTags: const ['Lluvia', 'Frío', 'Calor', 'Nublado'],
      priceLevel: '€€',
      description:
          'Actividad indoor compacta con estética cuidada y conversación fácil después.',
      latitude: 48.8566,
      longitude: 2.3522,
    ),
    PlaceModel(
      id: 'generic-bar-vinilo',
      name: 'Bar Vinilo',
      category: 'bar',
      location: 'tu zona',
      moodTags: const ['Amigos', 'Fiesta', 'Grupo', 'Sorpresa'],
      weatherTags: const ['Todos'],
      priceLevel: '€€',
      description:
          'Bar con música reconocible, primera ronda sencilla y energía de plan vivo.',
      latitude: 41.9028,
      longitude: 12.4964,
    ),
    PlaceModel(
      id: 'generic-mirador-claro',
      name: 'Mirador Claro',
      category: 'mirador',
      location: 'tu zona',
      moodTags: const ['Cita', 'Solo', 'Chill', 'Viaje', 'Sorpresa'],
      weatherTags: const ['Soleado', 'Nublado', 'Calor', 'Todos'],
      priceLevel: 'Gratis',
      description:
          'Mirador sencillo con aire, pausa fotogÃ©nica y sensaciÃ³n de ciudad propia.',
      latitude: 36.7213,
      longitude: -4.4214,
    ),
    PlaceModel(
      id: 'generic-plaza-local',
      name: 'Plaza Local',
      category: 'experiencia local',
      location: 'tu zona',
      moodTags: const ['Todos'],
      weatherTags: const ['Todos'],
      priceLevel: 'Gratis',
      description:
          'Plaza o rincÃ³n de barrio para observar, sentarse un momento y decidir la siguiente parada.',
      latitude: 37.3891,
      longitude: -5.9845,
    ),
  ]);

  static const Map<String, List<String>> _cityAliases = {
    'Madrid': [
      'Malasaña',
      'Chueca',
      'Retiro',
      'Lavapiés',
      'Centro',
      'La Latina',
    ],
    'Barcelona': [
      'Gràcia',
      'Gracia',
      'Born',
      'Eixample',
      'Raval',
      'Barceloneta',
    ],
    'Valencia': ['Ruzafa', 'El Carmen', 'Cabanyal', 'Ciutat Vella'],
    'Sevilla': ['Triana', 'Alameda', 'Santa Cruz', 'Nervión'],
    'Málaga': ['Centro Histórico', 'Soho', 'Pedregalejo', 'La Malagueta'],
    'Lisboa': ['Alfama', 'Chiado', 'Bairro Alto', 'Baixa', 'Príncipe Real'],
    'París': ['Le Marais', 'Montmartre', 'Saint-Germain', 'Canal Saint-Martin'],
    'Roma': ['Trastevere', 'Monti', 'Prati', 'Centro Storico', 'Testaccio'],
  };

  static const List<_CitySeed> _citySeeds = [
    _CitySeed(
      name: 'Madrid',
      latitude: 40.4168,
      longitude: -3.7038,
      freeMuseum: true,
      cafeName: 'Café Aurora',
      cafeDescription:
          'Café de especialidad con luz suave, mesas pequeñas y calma de barrio.',
      brunchName: 'Brunch Bravo',
      brunchDescription:
          'Brunch luminoso con tostadas generosas, café serio y mesas compartidas.',
      restaurantName: 'Casa Nori',
      restaurantDescription:
          'Restaurante acogedor de platos al centro y luz cálida para hablar sin prisa.',
      rooftopName: 'Azotea Norte',
      rooftopDescription:
          'Rooftop urbano con vistas abiertas, cócteles cuidados y atardecer fácil.',
      barName: 'Bar Vinilo',
      barDescription:
          'Bar con vinilos, mesas altas y energía de primera ronda.',
      museumName: 'Museo Lumen',
      museumDescription:
          'Museo pequeño de fotografía y diseño con salas tranquilas.',
      parkName: 'Parque Alba',
      parkDescription:
          'Zona verde para caminar, sentarse y bajar revoluciones.',
      viewpointName: 'Mirador del Conde',
      viewpointDescription:
          'Mirador discreto con tejados, aire y sensación de ciudad abierta.',
      indoorName: 'Galería Oculta',
      indoorDescription:
          'Galería discreta con exposiciones cortas y estética cuidada.',
      lowCostName: 'Mercado Central',
      lowCostDescription:
          'Mercado informal con opciones rápidas, barras compartidas y ambiente real.',
      walkName: 'Paseo de las Letras',
      walkDescription:
          'Paseo corto entre fachadas bonitas, librerías y plazas con vida.',
      localName: 'Taller del Barrio',
      localDescription:
          'Experiencia local con artesanía, conversación cercana y recomendaciones reales.',
    ),
    _CitySeed(
      name: 'Barcelona',
      latitude: 41.3851,
      longitude: 2.1734,
      cafeName: 'Café Bruma',
      cafeDescription:
          'Café de esquina con ventanales, bollería fina y ritmo mediterráneo.',
      brunchName: 'Brunch del Born',
      brunchDescription:
          'Brunch con mesas de madera, huevos buenos y luz de media mañana.',
      restaurantName: 'Mesa Salada',
      restaurantDescription:
          'Restaurante de platos compartidos, producto de mercado y ambiente relajado.',
      rooftopName: 'Terraza Sal',
      rooftopDescription:
          'Terraza mediterránea para atardecer, cóctel y vistas sobre la ciudad.',
      barName: 'Patio Azul',
      barDescription:
          'Patio escondido para una primera bebida sin ruido excesivo.',
      museumName: 'Museo Bahía',
      museumDescription:
          'Museo de barrio con entrada amable y salas fáciles de recorrer.',
      parkName: 'Jardín Claro',
      parkDescription: 'Jardín tranquilo para caminar poco y respirar mucho.',
      viewpointName: 'Mirador del Mar',
      viewpointDescription:
          'Punto alto con brisa, horizonte azul y pausa fotogénica.',
      indoorName: 'Sala Pixel',
      indoorDescription:
          'Actividad indoor con piezas digitales, luz baja y un punto sorprendente.',
      lowCostName: 'Plaza del Sábado',
      lowCostDescription:
          'Plaza viva con bancos, música callejera y planes sin gasto obligatorio.',
      walkName: 'Paseo de Gràcia Lento',
      walkDescription:
          'Ruta urbana con escaparates, arquitectura y paradas fáciles.',
      localName: 'Bodega del Veí',
      localDescription:
          'Bodega local con vermut, tapas sencillas y conversación de barra.',
    ),
    _CitySeed(
      name: 'Valencia',
      latitude: 39.4699,
      longitude: -0.3763,
      cafeName: 'Horno Luna',
      cafeDescription:
          'Horno de barrio con café, dulces y mesas junto al cristal.',
      brunchName: 'Brunch Naranja',
      brunchDescription:
          'Brunch fresco con zumos, terraza suave y platos sin complicación.',
      restaurantName: 'Mesa Plaza',
      restaurantDescription:
          'Restaurante informal con platos compartidos y buena acústica.',
      rooftopName: 'Ático Turia',
      rooftopDescription:
          'Rooftop claro con vistas al cauce, copas frescas y aire de tarde.',
      barName: 'Sala Neón',
      barDescription: 'Bar pequeño con DJ, luz roja y primera pista fácil.',
      museumName: 'Museo del Patio',
      museumDescription:
          'Museo compacto con diseño, cerámica y una visita sin saturación.',
      parkName: 'Jardín del Río',
      parkDescription:
          'Parque amplio para caminar con aire, sombra y final abierto.',
      viewpointName: 'Mirador de la Marina',
      viewpointDescription:
          'Mirador con agua cerca, luz dorada y bancos para alargar.',
      indoorName: 'Cine Boutique',
      indoorDescription:
          'Cine pequeño con programación rara y butacas cómodas.',
      lowCostName: 'Lonja Viva',
      lowCostDescription:
          'Ruta low-cost entre mercado, plazas y detalles históricos.',
      walkName: 'Paseo Mar',
      walkDescription:
          'Paseo amplio para caminar con aire, luz y final abierto.',
      localName: 'Taller de Ruzafa',
      localDescription:
          'Espacio local con piezas independientes, charla fácil y recomendaciones de barrio.',
    ),
    _CitySeed(
      name: 'Sevilla',
      latitude: 37.3891,
      longitude: -5.9845,
      cafeName: 'Café Azahar',
      cafeDescription:
          'Café con sombra, mesas de mármol y aroma dulce de mañana.',
      brunchName: 'Brunch Alameda',
      brunchDescription:
          'Brunch informal con tostadas grandes, patio y ritmo de fin de semana.',
      restaurantName: 'Casa Candela',
      restaurantDescription:
          'Restaurante cálido con platos andaluces al centro y sobremesa fácil.',
      rooftopName: 'Terraza Giralda',
      rooftopDescription:
          'Terraza con vistas, luz naranja y sensación de postal viva.',
      barName: 'Taberna Mapa',
      barDescription: 'Taberna local de barra viva y recomendaciones fáciles.',
      museumName: 'Museo del Patio',
      museumDescription:
          'Museo pequeño con salas frescas y recorrido amable bajo techo.',
      parkName: 'Plaza Sombra',
      parkDescription:
          'Plaza con sombra, bancos y ambiente local para mirar lento.',
      viewpointName: 'Mirador del Río',
      viewpointDescription:
          'Punto abierto junto al agua para ver cómo cambia la luz.',
      indoorName: 'Cine Boutique Sur',
      indoorDescription:
          'Sala indoor con butacas cómodas, cine raro y aire fresco.',
      lowCostName: 'Ruta de la Sombra',
      lowCostDescription:
          'Plan gratuito de calles frescas, patios visibles y plazas con vida.',
      walkName: 'Paseo de Triana',
      walkDescription:
          'Paseo con río, azulejos, escaparates y parada dulce opcional.',
      localName: 'Corral de Oficios',
      localDescription:
          'Experiencia local con talleres, piezas hechas a mano y conversación cercana.',
    ),
    _CitySeed(
      name: 'Málaga',
      latitude: 36.7213,
      longitude: -4.4214,
      cafeName: 'Café Limonar',
      cafeDescription:
          'Café luminoso con mesas pequeñas, tostadas buenas y aire de costa.',
      brunchName: 'Brunch Soho',
      brunchDescription:
          'Brunch moderno con murales cerca, platos frescos y café largo.',
      restaurantName: 'Mesa del Puerto',
      restaurantDescription:
          'Restaurante de producto sencillo, platos al centro y ambiente mediterráneo.',
      rooftopName: 'Azotea Alcazaba',
      rooftopDescription:
          'Rooftop con vistas a tejados, piedra antigua y luz dorada.',
      barName: 'Bar Espeto',
      barDescription:
          'Bar vivo con primeras rondas fáciles y ambiente de encuentro.',
      museumName: 'Museo Azul',
      museumDescription:
          'Museo manejable con arte contemporáneo y salas frescas.',
      parkName: 'Parque Palmeral',
      parkDescription:
          'Parque con palmeras, sombra y paseo suave hacia el mar.',
      viewpointName: 'Mirador Gibralfaro',
      viewpointDescription:
          'Mirador alto con bahía, ciudad y final de foto inevitable.',
      indoorName: 'Sala Refugio',
      indoorDescription:
          'Actividad indoor fresca para días de calor o lluvia inesperada.',
      lowCostName: 'Mercado Claro',
      lowCostDescription:
          'Mercado local para picar barato y sentir la ciudad en movimiento.',
      walkName: 'Paseo del Muelle',
      walkDescription:
          'Ruta junto al puerto con brisa, bancos y final abierto.',
      localName: 'Taller del Soho',
      localDescription:
          'Experiencia local con arte urbano, tiendas pequeñas y conversación creativa.',
    ),
    _CitySeed(
      name: 'Lisboa',
      latitude: 38.7223,
      longitude: -9.1393,
      cafeName: 'Café Saudade',
      cafeDescription:
          'Café con azulejos, pasteles, mesas pequeñas y una calma muy lisboeta.',
      brunchName: 'Brunch Chiado',
      brunchDescription:
          'Brunch luminoso entre cuestas, café fuerte y platos para compartir.',
      restaurantName: 'Mesa Alfama',
      restaurantDescription:
          'Restaurante íntimo con cocina portuguesa, luz baja y platos honestos.',
      rooftopName: 'Terraço Tejo',
      rooftopDescription:
          'Rooftop con vistas al río, brisa y cócteles al atardecer.',
      barName: 'Bar Fado Novo',
      barDescription:
          'Bar pequeño con música, vino y energía de barrio antiguo.',
      museumName: 'Museu da Luz',
      museumDescription:
          'Museo compacto con diseño, historia y salas perfectas para lluvia.',
      parkName: 'Jardim Claro',
      parkDescription:
          'Jardín tranquilo para respirar entre cuestas y bancos con sombra.',
      viewpointName: 'Miradouro Alto',
      viewpointDescription: 'Mirador con tejados rojos, río y pausa larga.',
      indoorName: 'Atelier Baixa',
      indoorDescription:
          'Actividad indoor con talleres, piezas locales y estética cuidada.',
      lowCostName: 'Ruta de Azulejos',
      lowCostDescription:
          'Paseo gratis entre fachadas, miradores y calles con textura.',
      walkName: 'Paseo Alfama',
      walkDescription:
          'Ruta lenta por callejuelas, ropa tendida y música lejana.',
      localName: 'Tasquita Local',
      localDescription:
          'Experiencia local con barra sencilla, tapas portuguesas y recomendaciones cercanas.',
    ),
    _CitySeed(
      name: 'París',
      latitude: 48.8566,
      longitude: 2.3522,
      cafeName: 'Café Lumière',
      cafeDescription:
          'Café pequeño con sillas de terraza, croissant bueno y conversación baja.',
      brunchName: 'Brunch Marais',
      brunchDescription:
          'Brunch cuidado entre galerías, pan dulce y mesas fotogénicas.',
      restaurantName: 'Bistrot Minuit',
      restaurantDescription:
          'Bistrot íntimo con platos clásicos, luz cálida y ritmo elegante.',
      rooftopName: 'Toit Doré',
      rooftopDescription:
          'Rooftop con tejados parisinos, copa especial y atardecer de postal.',
      barName: 'Bar Velours',
      barDescription: 'Bar de terciopelo, música baja y energía sofisticada.',
      museumName: 'Galerie Pluie',
      museumDescription:
          'Museo/galería perfecto para lluvia, salas breves y mirada lenta.',
      parkName: 'Jardin Minéral',
      parkDescription: 'Parque urbano con bancos, fuentes y paseo suave.',
      viewpointName: 'Belvédère Secret',
      viewpointDescription:
          'Mirador discreto con tejados, luz azul y ciudad extensa.',
      indoorName: 'Cinéma Rouge',
      indoorDescription:
          'Sala indie con programación cuidada y refugio perfecto bajo techo.',
      lowCostName: 'Passage Libre',
      lowCostDescription:
          'Plan low-cost por pasajes cubiertos, escaparates y rincones clásicos.',
      walkName: 'Paseo Canal',
      walkDescription:
          'Paseo junto al canal con librerías, puentes y cafés cercanos.',
      localName: 'Atelier du Quartier',
      localDescription:
          'Experiencia local con diseño, talleres pequeños y conversación de barrio.',
    ),
    _CitySeed(
      name: 'Roma',
      latitude: 41.9028,
      longitude: 12.4964,
      cafeName: 'Caffè Ombra',
      cafeDescription:
          'Café italiano de barra rápida, mesas pequeñas y luz antigua.',
      brunchName: 'Brunch Monti',
      brunchDescription:
          'Brunch informal entre calles de piedra, café fuerte y platos sencillos.',
      restaurantName: 'Trattoria Sera',
      restaurantDescription:
          'Trattoria cálida con pasta al centro, vino y conversación larga.',
      rooftopName: 'Terrazza Roma',
      rooftopDescription:
          'Terraza con cúpulas, tejados y una copa que parece escena.',
      barName: 'Bar Vicolo',
      barDescription:
          'Bar escondido en callejón con aperitivo, música y ambiente local.',
      museumName: 'Museo Cortile',
      museumDescription:
          'Museo de patio tranquilo con historia, sombra y recorrido manejable.',
      parkName: 'Giardino Quieto',
      parkDescription:
          'Jardín con pinos, bancos y pausa verde entre monumentos.',
      viewpointName: 'Belvedere Luna',
      viewpointDescription:
          'Mirador con cúpulas, piedra cálida y final cinematográfico.',
      indoorName: 'Sala Mosaico',
      indoorDescription:
          'Actividad indoor con arte, mosaicos y refugio para calor o lluvia.',
      lowCostName: 'Ruta Fontana',
      lowCostDescription:
          'Plan gratuito entre fuentes, plazas y esquinas históricas.',
      walkName: 'Paseo Trastevere',
      walkDescription:
          'Paseo por calles vivas, ropa tendida, fachadas y barras cercanas.',
      localName: 'Bottega Locale',
      localDescription:
          'Experiencia local con artesanía, aperitivo y recomendaciones de quien vive allí.',
    ),
  ];
}

class _ScoredPlace {
  const _ScoredPlace({required this.place, required this.score});

  final PlaceModel place;
  final int score;
}

class _CitySeed {
  const _CitySeed({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.cafeName,
    required this.cafeDescription,
    required this.brunchName,
    required this.brunchDescription,
    required this.restaurantName,
    required this.restaurantDescription,
    required this.rooftopName,
    required this.rooftopDescription,
    required this.barName,
    required this.barDescription,
    required this.museumName,
    required this.museumDescription,
    required this.parkName,
    required this.parkDescription,
    required this.viewpointName,
    required this.viewpointDescription,
    required this.indoorName,
    required this.indoorDescription,
    required this.lowCostName,
    required this.lowCostDescription,
    required this.walkName,
    required this.walkDescription,
    required this.localName,
    required this.localDescription,
    this.freeMuseum = false,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String cafeName;
  final String cafeDescription;
  final String brunchName;
  final String brunchDescription;
  final String restaurantName;
  final String restaurantDescription;
  final String rooftopName;
  final String rooftopDescription;
  final String barName;
  final String barDescription;
  final String museumName;
  final String museumDescription;
  final String parkName;
  final String parkDescription;
  final String viewpointName;
  final String viewpointDescription;
  final String indoorName;
  final String indoorDescription;
  final String lowCostName;
  final String lowCostDescription;
  final String walkName;
  final String walkDescription;
  final String localName;
  final String localDescription;
  final bool freeMuseum;
}
