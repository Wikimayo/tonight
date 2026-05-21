import '../models/place_model.dart';
import '../utils/text_sanitizer.dart';

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
    final cleanMood = TextSanitizer.clean(mood);
    final moodTags = place.moodTags.map(TextSanitizer.clean).toSet();
    if (moodTags.contains(cleanMood)) {
      return 8;
    }
    if (moodTags.contains('Todos')) {
      return 3;
    }
    return 0;
  }

  static int _weatherScore(PlaceModel place, String weather) {
    final cleanWeather = TextSanitizer.clean(weather);
    final weatherTags = place.weatherTags.map(TextSanitizer.clean).toSet();
    if (cleanWeather == 'Automático') {
      return 3;
    }
    if (weatherTags.contains(cleanWeather)) {
      return 5;
    }
    if (weatherTags.contains('Todos')) {
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
    return TextSanitizer.clean(value)
        .trim()
        .toLowerCase()
        .replaceAll('Ã¡', 'a')
        .replaceAll('Ã ', 'a')
        .replaceAll('Ã¢', 'a')
        .replaceAll('Ã¤', 'a')
        .replaceAll('Ã£', 'a')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã¨', 'e')
        .replaceAll('Ãª', 'e')
        .replaceAll('Ã«', 'e')
        .replaceAll('Ã­', 'i')
        .replaceAll('Ã¬', 'i')
        .replaceAll('Ã®', 'i')
        .replaceAll('Ã¯', 'i')
        .replaceAll('Ã³', 'o')
        .replaceAll('Ã²', 'o')
        .replaceAll('Ã´', 'o')
        .replaceAll('Ã¶', 'o')
        .replaceAll('Ãµ', 'o')
        .replaceAll('Ãº', 'u')
        .replaceAll('Ã¹', 'u')
        .replaceAll('Ã»', 'u')
        .replaceAll('Ã¼', 'u')
        .replaceAll('Ã±', 'n')
        .replaceAll('Ã§', 'c');
  }

  static int _priceRank(String priceLevel) {
    switch (TextSanitizer.clean(priceLevel)) {
      case 'Gratis':
        return 0;
      case '€':
        return 1;
      case '€€€':
        return 3;
      case '€€':
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
      address: place.address,
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
        category: 'cafÃ©',
        moodTags: const ['Cita', 'Solo', 'Chill'],
        weatherTags: const ['Lluvia', 'FrÃ­o', 'Nublado', 'Todos'],
        priceLevel: 'â‚¬',
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
        priceLevel: 'â‚¬â‚¬',
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
        weatherTags: const ['FrÃ­o', 'Lluvia', 'Nublado', 'Todos'],
        priceLevel: 'â‚¬â‚¬',
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
        priceLevel: 'â‚¬â‚¬â‚¬',
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
        weatherTags: const ['Lluvia', 'FrÃ­o', 'Nublado', 'Todos'],
        priceLevel: 'â‚¬â‚¬',
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
        weatherTags: const ['Lluvia', 'FrÃ­o', 'Nublado'],
        priceLevel: city.freeMuseum ? 'Gratis' : 'â‚¬',
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
        weatherTags: const ['Lluvia', 'FrÃ­o', 'Calor', 'Nublado'],
        priceLevel: 'â‚¬â‚¬',
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
        priceLevel: 'â‚¬',
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
      name: TextSanitizer.clean(name),
      category: TextSanitizer.clean(category),
      location: TextSanitizer.clean(city.name),
      moodTags: moodTags.map(TextSanitizer.clean).toList(),
      weatherTags: weatherTags.map(TextSanitizer.clean).toList(),
      priceLevel: TextSanitizer.clean(priceLevel),
      description: TextSanitizer.clean(description),
      address: _addressFor(city, suffix),
      latitude: city.latitude + latOffset,
      longitude: city.longitude + lngOffset,
    );
  }

  static String _addressFor(_CitySeed city, String suffix) {
    final street = switch (suffix) {
      'cafe' => 'Calle Aurora 12',
      'brunch' => 'Plaza del Mercado 4',
      'restaurant' => 'Calle Mayor 28',
      'rooftop' => 'Avenida Central 17, azotea',
      'bar' => 'Calle de la Musica 8',
      'museum' => 'Paseo de las Artes 3',
      'park' => 'Entrada principal del parque',
      'viewpoint' => 'Camino del Mirador s/n',
      'indoor' => 'Calle Talleres 16',
      'low-cost' => 'Mercado municipal, puesto 6',
      'walk' => 'Inicio en Plaza Principal',
      'local' => 'Calle del Barrio 21',
      _ => 'Centro de la ciudad',
    };

    return '$street, ${TextSanitizer.clean(city.name)}';
  }

  static final List<PlaceModel> _places = List<PlaceModel>.unmodifiable(
    _citySeeds.expand(_buildCityPlaces),
  );

  static final List<PlaceModel> _genericPlaces = List<PlaceModel>.unmodifiable([
    PlaceModel(
      id: 'generic-cafe-refugio',
      name: 'CafÃ© Refugio',
      category: 'cafÃ©',
      location: 'tu zona',
      moodTags: const ['Cita', 'Solo', 'Chill', 'Todos'],
      weatherTags: const ['Lluvia', 'FrÃ­o', 'Nublado', 'Todos'],
      priceLevel: 'â‚¬',
      description:
          'CafÃ© cÃ¡lido de barrio con mesas pequeÃ±as y ritmo tranquilo.',
      address: 'Calle Principal 12',
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
      priceLevel: 'â‚¬',
      description:
          'Mercado informal con comida fÃ¡cil, gente local y opciones para todos.',
      address: 'Mercado municipal, puesto 6',
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
      address: 'Inicio en Plaza Central',
      latitude: 38.7223,
      longitude: -9.1393,
    ),
    PlaceModel(
      id: 'generic-sala-luz',
      name: 'Sala Luz',
      category: 'actividad indoor',
      location: 'tu zona',
      moodTags: const ['Sorpresa', 'Grupo', 'Amigos', 'Solo'],
      weatherTags: const ['Lluvia', 'FrÃ­o', 'Calor', 'Nublado'],
      priceLevel: 'â‚¬â‚¬',
      description:
          'Actividad indoor compacta con estÃ©tica cuidada y conversaciÃ³n fÃ¡cil despuÃ©s.',
      address: 'Calle Talleres 16',
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
      priceLevel: 'â‚¬â‚¬',
      description:
          'Bar con mÃºsica reconocible, primera ronda sencilla y energÃ­a de plan vivo.',
      address: 'Calle de la Musica 8',
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
          'Mirador sencillo con aire, pausa fotogÃƒÂ©nica y sensaciÃƒÂ³n de ciudad propia.',
      address: 'Camino del Mirador s/n',
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
          'Plaza o rincÃƒÂ³n de barrio para observar, sentarse un momento y decidir la siguiente parada.',
      address: 'Plaza del Barrio 1',
      latitude: 37.3891,
      longitude: -5.9845,
    ),
  ]);

  static const Map<String, List<String>> _cityAliases = {
    'Madrid': [
      'MalasaÃ±a',
      'Chueca',
      'Retiro',
      'LavapiÃ©s',
      'Centro',
      'La Latina',
    ],
    'Barcelona': [
      'GrÃ cia',
      'Gracia',
      'Born',
      'Eixample',
      'Raval',
      'Barceloneta',
    ],
    'Valencia': ['Ruzafa', 'El Carmen', 'Cabanyal', 'Ciutat Vella'],
    'Sevilla': ['Triana', 'Alameda', 'Santa Cruz', 'NerviÃ³n'],
    'MÃ¡laga': ['Centro HistÃ³rico', 'Soho', 'Pedregalejo', 'La Malagueta'],
    'Lisboa': ['Alfama', 'Chiado', 'Bairro Alto', 'Baixa', 'PrÃ­ncipe Real'],
    'ParÃ­s': [
      'Le Marais',
      'Montmartre',
      'Saint-Germain',
      'Canal Saint-Martin',
    ],
    'Roma': ['Trastevere', 'Monti', 'Prati', 'Centro Storico', 'Testaccio'],
  };

  static const List<_CitySeed> _citySeeds = [
    _CitySeed(
      name: 'Madrid',
      latitude: 40.4168,
      longitude: -3.7038,
      freeMuseum: true,
      cafeName: 'CafÃ© Aurora',
      cafeDescription:
          'CafÃ© de especialidad con luz suave, mesas pequeÃ±as y calma de barrio.',
      brunchName: 'Brunch Bravo',
      brunchDescription:
          'Brunch luminoso con tostadas generosas, cafÃ© serio y mesas compartidas.',
      restaurantName: 'Casa Nori',
      restaurantDescription:
          'Restaurante acogedor de platos al centro y luz cÃ¡lida para hablar sin prisa.',
      rooftopName: 'Azotea Norte',
      rooftopDescription:
          'Rooftop urbano con vistas abiertas, cÃ³cteles cuidados y atardecer fÃ¡cil.',
      barName: 'Bar Vinilo',
      barDescription:
          'Bar con vinilos, mesas altas y energÃ­a de primera ronda.',
      museumName: 'Museo Lumen',
      museumDescription:
          'Museo pequeÃ±o de fotografÃ­a y diseÃ±o con salas tranquilas.',
      parkName: 'Parque Alba',
      parkDescription:
          'Zona verde para caminar, sentarse y bajar revoluciones.',
      viewpointName: 'Mirador del Conde',
      viewpointDescription:
          'Mirador discreto con tejados, aire y sensaciÃ³n de ciudad abierta.',
      indoorName: 'GalerÃ­a Oculta',
      indoorDescription:
          'GalerÃ­a discreta con exposiciones cortas y estÃ©tica cuidada.',
      lowCostName: 'Mercado Central',
      lowCostDescription:
          'Mercado informal con opciones rÃ¡pidas, barras compartidas y ambiente real.',
      walkName: 'Paseo de las Letras',
      walkDescription:
          'Paseo corto entre fachadas bonitas, librerÃ­as y plazas con vida.',
      localName: 'Taller del Barrio',
      localDescription:
          'Experiencia local con artesanÃ­a, conversaciÃ³n cercana y recomendaciones reales.',
    ),
    _CitySeed(
      name: 'Barcelona',
      latitude: 41.3851,
      longitude: 2.1734,
      cafeName: 'CafÃ© Bruma',
      cafeDescription:
          'CafÃ© de esquina con ventanales, bollerÃ­a fina y ritmo mediterrÃ¡neo.',
      brunchName: 'Brunch del Born',
      brunchDescription:
          'Brunch con mesas de madera, huevos buenos y luz de media maÃ±ana.',
      restaurantName: 'Mesa Salada',
      restaurantDescription:
          'Restaurante de platos compartidos, producto de mercado y ambiente relajado.',
      rooftopName: 'Terraza Sal',
      rooftopDescription:
          'Terraza mediterrÃ¡nea para atardecer, cÃ³ctel y vistas sobre la ciudad.',
      barName: 'Patio Azul',
      barDescription:
          'Patio escondido para una primera bebida sin ruido excesivo.',
      museumName: 'Museo BahÃ­a',
      museumDescription:
          'Museo de barrio con entrada amable y salas fÃ¡ciles de recorrer.',
      parkName: 'JardÃ­n Claro',
      parkDescription: 'JardÃ­n tranquilo para caminar poco y respirar mucho.',
      viewpointName: 'Mirador del Mar',
      viewpointDescription:
          'Punto alto con brisa, horizonte azul y pausa fotogÃ©nica.',
      indoorName: 'Sala Pixel',
      indoorDescription:
          'Actividad indoor con piezas digitales, luz baja y un punto sorprendente.',
      lowCostName: 'Plaza del SÃ¡bado',
      lowCostDescription:
          'Plaza viva con bancos, mÃºsica callejera y planes sin gasto obligatorio.',
      walkName: 'Paseo de GrÃ cia Lento',
      walkDescription:
          'Ruta urbana con escaparates, arquitectura y paradas fÃ¡ciles.',
      localName: 'Bodega del VeÃ­',
      localDescription:
          'Bodega local con vermut, tapas sencillas y conversaciÃ³n de barra.',
    ),
    _CitySeed(
      name: 'Valencia',
      latitude: 39.4699,
      longitude: -0.3763,
      cafeName: 'Horno Luna',
      cafeDescription:
          'Horno de barrio con cafÃ©, dulces y mesas junto al cristal.',
      brunchName: 'Brunch Naranja',
      brunchDescription:
          'Brunch fresco con zumos, terraza suave y platos sin complicaciÃ³n.',
      restaurantName: 'Mesa Plaza',
      restaurantDescription:
          'Restaurante informal con platos compartidos y buena acÃºstica.',
      rooftopName: 'Ãtico Turia',
      rooftopDescription:
          'Rooftop claro con vistas al cauce, copas frescas y aire de tarde.',
      barName: 'Sala NeÃ³n',
      barDescription: 'Bar pequeÃ±o con DJ, luz roja y primera pista fÃ¡cil.',
      museumName: 'Museo del Patio',
      museumDescription:
          'Museo compacto con diseÃ±o, cerÃ¡mica y una visita sin saturaciÃ³n.',
      parkName: 'JardÃ­n del RÃ­o',
      parkDescription:
          'Parque amplio para caminar con aire, sombra y final abierto.',
      viewpointName: 'Mirador de la Marina',
      viewpointDescription:
          'Mirador con agua cerca, luz dorada y bancos para alargar.',
      indoorName: 'Cine Boutique',
      indoorDescription:
          'Cine pequeÃ±o con programaciÃ³n rara y butacas cÃ³modas.',
      lowCostName: 'Lonja Viva',
      lowCostDescription:
          'Ruta low-cost entre mercado, plazas y detalles histÃ³ricos.',
      walkName: 'Paseo Mar',
      walkDescription:
          'Paseo amplio para caminar con aire, luz y final abierto.',
      localName: 'Taller de Ruzafa',
      localDescription:
          'Espacio local con piezas independientes, charla fÃ¡cil y recomendaciones de barrio.',
    ),
    _CitySeed(
      name: 'Sevilla',
      latitude: 37.3891,
      longitude: -5.9845,
      cafeName: 'CafÃ© Azahar',
      cafeDescription:
          'CafÃ© con sombra, mesas de mÃ¡rmol y aroma dulce de maÃ±ana.',
      brunchName: 'Brunch Alameda',
      brunchDescription:
          'Brunch informal con tostadas grandes, patio y ritmo de fin de semana.',
      restaurantName: 'Casa Candela',
      restaurantDescription:
          'Restaurante cÃ¡lido con platos andaluces al centro y sobremesa fÃ¡cil.',
      rooftopName: 'Terraza Giralda',
      rooftopDescription:
          'Terraza con vistas, luz naranja y sensaciÃ³n de postal viva.',
      barName: 'Taberna Mapa',
      barDescription: 'Taberna local de barra viva y recomendaciones fÃ¡ciles.',
      museumName: 'Museo del Patio',
      museumDescription:
          'Museo pequeÃ±o con salas frescas y recorrido amable bajo techo.',
      parkName: 'Plaza Sombra',
      parkDescription:
          'Plaza con sombra, bancos y ambiente local para mirar lento.',
      viewpointName: 'Mirador del RÃ­o',
      viewpointDescription:
          'Punto abierto junto al agua para ver cÃ³mo cambia la luz.',
      indoorName: 'Cine Boutique Sur',
      indoorDescription:
          'Sala indoor con butacas cÃ³modas, cine raro y aire fresco.',
      lowCostName: 'Ruta de la Sombra',
      lowCostDescription:
          'Plan gratuito de calles frescas, patios visibles y plazas con vida.',
      walkName: 'Paseo de Triana',
      walkDescription:
          'Paseo con rÃ­o, azulejos, escaparates y parada dulce opcional.',
      localName: 'Corral de Oficios',
      localDescription:
          'Experiencia local con talleres, piezas hechas a mano y conversaciÃ³n cercana.',
    ),
    _CitySeed(
      name: 'MÃ¡laga',
      latitude: 36.7213,
      longitude: -4.4214,
      cafeName: 'CafÃ© Limonar',
      cafeDescription:
          'CafÃ© luminoso con mesas pequeÃ±as, tostadas buenas y aire de costa.',
      brunchName: 'Brunch Soho',
      brunchDescription:
          'Brunch moderno con murales cerca, platos frescos y cafÃ© largo.',
      restaurantName: 'Mesa del Puerto',
      restaurantDescription:
          'Restaurante de producto sencillo, platos al centro y ambiente mediterrÃ¡neo.',
      rooftopName: 'Azotea Alcazaba',
      rooftopDescription:
          'Rooftop con vistas a tejados, piedra antigua y luz dorada.',
      barName: 'Bar Espeto',
      barDescription:
          'Bar vivo con primeras rondas fÃ¡ciles y ambiente de encuentro.',
      museumName: 'Museo Azul',
      museumDescription:
          'Museo manejable con arte contemporÃ¡neo y salas frescas.',
      parkName: 'Parque Palmeral',
      parkDescription:
          'Parque con palmeras, sombra y paseo suave hacia el mar.',
      viewpointName: 'Mirador Gibralfaro',
      viewpointDescription:
          'Mirador alto con bahÃ­a, ciudad y final de foto inevitable.',
      indoorName: 'Sala Refugio',
      indoorDescription:
          'Actividad indoor fresca para dÃ­as de calor o lluvia inesperada.',
      lowCostName: 'Mercado Claro',
      lowCostDescription:
          'Mercado local para picar barato y sentir la ciudad en movimiento.',
      walkName: 'Paseo del Muelle',
      walkDescription:
          'Ruta junto al puerto con brisa, bancos y final abierto.',
      localName: 'Taller del Soho',
      localDescription:
          'Experiencia local con arte urbano, tiendas pequeÃ±as y conversaciÃ³n creativa.',
    ),
    _CitySeed(
      name: 'Lisboa',
      latitude: 38.7223,
      longitude: -9.1393,
      cafeName: 'CafÃ© Saudade',
      cafeDescription:
          'CafÃ© con azulejos, pasteles, mesas pequeÃ±as y una calma muy lisboeta.',
      brunchName: 'Brunch Chiado',
      brunchDescription:
          'Brunch luminoso entre cuestas, cafÃ© fuerte y platos para compartir.',
      restaurantName: 'Mesa Alfama',
      restaurantDescription:
          'Restaurante Ã­ntimo con cocina portuguesa, luz baja y platos honestos.',
      rooftopName: 'TerraÃ§o Tejo',
      rooftopDescription:
          'Rooftop con vistas al rÃ­o, brisa y cÃ³cteles al atardecer.',
      barName: 'Bar Fado Novo',
      barDescription:
          'Bar pequeÃ±o con mÃºsica, vino y energÃ­a de barrio antiguo.',
      museumName: 'Museu da Luz',
      museumDescription:
          'Museo compacto con diseÃ±o, historia y salas perfectas para lluvia.',
      parkName: 'Jardim Claro',
      parkDescription:
          'JardÃ­n tranquilo para respirar entre cuestas y bancos con sombra.',
      viewpointName: 'Miradouro Alto',
      viewpointDescription: 'Mirador con tejados rojos, rÃ­o y pausa larga.',
      indoorName: 'Atelier Baixa',
      indoorDescription:
          'Actividad indoor con talleres, piezas locales y estÃ©tica cuidada.',
      lowCostName: 'Ruta de Azulejos',
      lowCostDescription:
          'Paseo gratis entre fachadas, miradores y calles con textura.',
      walkName: 'Paseo Alfama',
      walkDescription:
          'Ruta lenta por callejuelas, ropa tendida y mÃºsica lejana.',
      localName: 'Tasquita Local',
      localDescription:
          'Experiencia local con barra sencilla, tapas portuguesas y recomendaciones cercanas.',
    ),
    _CitySeed(
      name: 'ParÃ­s',
      latitude: 48.8566,
      longitude: 2.3522,
      cafeName: 'CafÃ© LumiÃ¨re',
      cafeDescription:
          'CafÃ© pequeÃ±o con sillas de terraza, croissant bueno y conversaciÃ³n baja.',
      brunchName: 'Brunch Marais',
      brunchDescription:
          'Brunch cuidado entre galerÃ­as, pan dulce y mesas fotogÃ©nicas.',
      restaurantName: 'Bistrot Minuit',
      restaurantDescription:
          'Bistrot Ã­ntimo con platos clÃ¡sicos, luz cÃ¡lida y ritmo elegante.',
      rooftopName: 'Toit DorÃ©',
      rooftopDescription:
          'Rooftop con tejados parisinos, copa especial y atardecer de postal.',
      barName: 'Bar Velours',
      barDescription: 'Bar de terciopelo, mÃºsica baja y energÃ­a sofisticada.',
      museumName: 'Galerie Pluie',
      museumDescription:
          'Museo/galerÃ­a perfecto para lluvia, salas breves y mirada lenta.',
      parkName: 'Jardin MinÃ©ral',
      parkDescription: 'Parque urbano con bancos, fuentes y paseo suave.',
      viewpointName: 'BelvÃ©dÃ¨re Secret',
      viewpointDescription:
          'Mirador discreto con tejados, luz azul y ciudad extensa.',
      indoorName: 'CinÃ©ma Rouge',
      indoorDescription:
          'Sala indie con programaciÃ³n cuidada y refugio perfecto bajo techo.',
      lowCostName: 'Passage Libre',
      lowCostDescription:
          'Plan low-cost por pasajes cubiertos, escaparates y rincones clÃ¡sicos.',
      walkName: 'Paseo Canal',
      walkDescription:
          'Paseo junto al canal con librerÃ­as, puentes y cafÃ©s cercanos.',
      localName: 'Atelier du Quartier',
      localDescription:
          'Experiencia local con diseÃ±o, talleres pequeÃ±os y conversaciÃ³n de barrio.',
    ),
    _CitySeed(
      name: 'Roma',
      latitude: 41.9028,
      longitude: 12.4964,
      cafeName: 'CaffÃ¨ Ombra',
      cafeDescription:
          'CafÃ© italiano de barra rÃ¡pida, mesas pequeÃ±as y luz antigua.',
      brunchName: 'Brunch Monti',
      brunchDescription:
          'Brunch informal entre calles de piedra, cafÃ© fuerte y platos sencillos.',
      restaurantName: 'Trattoria Sera',
      restaurantDescription:
          'Trattoria cÃ¡lida con pasta al centro, vino y conversaciÃ³n larga.',
      rooftopName: 'Terrazza Roma',
      rooftopDescription:
          'Terraza con cÃºpulas, tejados y una copa que parece escena.',
      barName: 'Bar Vicolo',
      barDescription:
          'Bar escondido en callejÃ³n con aperitivo, mÃºsica y ambiente local.',
      museumName: 'Museo Cortile',
      museumDescription:
          'Museo de patio tranquilo con historia, sombra y recorrido manejable.',
      parkName: 'Giardino Quieto',
      parkDescription:
          'JardÃ­n con pinos, bancos y pausa verde entre monumentos.',
      viewpointName: 'Belvedere Luna',
      viewpointDescription:
          'Mirador con cÃºpulas, piedra cÃ¡lida y final cinematogrÃ¡fico.',
      indoorName: 'Sala Mosaico',
      indoorDescription:
          'Actividad indoor con arte, mosaicos y refugio para calor o lluvia.',
      lowCostName: 'Ruta Fontana',
      lowCostDescription:
          'Plan gratuito entre fuentes, plazas y esquinas histÃ³ricas.',
      walkName: 'Paseo Trastevere',
      walkDescription:
          'Paseo por calles vivas, ropa tendida, fachadas y barras cercanas.',
      localName: 'Bottega Locale',
      localDescription:
          'Experiencia local con artesanÃ­a, aperitivo y recomendaciones de quien vive allÃ­.',
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
