class AppTexts {
  const AppTexts._();

  static const AppTextValues es = AppTextValues(
    languageCode: 'es',
    appName: 'Tonight',
    tagline: 'Planes perfectos para ahora.',
    home: 'Inicio',
    explore: 'Explorar',
    saved: 'Guardados',
    settings: 'Ajustes',
    community: 'Comunidad',
    chat: 'Chat',
    chatTitle: 'Cuéntame tu plan',
    chatSubtitle:
        'Dime dónde estás, con quién vas, presupuesto y qué te apetece.',
    chatExamples: [
      'Tengo 20€ y estoy con mi pareja',
      'Plan barato por Madrid',
      'Algo chill para esta tarde',
      'Estoy de viaje y quiero algo local',
    ],
    chatInputHint:
        'Ej: Estoy en Madrid, tengo 20 euros, voy con mi mujer y quiero un plan por esta zona.',
    chatEmptyMessage: 'Cuéntame un poco qué te apetece y te preparo algo.',
    chatGenerating: 'Generando...',
    chatLoadingTitle: 'Interpretando tu plan',
    chatLoadingMessage:
        'Tonight está leyendo contexto, presupuesto, compañía y mood.',
    chatFallbackMessage:
        'No se pudo conectar con la IA. Te he preparado un plan sorpresa.',
    chatErrorMessage: 'No se pudo generar el plan. Inténtalo de nuevo.',
    createPlan: 'Crear mi plan',
    surpriseMe: 'Sorpréndeme',
    planOfTheDay: 'Plan del día',
    lastPlan: 'Último plan',
    premium: 'Premium',
    language: 'Idioma',
    notifications: 'Notificaciones',
    planSetupTitle: 'Crear plan',
    planSetupHeading: 'Vamos a preparar tu plan',
    selectedMoodPrefix: 'Mood seleccionado',
    moment: 'Momento',
    weather: 'Clima',
    groupSize: 'Tamaño del grupo',
    budget: 'Presupuesto',
    timeAvailable: 'Tiempo disponible',
    distance: 'Distancia',
    generatePlan: 'Generar plan',
    whereAreYou: '¿Dónde estás?',
    whereAreYouTravel: '¿A qué ciudad vas?',
    locationHelper: 'Puedes escribir una zona o usar tu ubicación actual',
    useMyLocation: 'Usar mi ubicación',
    findingLocation: 'Buscando ubicación...',
    locationError:
        'No hemos podido detectar tu ubicación. Puedes escribirla manualmente.',
    generatingTitle: 'Generando plan',
    cancel: 'Cancelar',
    creatingYourPlan: 'Creando tu plan',
    generatingSubtitle:
        'La IA está cruzando señales para que Tonight no parezca una lista cualquiera.',
    generatingError: 'No se pudo generar el plan. Inténtalo de nuevo.',
    generatingPhases: [
      'Leyendo tu mood',
      'Analizando clima y zona',
      'Buscando la mejor vibe',
      'Montando tu plan',
      'Preparando el toque final',
    ],
    planReadyTitle: 'Plan listo',
    planReadyHeading: 'Tu plan está listo',
    sharePlan: 'Compartir plan',
    shareText: 'Compartir texto',
    shareImage: 'Compartir imagen',
    preparingImage: 'Preparando imagen...',
    editCriteria: 'Editar criterios',
    generateAnother: 'Generar otro',
    generatingAnother: 'Generando otro...',
    openRoute: 'Abrir ruta',
    whyItFits: 'Por qué te pega',
    planVibe: 'Vibe del plan',
    itinerary: 'Itinerario',
    openMaps: 'Ver en Maps',
    useThisPlan: 'Usar este plan',
    favoriteSave: 'Guardar favorito',
    favoriteRemove: 'Quitar favorito',
    deletePlan: 'Borrar plan',
    delete: 'Borrar',
    planDeleted: 'Plan borrado',
    shareError: 'No se pudo compartir el plan. Inténtalo de nuevo.',
    imageError: 'No se pudo preparar la imagen. Inténtalo de nuevo.',
    mapsError: 'No se pudo abrir Google Maps.',
    anotherPlanError: 'No se pudo generar otro plan. Inténtalo de nuevo.',
    planDetailTitle: 'Detalle del plan',
    savedSubtitle: 'Tus planes recientes y favoritos viven aquí.',
    savedLoadErrorTitle: 'No pudimos cargar tus planes',
    savedLoadErrorMessage:
        'Algo falló leyendo tus datos locales. Inténtalo de nuevo en un momento.',
    searchPlans: 'Buscar planes...',
    noFilterResultsTitle: 'No encontramos ningún plan con esos filtros.',
    noFilterResultsMessage: 'Prueba con otro mood, ubicación o palabra clave.',
    results: 'Resultados',
    history: 'Historial',
    favorites: 'Favoritos',
    noSavedPlansTitle: 'Todavía no has guardado ningún plan',
    noSavedPlansMessage: 'Cuando crees o marques favoritos, aparecerán aquí.',
    noSavedPlansDetail: 'Todavía no hay planes guardados.',
    deleteHistoryMessage:
        'Se eliminará este plan del historial de este dispositivo.',
    deleteFavoritesMessage:
        'Se eliminará este plan de favoritos de este dispositivo.',
    deleteAllMessage:
        'Se eliminará este plan de historial y favoritos de este dispositivo.',
    exploreSubtitle: 'Descubre planes populares',
    trending: 'Trending',
    startByVibe: 'Empieza por una vibe',
    startByVibeSubtitle:
        'Toca una categoría y Tonight prepara el plan con ese mood desde el primer paso.',
    communitySubtitle: 'Planes que están probando otros usuarios',
    communityRealtimeSoon: 'Comunidad próximamente en tiempo real',
    all: 'Todos',
    usePlan: 'Usar plan',
    premiumTitle: 'Tonight Premium',
    premiumSubtitle: 'Planes ilimitados para cualquier momento',
    premiumIncluded: 'Incluido en Premium',
    activateSoon: 'Activar próximamente',
    continueFree: 'Seguir gratis',
    paymentsSoon: 'Los pagos llegarán próximamente.',
    monthly: 'Mensual',
    annual: 'Anual',
    onboardingNext: 'Siguiente',
    onboardingStart: 'Empezar',
    onboardingTitle1: 'Planes perfectos para ahora',
    onboardingTitle2: 'Elige tu vibe',
    onboardingTitle3: 'Descubre tu próximo plan',
    onboardingTitle4: '¿Cuál es tu vibe favorita?',
    metaLocation: 'Ubicación',
    metaMood: 'Mood',
    metaBudget: 'Presupuesto',
    metaTime: 'Tiempo',
    metaCost: 'Coste',
    metaDuration: 'Duración',
    metaEstimatedCost: 'Coste estimado',
    metaGroup: 'Grupo',
  );

  static const AppTextValues en = AppTextValues(
    languageCode: 'en',
    appName: 'Tonight',
    tagline: 'Perfect plans for right now.',
    home: 'Home',
    explore: 'Explore',
    saved: 'Saved',
    settings: 'Settings',
    community: 'Community',
    chat: 'Chat',
    chatTitle: 'Tell me your plan',
    chatSubtitle:
        'Tell me where you are, who you are with, your budget and what you feel like doing.',
    chatExamples: [
      'I have €20 and I am with my partner',
      'Cheap plan around Madrid',
      'Something chill for this afternoon',
      'I am traveling and want something local',
    ],
    chatInputHint:
        'Example: I am in Madrid, I have 20 euros, I am with my partner and want a plan around here.',
    chatEmptyMessage: 'Tell me a little about what you feel like doing.',
    chatGenerating: 'Generating...',
    chatLoadingTitle: 'Reading your plan',
    chatLoadingMessage: 'Tonight is reading context, budget, company and mood.',
    chatFallbackMessage:
        'AI could not be reached. I prepared a surprise plan for you.',
    chatErrorMessage: "We couldn't generate the plan. Try again.",
    createPlan: 'Create my plan',
    surpriseMe: 'Surprise me',
    planOfTheDay: 'Plan of the day',
    lastPlan: 'Last plan',
    premium: 'Premium',
    language: 'Language',
    notifications: 'Notifications',
    planSetupTitle: 'Create plan',
    planSetupHeading: "Let's build your plan",
    selectedMoodPrefix: 'Selected mood',
    moment: 'Moment',
    weather: 'Weather',
    groupSize: 'Group size',
    budget: 'Budget',
    timeAvailable: 'Time available',
    distance: 'Distance',
    generatePlan: 'Generate plan',
    whereAreYou: 'Where are you?',
    whereAreYouTravel: 'Which city are you visiting?',
    locationHelper: 'Type an area or use your current location',
    useMyLocation: 'Use my location',
    findingLocation: 'Finding location...',
    locationError:
        "We couldn't detect your location. You can type it manually.",
    generatingTitle: 'Generating plan',
    cancel: 'Cancel',
    creatingYourPlan: 'Creating your plan',
    generatingSubtitle:
        'AI is crossing signals so Tonight feels smarter than a plain list.',
    generatingError: "We couldn't generate the plan. Try again.",
    generatingPhases: [
      'Reading your mood',
      'Checking weather and area',
      'Finding the best vibe',
      'Building your plan',
      'Adding the final touch',
    ],
    planReadyTitle: 'Plan ready',
    planReadyHeading: 'Your plan is ready',
    sharePlan: 'Share plan',
    shareText: 'Share text',
    shareImage: 'Share image',
    preparingImage: 'Preparing image...',
    editCriteria: 'Edit criteria',
    generateAnother: 'Generate another',
    generatingAnother: 'Generating another...',
    openRoute: 'Open route',
    whyItFits: 'Why it fits',
    planVibe: 'Plan vibe',
    itinerary: 'Itinerary',
    openMaps: 'View in Maps',
    useThisPlan: 'Use this plan',
    favoriteSave: 'Save favorite',
    favoriteRemove: 'Remove favorite',
    deletePlan: 'Delete plan',
    delete: 'Delete',
    planDeleted: 'Plan deleted',
    shareError: "We couldn't share the plan. Try again.",
    imageError: "We couldn't prepare the image. Try again.",
    mapsError: "We couldn't open Google Maps.",
    anotherPlanError: "We couldn't generate another plan. Try again.",
    planDetailTitle: 'Plan detail',
    savedSubtitle: 'Your recent and favorite plans live here.',
    savedLoadErrorTitle: "We couldn't load your plans",
    savedLoadErrorMessage:
        'Something failed while reading local data. Try again in a moment.',
    searchPlans: 'Search plans...',
    noFilterResultsTitle: "We couldn't find plans with those filters.",
    noFilterResultsMessage: 'Try another mood, location or keyword.',
    results: 'Results',
    history: 'History',
    favorites: 'Favorites',
    noSavedPlansTitle: "You haven't saved any plans yet",
    noSavedPlansMessage:
        'When you create or favorite plans, they will appear here.',
    noSavedPlansDetail: 'No saved plans yet.',
    deleteHistoryMessage: 'This plan will be removed from your local history.',
    deleteFavoritesMessage:
        'This plan will be removed from your local favorites.',
    deleteAllMessage:
        'This plan will be removed from local history and favorites.',
    exploreSubtitle: 'Discover popular plans',
    trending: 'Trending',
    startByVibe: 'Start with a vibe',
    startByVibeSubtitle:
        'Tap a category and Tonight will start the plan with that mood.',
    communitySubtitle: 'Plans other users are trying',
    communityRealtimeSoon: 'Real-time community coming soon',
    all: 'All',
    usePlan: 'Use plan',
    premiumTitle: 'Tonight Premium',
    premiumSubtitle: 'More plans, more context and fewer limits.',
    premiumIncluded: 'Included in Premium',
    activateSoon: 'Activate soon',
    continueFree: 'Continue free',
    paymentsSoon: 'Payments are coming soon.',
    monthly: 'Monthly',
    annual: 'Annual',
    onboardingNext: 'Next',
    onboardingStart: 'Start',
    onboardingTitle1: 'Perfect plans for right now',
    onboardingTitle2: 'Choose your vibe',
    onboardingTitle3: 'Discover your next plan',
    onboardingTitle4: "What's your favorite vibe?",
    metaLocation: 'Location',
    metaMood: 'Mood',
    metaBudget: 'Budget',
    metaTime: 'Time',
    metaCost: 'Cost',
    metaDuration: 'Duration',
    metaEstimatedCost: 'Estimated cost',
    metaGroup: 'Group',
  );

  static AppTextValues of(String languageCode) {
    return languageCode == 'en' ? en : es;
  }
}

class AppTextValues {
  const AppTextValues({
    required this.languageCode,
    required this.appName,
    required this.tagline,
    required this.home,
    required this.explore,
    required this.saved,
    required this.settings,
    required this.community,
    required this.chat,
    required this.chatTitle,
    required this.chatSubtitle,
    required this.chatExamples,
    required this.chatInputHint,
    required this.chatEmptyMessage,
    required this.chatGenerating,
    required this.chatLoadingTitle,
    required this.chatLoadingMessage,
    required this.chatFallbackMessage,
    required this.chatErrorMessage,
    required this.createPlan,
    required this.surpriseMe,
    required this.planOfTheDay,
    required this.lastPlan,
    required this.premium,
    required this.language,
    required this.notifications,
    required this.planSetupTitle,
    required this.planSetupHeading,
    required this.selectedMoodPrefix,
    required this.moment,
    required this.weather,
    required this.groupSize,
    required this.budget,
    required this.timeAvailable,
    required this.distance,
    required this.generatePlan,
    required this.whereAreYou,
    required this.whereAreYouTravel,
    required this.locationHelper,
    required this.useMyLocation,
    required this.findingLocation,
    required this.locationError,
    required this.generatingTitle,
    required this.cancel,
    required this.creatingYourPlan,
    required this.generatingSubtitle,
    required this.generatingError,
    required this.generatingPhases,
    required this.planReadyTitle,
    required this.planReadyHeading,
    required this.sharePlan,
    required this.shareText,
    required this.shareImage,
    required this.preparingImage,
    required this.editCriteria,
    required this.generateAnother,
    required this.generatingAnother,
    required this.openRoute,
    required this.whyItFits,
    required this.planVibe,
    required this.itinerary,
    required this.openMaps,
    required this.useThisPlan,
    required this.favoriteSave,
    required this.favoriteRemove,
    required this.deletePlan,
    required this.delete,
    required this.planDeleted,
    required this.shareError,
    required this.imageError,
    required this.mapsError,
    required this.anotherPlanError,
    required this.planDetailTitle,
    required this.savedSubtitle,
    required this.savedLoadErrorTitle,
    required this.savedLoadErrorMessage,
    required this.searchPlans,
    required this.noFilterResultsTitle,
    required this.noFilterResultsMessage,
    required this.results,
    required this.history,
    required this.favorites,
    required this.noSavedPlansTitle,
    required this.noSavedPlansMessage,
    required this.noSavedPlansDetail,
    required this.deleteHistoryMessage,
    required this.deleteFavoritesMessage,
    required this.deleteAllMessage,
    required this.exploreSubtitle,
    required this.trending,
    required this.startByVibe,
    required this.startByVibeSubtitle,
    required this.communitySubtitle,
    required this.communityRealtimeSoon,
    required this.all,
    required this.usePlan,
    required this.premiumTitle,
    required this.premiumSubtitle,
    required this.premiumIncluded,
    required this.activateSoon,
    required this.continueFree,
    required this.paymentsSoon,
    required this.monthly,
    required this.annual,
    required this.onboardingNext,
    required this.onboardingStart,
    required this.onboardingTitle1,
    required this.onboardingTitle2,
    required this.onboardingTitle3,
    required this.onboardingTitle4,
    required this.metaLocation,
    required this.metaMood,
    required this.metaBudget,
    required this.metaTime,
    required this.metaCost,
    required this.metaDuration,
    required this.metaEstimatedCost,
    required this.metaGroup,
  });

  final String languageCode;
  final String appName;
  final String tagline;
  final String home;
  final String explore;
  final String saved;
  final String settings;
  final String community;
  final String chat;
  final String chatTitle;
  final String chatSubtitle;
  final List<String> chatExamples;
  final String chatInputHint;
  final String chatEmptyMessage;
  final String chatGenerating;
  final String chatLoadingTitle;
  final String chatLoadingMessage;
  final String chatFallbackMessage;
  final String chatErrorMessage;
  final String createPlan;
  final String surpriseMe;
  final String planOfTheDay;
  final String lastPlan;
  final String premium;
  final String language;
  final String notifications;
  final String planSetupTitle;
  final String planSetupHeading;
  final String selectedMoodPrefix;
  final String moment;
  final String weather;
  final String groupSize;
  final String budget;
  final String timeAvailable;
  final String distance;
  final String generatePlan;
  final String whereAreYou;
  final String whereAreYouTravel;
  final String locationHelper;
  final String useMyLocation;
  final String findingLocation;
  final String locationError;
  final String generatingTitle;
  final String cancel;
  final String creatingYourPlan;
  final String generatingSubtitle;
  final String generatingError;
  final List<String> generatingPhases;
  final String planReadyTitle;
  final String planReadyHeading;
  final String sharePlan;
  final String shareText;
  final String shareImage;
  final String preparingImage;
  final String editCriteria;
  final String generateAnother;
  final String generatingAnother;
  final String openRoute;
  final String whyItFits;
  final String planVibe;
  final String itinerary;
  final String openMaps;
  final String useThisPlan;
  final String favoriteSave;
  final String favoriteRemove;
  final String deletePlan;
  final String delete;
  final String planDeleted;
  final String shareError;
  final String imageError;
  final String mapsError;
  final String anotherPlanError;
  final String planDetailTitle;
  final String savedSubtitle;
  final String savedLoadErrorTitle;
  final String savedLoadErrorMessage;
  final String searchPlans;
  final String noFilterResultsTitle;
  final String noFilterResultsMessage;
  final String results;
  final String history;
  final String favorites;
  final String noSavedPlansTitle;
  final String noSavedPlansMessage;
  final String noSavedPlansDetail;
  final String deleteHistoryMessage;
  final String deleteFavoritesMessage;
  final String deleteAllMessage;
  final String exploreSubtitle;
  final String trending;
  final String startByVibe;
  final String startByVibeSubtitle;
  final String communitySubtitle;
  final String communityRealtimeSoon;
  final String all;
  final String usePlan;
  final String premiumTitle;
  final String premiumSubtitle;
  final String premiumIncluded;
  final String activateSoon;
  final String continueFree;
  final String paymentsSoon;
  final String monthly;
  final String annual;
  final String onboardingNext;
  final String onboardingStart;
  final String onboardingTitle1;
  final String onboardingTitle2;
  final String onboardingTitle3;
  final String onboardingTitle4;
  final String metaLocation;
  final String metaMood;
  final String metaBudget;
  final String metaTime;
  final String metaCost;
  final String metaDuration;
  final String metaEstimatedCost;
  final String metaGroup;

  bool get isEnglish => languageCode == 'en';

  String moodLabel(String mood) {
    if (!isEnglish) {
      return mood;
    }

    return switch (mood) {
      'Cita' => 'Date',
      'Amigos' => 'Friends',
      'Solo' => 'Solo',
      'Chill' => 'Chill',
      'Fiesta' => 'Party',
      'Sorpresa' => 'Surprise',
      'Viaje' => 'Travel',
      'Grupo' => 'Group',
      _ => mood,
    };
  }

  String weatherLabel(String weather) {
    if (!isEnglish) {
      return weather;
    }

    return switch (weather) {
      'Automático' => 'Automatic',
      'Soleado' => 'Sunny',
      'Lluvia' => 'Rain',
      'Frío' => 'Cold',
      'Calor' => 'Hot',
      'Nublado' => 'Cloudy',
      _ => weather,
    };
  }

  String budgetLabel(String budget) {
    if (!isEnglish) {
      return budget;
    }

    return switch (budget) {
      'Gratis' => 'Free',
      _ => budget,
    };
  }

  String momentLabel(String moment) {
    if (!isEnglish) {
      return moment;
    }

    return switch (moment) {
      'Ahora' => 'Now',
      'Mañana' => 'Morning',
      'Tarde' => 'Afternoon',
      'Noche' => 'Night',
      'Fin de semana' => 'Weekend',
      _ => moment,
    };
  }

  String timeLabel(String time) {
    if (!isEnglish) {
      return time;
    }

    return switch (time) {
      'Toda la noche' => 'All night',
      _ => time,
    };
  }

  String distanceLabel(String distance) {
    if (!isEnglish) {
      return distance;
    }

    return switch (distance) {
      'Cerca' => 'Nearby',
      'Media' => 'Medium',
      'Me da igual' => "Doesn't matter",
      _ => distance,
    };
  }

  String filterLabel(String filter) {
    return switch (filter) {
      'Todos' => all,
      'Favoritos' => favorites,
      'Historial' => history,
      _ => moodLabel(filter),
    };
  }
}
