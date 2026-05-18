// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/main.dart';
import 'package:app/services/daily_plan_service.dart';
import 'package:app/services/local_plan_storage.dart';
import 'package:app/services/mock_plan_generator.dart';
import 'package:app/services/mock_places_service.dart';
import 'package:app/services/onboarding_service.dart';
import 'package:app/services/plan_generation_service.dart';
import 'package:app/services/premium_service.dart';
import 'package:app/services/usage_limits_service.dart';
import 'package:app/services/user_preferences_service.dart';
import 'package:app/services/weather_service.dart';
import 'package:app/widgets/mood_chip.dart';
import 'package:app/widgets/trending_plan_card.dart';

Finder _moodChipFinder(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is MoodChip && widget.label == label,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    WeatherService.debugAutomaticWeatherResolver = () async {
      return WeatherService.automaticWeather;
    };
    UsageLimitsService.debugNowProvider = null;
    await LocalPlanStorage.clear();
    await PremiumService.setPremiumMock(false);
  });

  Future<void> markOnboardingAsSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(OnboardingService.hasSeenOnboardingKey, true);
  }

  Future<void> markOnboardingAsSeenWithFavoriteVibe(String vibe) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(OnboardingService.hasSeenOnboardingKey, true);
    await preferences.setString(OnboardingService.favoriteVibeKey, vibe);
  }

  test('MockPlanGenerator returns a different plan per mood', () {
    const moods = [
      'Cita',
      'Amigos',
      'Solo',
      'Chill',
      'Fiesta',
      'Sorpresa',
      'Viaje',
      'Grupo',
    ];

    final titles = moods.map((mood) {
      return MockPlanGenerator.generate(
        mood: mood,
        budget: '€€',
        time: '2h',
        distance: 'Cerca',
        moment: 'Ahora',
        location: 'Madrid',
      ).title;
    }).toSet();

    expect(titles.length, moods.length);
  });

  test('MockPlanGenerator defaults empty location to tu zona', () {
    final plan = MockPlanGenerator.generate(
      mood: 'Chill',
      budget: 'Gratis',
      time: '1h',
      distance: 'Cerca',
      moment: 'Tarde',
      location: '   ',
    );

    expect(plan.location, 'tu zona');
  });

  test('MockPlacesService provides a local catalog with compatible places', () {
    final places = MockPlacesService.getPlaces();
    final compatiblePlaces = MockPlacesService.findCompatiblePlaces(
      mood: 'Cita',
      weather: 'Lluvia',
      budget: '€€',
      location: 'Madrid',
    );

    expect(places.length, greaterThanOrEqualTo(60));
    expect(places.every((place) => place.latitude != null), isTrue);
    expect(places.every((place) => place.longitude != null), isTrue);
    expect(compatiblePlaces.length, greaterThanOrEqualTo(3));
    expect(compatiblePlaces.first.moodTags, contains('Cita'));
  });

  test('MockPlacesService supports core cities and generic fallback', () {
    final places = MockPlacesService.getPlaces();
    final locations = places.map((place) => place.location).toSet();

    expect(
      locations,
      containsAll(['Madrid', 'Barcelona', 'Valencia', 'Sevilla']),
    );
    expect(
      locations.map((location) => location.toLowerCase()).toSet(),
      containsAll(['málaga', 'lisboa', 'parís', 'roma']),
    );

    final parisPlaces = MockPlacesService.findCompatiblePlaces(
      mood: 'Viaje',
      weather: 'Nublado',
      budget: '€€',
      location: 'Montmartre',
    );
    expect(parisPlaces.length, greaterThanOrEqualTo(3));
    expect(parisPlaces.every((place) => place.location == 'París'), isTrue);

    final fallbackPlaces = MockPlacesService.findCompatiblePlaces(
      mood: 'Cita',
      weather: 'Soleado',
      budget: 'Gratis',
      location: 'Bilbao',
    );
    expect(fallbackPlaces.length, greaterThanOrEqualTo(3));
    expect(fallbackPlaces.every((place) => place.location == 'Bilbao'), isTrue);
  });

  test('MockPlanGenerator can attach selected mock places', () {
    final plan = MockPlanGenerator.generate(
      mood: 'Cita',
      budget: '€€',
      time: '2h',
      distance: 'Cerca',
      moment: 'Tarde',
      location: 'Madrid',
      weather: 'Lluvia',
    );

    expect(plan.places.length, 3);
    expect(plan.places.map((place) => place.id).toSet().length, 3);
    expect(plan.itinerarySteps.first, contains(plan.places.first.name));
  });

  test('PlanGenerationService returns a generated plan with context', () async {
    const service = PlanGenerationService();

    final plan = await service.generatePlan(
      mood: 'Amigos',
      budget: '€€',
      time: '2h',
      distance: 'Media',
      moment: 'Noche',
      location: 'Barcelona',
      weather: 'Lluvia',
    );

    expect(plan.mood, 'Amigos');
    expect(plan.budget, '€€');
    expect(plan.time, '2h');
    expect(plan.distance, 'Media');
    expect(plan.moment, 'Noche');
    expect(plan.location, 'Barcelona');
    expect(plan.weather, 'Lluvia');
    expect(plan.description, contains('lluvia'));
  });

  test('PlanGenerationService keeps group size for group plans', () async {
    const service = PlanGenerationService();

    final plan = await service.generatePlan(
      mood: 'Grupo',
      budget: '€',
      time: '2h',
      distance: 'Cerca',
      moment: 'Ahora',
      location: 'Madrid',
      groupSize: '7+',
    );

    expect(plan.mood, 'Grupo');
    expect(plan.groupSize, '7+');
    expect(plan.description, contains('grupo'));
  });

  test('DailyPlanService returns the same plan for the same day', () {
    final morningPlan = DailyPlanService.getDailyPlan(
      now: DateTime(2026, 5, 15, 9),
    );
    final eveningPlan = DailyPlanService.getDailyPlan(
      now: DateTime(2026, 5, 15, 21),
    );
    final nextDayPlan = DailyPlanService.getDailyPlan(
      now: DateTime(2026, 5, 16, 9),
    );

    expect(morningPlan.id, eveningPlan.id);
    expect(nextDayPlan.id, isNot(morningPlan.id));
  });

  test('UserPreferencesService saves and loads defaults', () async {
    await UserPreferencesService.saveDefaultLocation('Madrid');
    await UserPreferencesService.saveDefaultBudget('€');
    await UserPreferencesService.saveDefaultTime('Toda la noche');
    await UserPreferencesService.saveDefaultDistance('Me da igual');

    final preferences = await UserPreferencesService.getPreferences();

    expect(preferences.defaultLocation, 'Madrid');
    expect(preferences.defaultBudget, '€');
    expect(preferences.defaultTime, 'Toda la noche');
    expect(preferences.defaultDistance, 'Me da igual');
  });

  test('WeatherService maps Open-Meteo weather to app labels', () {
    expect(
      WeatherService.labelFromWeather(weatherCode: 0, temperature: 22),
      'Soleado',
    );
    expect(
      WeatherService.labelFromWeather(weatherCode: 61, temperature: 18),
      'Lluvia',
    );
    expect(
      WeatherService.labelFromWeather(weatherCode: 3, temperature: 19),
      'Nublado',
    );
    expect(
      WeatherService.labelFromWeather(weatherCode: 0, temperature: 5),
      'Frío',
    );
    expect(
      WeatherService.labelFromWeather(weatherCode: 1, temperature: 34),
      'Calor',
    );
  });

  test('UsageLimitsService tracks and resets free daily plans', () async {
    UsageLimitsService.debugNowProvider = () => DateTime(2026, 5, 15, 10);

    expect(await UsageLimitsService.canGeneratePlan(), isTrue);
    for (
      var index = 0;
      index < UsageLimitsService.freeDailyPlanLimit;
      index++
    ) {
      await UsageLimitsService.registerPlanGenerated();
    }

    expect(await UsageLimitsService.getTodayUsage(), 5);
    expect(await UsageLimitsService.getRemainingPlans(), 0);
    expect(UsageLimitsService.getDailyLimit(), 5);
    expect(await UsageLimitsService.getRemainingPlansToday(), 0);
    expect(await UsageLimitsService.canGeneratePlan(), isFalse);

    UsageLimitsService.debugNowProvider = () => DateTime(2026, 5, 16, 10);

    expect(await UsageLimitsService.getTodayUsage(), 0);
    expect(await UsageLimitsService.canGeneratePlan(), isTrue);
  });

  test('PremiumService stores mock state and bypasses usage limits', () async {
    await PremiumService.setSelectedPlan(PremiumService.monthlyPlan);
    expect(await PremiumService.getSelectedPlan(), PremiumService.monthlyPlan);

    for (
      var index = 0;
      index < UsageLimitsService.freeDailyPlanLimit;
      index++
    ) {
      await UsageLimitsService.registerPlanGenerated();
    }

    expect(await UsageLimitsService.canGeneratePlan(), isFalse);

    await PremiumService.setPremiumMock(true);

    expect(await PremiumService.isPremium(), isTrue);
    expect(await UsageLimitsService.canGeneratePlan(), isTrue);
  });

  testWidgets('Tonight home renders the core experience', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    expect(find.text('Tonight'), findsOneWidget);
    expect(find.text('Planes perfectos para ahora.'), findsOneWidget);
    expect(find.text('Mañana · Tarde · Noche'), findsOneWidget);
    expect(find.text('Plan del día'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Te quedan 5 planes gratis hoy'), findsOneWidget);
    expect(find.text('Trending ahora'), findsOneWidget);
    expect(find.text('Ruta secreta de última hora'), findsOneWidget);
    expect(find.text('¿Qué buscas ahora?'), findsOneWidget);
    expect(_moodChipFinder('Cita'), findsOneWidget);
    expect(_moodChipFinder('Viaje'), findsOneWidget);
    expect(_moodChipFinder('Grupo'), findsOneWidget);
    expect(find.text('Sorpréndeme'), findsOneWidget);
    expect(find.text('Un plan rápido para ahora'), findsOneWidget);
    expect(find.text('Crear mi plan'), findsOneWidget);
    expect(find.text('Guardados'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });

  testWidgets('Tonight opens explore tab with trending and categories', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();

    expect(find.text('Explorar'), findsWidgets);
    expect(find.text('Descubre planes populares'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Empieza por una vibe'), findsOneWidget);
    expect(find.text('Ruta secreta de última hora'), findsOneWidget);

    await tester.ensureVisible(find.text('Viaje').last);
    await tester.tap(find.text('Viaje').last);
    await tester.pumpAndSettle();

    expect(find.text('Vamos a preparar tu plan'), findsOneWidget);
    expect(find.text('Mood seleccionado: Viaje'), findsOneWidget);
  });

  testWidgets('Tonight opens trending plan detail', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    final firstTrendingCard = find.byType(TrendingPlanCard).first;
    await tester.ensureVisible(firstTrendingCard);
    final trendingCardTopLeft = tester.getTopLeft(firstTrendingCard);
    await tester.tapAt(trendingCardTopLeft + const Offset(48, 48));
    await tester.pumpAndSettle();

    expect(find.text('Ruta secreta de última hora'), findsOneWidget);
    expect(find.text('Ruta del plan'), findsOneWidget);
    expect(find.text('Usar este plan'), findsOneWidget);
    expect(find.text('Compartir texto'), findsOneWidget);

    await tester.tap(find.text('Usar este plan'));
    await tester.pumpAndSettle();

    expect(find.text('Vamos a preparar tu plan'), findsOneWidget);
    expect(find.text('Mood seleccionado: Sorpresa'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Ahora'), findsOneWidget);
    expect(find.text('€€'), findsOneWidget);
  });

  testWidgets('Surprise me starts quick generation with defaults', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sorpréndeme'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Creando tu plan'), findsOneWidget);
    expect(
      find.text('Analizando mood, zona, clima y momento...'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('Tu plan está listo'), findsOneWidget);
    expect(find.text('Mood: Sorpresa'), findsOneWidget);
    expect(find.text('Ubicación: tu zona'), findsOneWidget);
    expect(find.text('Momento: Ahora'), findsOneWidget);
    expect(find.text('Clima: Automático'), findsOneWidget);
  });

  testWidgets('Surprise me uses saved user preferences', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await UserPreferencesService.saveDefaultLocation('Valencia');
    await UserPreferencesService.saveDefaultBudget('Gratis');
    await UserPreferencesService.saveDefaultTime('1h');
    await UserPreferencesService.saveDefaultDistance('Me da igual');

    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sorpréndeme'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    expect(find.text('Tu plan está listo'), findsOneWidget);
    expect(find.text('Ubicación: Valencia'), findsOneWidget);
    expect(find.text('Presupuesto: Gratis'), findsOneWidget);
    expect(find.text('Tiempo: 1h'), findsOneWidget);
    expect(find.text('Distancia: Me da igual'), findsOneWidget);
  });

  testWidgets('Daily plan opens detail and can be used as setup base', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    final dailyPlan = DailyPlanService.getDailyPlan();
    await tester.ensureVisible(find.text('Plan del día'));
    await tester.tap(find.text(dailyPlan.title));
    await tester.pumpAndSettle();

    expect(find.text(dailyPlan.title), findsOneWidget);
    expect(find.text('Ruta del plan'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Usar este plan'));
    await tester.tap(find.text('Usar este plan').first);
    await tester.pumpAndSettle();

    expect(find.text('Vamos a preparar tu plan'), findsOneWidget);
    expect(find.text('Mood seleccionado: ${dailyPlan.mood}'), findsOneWidget);
  });

  testWidgets('Settings screen clears data and can reopen onboarding', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await LocalPlanStorage.addToHistory(
      MockPlanGenerator.generate(
        mood: 'Chill',
        budget: 'Gratis',
        time: '1h',
        distance: 'Cerca',
        moment: 'Tarde',
        location: 'Madrid',
      ),
    );
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsWidgets);
    expect(find.text('Datos'), findsOneWidget);
    expect(find.text('Debug'), findsOneWidget);
    expect(find.text('Premium mock'), findsOneWidget);
    expect(find.text('Borrar historial'), findsOneWidget);
    expect(find.text('Borrar favoritos'), findsOneWidget);
    expect(find.text('Borrar todo'), findsOneWidget);
    expect(find.text('App'), findsOneWidget);
    expect(find.text('Versión 0.1.0'), findsOneWidget);
    expect(find.text('Ver onboarding de nuevo'), findsOneWidget);
    expect(find.text('Probar Crashlytics (debug/test)'), findsOneWidget);

    await tester.ensureVisible(find.text('Probar Crashlytics (debug/test)'));
    await tester.tap(find.text('Probar Crashlytics (debug/test)'));
    await tester.pumpAndSettle();
    expect(
      find.text('Error de prueba registrado en Crashlytics'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Borrar historial'));
    await tester.tap(find.text('Borrar historial'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar'), findsOneWidget);
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(find.text('Historial borrado'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver onboarding de nuevo'));
    await tester.tap(find.text('Ver onboarding de nuevo'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(OnboardingService.hasSeenOnboardingKey),
      isFalse,
    );
    expect(find.text('Planes perfectos para ahora'), findsOneWidget);
  });

  testWidgets('Tonight shows onboarding on first launch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    expect(find.text('Planes perfectos para ahora'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Elige tu vibe'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Descubre tu próximo plan'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cuál es tu vibe favorita?'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);

    await tester.tap(find.text('Amigos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(OnboardingService.hasSeenOnboardingKey), isTrue);
    expect(preferences.getString(OnboardingService.favoriteVibeKey), 'Amigos');
    expect(find.text('Tonight'), findsOneWidget);
  });

  testWidgets('Home shows favorite vibe shortcut when preference exists', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeenWithFavoriteVibe('Chill');
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    expect(find.text('Tu vibe favorita: Chill'), findsOneWidget);
    expect(find.text('Crear plan con esta vibe'), findsOneWidget);

    await tester.tap(find.text('Crear plan con esta vibe'));
    await tester.pumpAndSettle();

    expect(find.text('Vamos a preparar tu plan'), findsOneWidget);
    expect(find.text('Mood seleccionado: Chill'), findsOneWidget);
  });

  testWidgets('Saved plans screen renders empty state', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardados'));
    await tester.pumpAndSettle();

    expect(find.text('Historial'), findsWidgets);
    expect(find.text('Favoritos'), findsWidgets);
    expect(find.text('Todavía no hay planes guardados.'), findsWidgets);
  });

  testWidgets('Saved plans screen opens plan detail', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    final savedPlan = MockPlanGenerator.generate(
      mood: 'Solo',
      budget: '€',
      time: '2h',
      distance: 'Cerca',
      moment: 'Tarde',
      location: 'Madrid',
    );
    await LocalPlanStorage.addToHistory(savedPlan);

    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardados'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(savedPlan.title));
    await tester.pumpAndSettle();

    expect(find.text(savedPlan.title), findsOneWidget);
    expect(find.text('Ruta del plan'), findsOneWidget);
    expect(find.text('Itinerario completo'), findsOneWidget);
    expect(find.text('Compartir texto'), findsOneWidget);
    expect(find.text('Compartir imagen'), findsOneWidget);
    expect(find.text('Guardar favorito'), findsOneWidget);
  });

  testWidgets('Saved plans screen filters by search and quick chips', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    final soloPlan = MockPlanGenerator.generate(
      mood: 'Solo',
      budget: '€',
      time: '2h',
      distance: 'Cerca',
      moment: 'Tarde',
      location: 'Madrid',
    );
    final friendsPlan = MockPlanGenerator.generate(
      mood: 'Amigos',
      budget: '€€',
      time: '3h',
      distance: 'Media',
      moment: 'Noche',
      location: 'Barcelona',
    );
    await LocalPlanStorage.addToHistory(soloPlan);
    await LocalPlanStorage.addToFavorites(friendsPlan);

    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardados'));
    await tester.pumpAndSettle();

    expect(find.text('Buscar planes...'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Favoritos'), findsWidgets);
    expect(find.text(soloPlan.title), findsOneWidget);
    expect(find.text(friendsPlan.title), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Madrid');
    await tester.pumpAndSettle();

    expect(find.text(soloPlan.title), findsOneWidget);
    expect(find.text(friendsPlan.title), findsNothing);

    await tester.enterText(find.byType(TextField), 'No existe este plan');
    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos ningún plan con esos filtros.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoritos').first);
    await tester.pumpAndSettle();

    expect(find.text(friendsPlan.title), findsOneWidget);
    expect(find.text(soloPlan.title), findsNothing);
  });

  testWidgets('Tonight navigates to plan setup with selected mood', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(_moodChipFinder('Amigos'));
    await tester.tap(_moodChipFinder('Amigos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear mi plan'));
    await tester.pumpAndSettle();

    expect(find.text('Vamos a preparar tu plan'), findsOneWidget);
    expect(find.text('Mood seleccionado: Amigos'), findsOneWidget);
    expect(find.text('5 planes gratis restantes hoy'), findsOneWidget);
    expect(find.text('Momento'), findsOneWidget);
    expect(find.text('Clima'), findsOneWidget);
    expect(find.text('¿Dónde estás?'), findsOneWidget);
    expect(find.text('Presupuesto'), findsOneWidget);
    expect(find.text('Tiempo disponible'), findsOneWidget);
    expect(find.text('Distancia'), findsOneWidget);
    expect(find.text('Generar plan'), findsOneWidget);
  });

  testWidgets('Plan setup opens premium screen after the free daily limit', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    for (
      var index = 0;
      index < UsageLimitsService.freeDailyPlanLimit;
      index++
    ) {
      await UsageLimitsService.registerPlanGenerated();
    }

    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear mi plan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generar plan'));
    await tester.pumpAndSettle();

    expect(find.text('Tonight Premium'), findsOneWidget);
    expect(
      find.text('Planes ilimitados para cualquier momento'),
      findsOneWidget,
    );
    expect(find.text('29,99 €/año'), findsOneWidget);
    expect(find.text('Ahorra 50%'), findsOneWidget);
    expect(find.text('Activar próximamente'), findsOneWidget);
    expect(find.text('Seguir gratis'), findsOneWidget);
    expect(find.text('Creando tu plan'), findsNothing);
  });

  testWidgets('Home and setup show unlimited plans for premium mock', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await PremiumService.setPremiumMock(true);

    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    expect(find.text('Premium activo · planes ilimitados'), findsOneWidget);

    await tester.tap(find.text('Crear mi plan'));
    await tester.pumpAndSettle();

    expect(find.text('Premium activo · planes ilimitados'), findsOneWidget);
  });

  testWidgets('Plan setup preloads saved preferences without initial values', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await UserPreferencesService.saveDefaultLocation('Sevilla');
    await UserPreferencesService.saveDefaultBudget('Gratis');
    await UserPreferencesService.saveDefaultTime('Toda la noche');
    await UserPreferencesService.saveDefaultDistance('Me da igual');

    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear mi plan'));
    await tester.pumpAndSettle();

    expect(find.text('Vamos a preparar tu plan'), findsOneWidget);
    expect(find.text('Sevilla'), findsOneWidget);
    expect(find.text('Gratis'), findsOneWidget);
    expect(find.text('Toda la noche'), findsOneWidget);
    expect(find.text('Me da igual'), findsOneWidget);
  });

  testWidgets('Travel mood asks for destination city', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(_moodChipFinder('Viaje'));
    await tester.tap(_moodChipFinder('Viaje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear mi plan'));
    await tester.pumpAndSettle();

    expect(find.text('Mood seleccionado: Viaje'), findsOneWidget);
    expect(find.text('¿A qué ciudad vas?'), findsOneWidget);
    expect(find.text('Roma, París, Lisboa, Madrid...'), findsOneWidget);
  });

  testWidgets('Group mood asks for group size', (WidgetTester tester) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(_moodChipFinder('Grupo'));
    await tester.tap(_moodChipFinder('Grupo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear mi plan'));
    await tester.pumpAndSettle();

    expect(find.text('Mood seleccionado: Grupo'), findsOneWidget);
    expect(find.text('Tamaño del grupo'), findsOneWidget);
    expect(find.text('2-3'), findsOneWidget);
    expect(find.text('4-6'), findsOneWidget);
    expect(find.text('7+'), findsOneWidget);
  });

  testWidgets('Tonight navigates to the generated plan result', (
    WidgetTester tester,
  ) async {
    await markOnboardingAsSeen();
    await tester.pumpWidget(const TonightApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear mi plan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Malasaña');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Creando tu plan'), findsOneWidget);
    expect(
      find.text('Analizando mood, zona, clima y momento...'),
      findsOneWidget,
    );
    expect(find.text('Buscando sitios con buena vibra'), findsOneWidget);
    expect(find.text('Calculando tiempos y distancia'), findsOneWidget);
    expect(find.text('Preparando una experiencia diferente'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('Tu plan está listo'), findsOneWidget);
    expect(find.text('Plan recomendado'), findsOneWidget);
    expect(find.text('Ubicación: Malasaña'), findsOneWidget);
    expect(find.text('Momento: Ahora'), findsOneWidget);
    expect(find.text('Clima: Automático'), findsOneWidget);
    expect(find.textContaining('Malasaña'), findsWidgets);
    expect(find.text('Ruta del plan'), findsOneWidget);
    expect(find.text('Parada 1'), findsOneWidget);
    expect(find.text('Por qué te pega'), findsOneWidget);
    expect(find.text('Vibe del plan'), findsOneWidget);
    expect(find.text('Itinerario'), findsOneWidget);
    expect((await LocalPlanStorage.getHistory()).first.places.length, 3);
    expect(find.text('Compartir plan'), findsOneWidget);
    expect(find.text('Compartir imagen'), findsOneWidget);
    expect(find.text('Generar otro'), findsOneWidget);
    expect((await LocalPlanStorage.getHistory()).length, 1);

    await tester.tap(find.text('Guardar favorito'));
    await tester.pumpAndSettle();

    expect(find.text('Plan guardado en favoritos'), findsOneWidget);
    expect(find.text('Favorito guardado'), findsOneWidget);
    expect((await LocalPlanStorage.getFavorites()).length, 1);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar otro'));
    await tester.pump();

    expect(find.text('Generando otro...'), findsOneWidget);
    expect(
      find.text('Preparando una nueva opción con la misma vibe...'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Tu plan está listo'), findsOneWidget);
    expect((await LocalPlanStorage.getHistory()).length, 2);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Vamos a preparar tu plan'), findsOneWidget);
  });
}
