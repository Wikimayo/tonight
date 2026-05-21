require('dotenv').config();

const express = require('express');
const cors = require('cors');
const {
  generatePlanFromChatWithOpenAI,
  generatePlanWithOpenAI,
} = require('./services/openaiPlanService');
const {
  canUseAi,
  registerAiUse,
  getUsageStatus,
} = require('./services/rateLimitService');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/usage', (req, res) => {
  res.json(getUsageStatus());
});

app.post('/generate-plan', async (req, res) => {
  const {
    mood,
    budget,
    time,
    distance,
    moment,
    location,
    weather,
    groupSize,
    language,
  } = req.body;

  const missingFields = [
    'mood',
    'budget',
    'time',
    'distance',
    'moment',
    'location',
    'weather',
  ].filter((field) => !req.body[field]);

  if (missingFields.length > 0) {
    return res.status(400).json({
      error: 'Missing required fields',
      missingFields,
    });
  }

  const planRequest = {
    mood,
    budget,
    time,
    distance,
    moment,
    location,
    weather,
    groupSize,
    language: normalizeLanguage(language),
  };

  if (!process.env.OPENAI_API_KEY) {
    return res.json(generateMockPlan(planRequest));
  }

  if (!canUseAi()) {
    return res.json(
      generateMockPlan(planRequest, { reason: 'daily_limit_reached' }),
    );
  }

  try {
    const plan = await generatePlanWithOpenAI(planRequest);
    registerAiUse();
    return res.json(plan);
  } catch (error) {
    // Do not log the API key or request body.
    console.warn(
      'OpenAI plan generation failed. Returning mock fallback.',
      {
        name: error.name,
        status: error.status,
        code: error.code,
      },
    );
  }

  return res.json(generateMockPlan(planRequest));
});

app.post('/generate-plan-from-chat', async (req, res) => {
  const { message, language } = req.body;

  if (typeof message !== 'string' || !message.trim()) {
    return res.status(400).json({
      error: 'Missing required field',
      missingFields: ['message'],
    });
  }

  const trimmedMessage = message.trim();
  const fallbackRequest = {
    ...inferPlanRequestFromChatMessage(trimmedMessage),
    language: normalizeLanguage(language),
  };

  if (!process.env.OPENAI_API_KEY) {
    return res.json(
      generateMockPlan(fallbackRequest, { reason: 'openai_key_missing' }),
    );
  }

  if (!canUseAi()) {
    return res.json(
      generateMockPlan(fallbackRequest, { reason: 'daily_limit_reached' }),
    );
  }

  try {
    const plan = await generatePlanFromChatWithOpenAI(
      trimmedMessage,
      fallbackRequest.language,
    );
    registerAiUse();
    return res.json(plan);
  } catch (error) {
    // Do not log the API key or the user's free-text message.
    console.warn(
      'OpenAI chat plan generation failed. Returning mock fallback.',
      {
        name: error.name,
        status: error.status,
        code: error.code,
      },
    );
  }

  return res.json(generateMockPlan(fallbackRequest));
});

function generateMockPlan(
  {
    mood,
    budget,
    time,
    distance,
    moment,
    location,
    weather,
    groupSize,
    language = 'es',
  },
  options = {},
) {
  const now = new Date();
  const outputLanguage = normalizeLanguage(language);
  const isEnglish = outputLanguage === 'en';
  const displayMood = localizePlanValue(mood, 'mood', outputLanguage);
  const displayBudget = localizePlanValue(budget, 'budget', outputLanguage);
  const displayTime = localizePlanValue(time, 'time', outputLanguage);
  const displayDistance = localizePlanValue(
    distance,
    'distance',
    outputLanguage,
  );
  const displayMoment = localizePlanValue(moment, 'moment', outputLanguage);
  const displayWeather = localizePlanValue(weather, 'weather', outputLanguage);

  return {
    id: `backend-mock-${now.getTime()}`,
    createdAt: now.toISOString(),
    title: isEnglish
      ? `${displayMood} plan in ${location}`
      : `Plan ${displayMood} en ${location}`,
    description: isEnglish
      ? `A Tonight-ready idea with a ${displayMood} mood, ${displayBudget} budget and ${displayWeather} weather.`
      : `Una propuesta lista para Tonight con mood ${displayMood}, presupuesto ${displayBudget} y clima ${displayWeather}.`,
    estimatedCost: displayBudget,
    estimatedDuration: displayTime,
    estimatedDistance: displayDistance,
    mood: displayMood,
    budget: displayBudget,
    time: displayTime,
    distance: displayDistance,
    moment: displayMoment,
    location,
    weather: displayWeather,
    groupSize: groupSize || null,
    source: 'mock',
    reason: options.reason || null,
    places: [
      {
        id: 'mock-place-1',
        name: isEnglish ? 'Tonight meeting point' : 'Punto de encuentro Tonight',
        category: isEnglish ? 'Start' : 'Inicio',
        location,
        moodTags: [displayMood],
        weatherTags: [displayWeather],
        priceLevel: displayBudget,
        description: isEnglish
          ? 'A comfortable place to start the plan without friction.'
          : 'Un lugar comodo para empezar el plan sin complicaciones.',
        latitude: null,
        longitude: null,
      },
      {
        id: 'mock-place-2',
        name: isEnglish ? 'Main stop' : 'Parada principal',
        category: isEnglish ? 'Experience' : 'Experiencia',
        location,
        moodTags: [displayMood],
        weatherTags: [displayWeather],
        priceLevel: displayBudget,
        description: isEnglish
          ? 'The central part of the plan, shaped around the moment.'
          : 'La parte central del plan, pensada para encajar con el momento.',
        latitude: null,
        longitude: null,
      },
    ],
    itinerarySteps: isEnglish
      ? [
          `Start in an easy-to-find area of ${location}.`,
          `Continue with a ${displayMood} experience for ${displayMoment}.`,
          `Wrap it up within ${displayTime}, keeping the distance ${displayDistance}.`,
        ]
      : [
          `Empieza en una zona facil de ${location}.`,
          `Sigue con una experiencia de mood ${displayMood} para ${displayMoment}.`,
          `Cierra el plan dentro de ${displayTime}, manteniendo distancia ${displayDistance}.`,
        ],
    whyItFits: isEnglish
      ? `It fits because it combines ${displayMood}, ${displayBudget} budget, ${displayWeather} weather and the ${displayMoment} moment.`
      : `Encaja porque combina ${displayMood}, presupuesto ${displayBudget}, clima ${displayWeather} y el momento ${displayMoment}.`,
    vibe: isEnglish
      ? `Tonight mock vibe: ${displayMood}, simple and ready to evolve with AI.`
      : `Tonight mock vibe: ${displayMood}, simple y listo para evolucionar con IA.`,
  };
}

function inferPlanRequestFromChatMessage(message) {
  const lowerMessage = normalizeForMatching(message);
  const budgetAmount = extractBudgetAmount(lowerMessage);

  return {
    mood: inferMood(lowerMessage),
    budget: inferBudget(lowerMessage, budgetAmount),
    time: inferTime(lowerMessage),
    distance: inferDistance(lowerMessage),
    moment: inferMoment(lowerMessage),
    location: inferLocation(message),
    weather: inferWeather(lowerMessage),
    groupSize: inferGroupSize(lowerMessage),
  };
}

function normalizeLanguage(language) {
  return language === 'en' ? 'en' : 'es';
}

function localizePlanValue(value, type, language) {
  if (language !== 'en') {
    return value;
  }

  const normalizedValue = normalizeForMatching(String(value || ''));
  const translations = {
    mood: {
      cita: 'Date',
      amigos: 'Friends',
      solo: 'Solo',
      chill: 'Chill',
      fiesta: 'Party',
      sorpresa: 'Surprise',
      viaje: 'Travel',
      grupo: 'Group',
    },
    budget: {
      gratis: 'Free',
    },
    time: {
      'toda la noche': 'All night',
    },
    distance: {
      cerca: 'Nearby',
      media: 'Medium',
      'me da igual': "Doesn't matter",
    },
    moment: {
      ahora: 'Now',
      manana: 'Morning',
      tarde: 'Afternoon',
      noche: 'Night',
      'fin de semana': 'Weekend',
    },
    weather: {
      automatico: 'Automatic',
      soleado: 'Sunny',
      lluvia: 'Rain',
      frio: 'Cold',
      calor: 'Hot',
      nublado: 'Cloudy',
    },
  };

  return translations[type]?.[normalizedValue] || value;
}

function normalizeForMatching(value) {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

function extractBudgetAmount(lowerMessage) {
  const match = lowerMessage.match(/(\d+)\s*(euros|euro|eur|€)/);
  return match ? Number.parseInt(match[1], 10) : null;
}

function inferMood(lowerMessage) {
  if (
    includesAny(lowerMessage, [
      'pareja',
      'mujer',
      'marido',
      'novia',
      'novio',
      'cita',
      'romant',
    ])
  ) {
    return 'Cita';
  }
  if (includesAny(lowerMessage, ['amigos', 'colegas', 'grupo'])) {
    return 'Amigos';
  }
  if (includesAny(lowerMessage, ['viaje', 'viajando', 'turismo', 'local'])) {
    return 'Viaje';
  }
  if (includesAny(lowerMessage, ['chill', 'tranquil', 'relax', 'suave'])) {
    return 'Chill';
  }
  if (includesAny(lowerMessage, ['fiesta', 'bailar', 'copas'])) {
    return 'Fiesta';
  }
  if (includesAny(lowerMessage, ['solo', 'sola'])) {
    return 'Solo';
  }

  return 'Sorpresa';
}

function inferBudget(lowerMessage, budgetAmount) {
  if (includesAny(lowerMessage, ['gratis', 'sin gastar', 'barato'])) {
    return budgetAmount !== null && budgetAmount > 10 ? '€' : 'Gratis';
  }
  if (budgetAmount === null) {
    return '€€';
  }
  if (budgetAmount <= 10) {
    return 'Gratis';
  }
  if (budgetAmount <= 25) {
    return '€';
  }
  if (budgetAmount <= 60) {
    return '€€';
  }
  return '€€€';
}

function inferTime(lowerMessage) {
  const hourMatch = lowerMessage.match(/(\d+)\s*h/);
  if (hourMatch) {
    const hours = Number.parseInt(hourMatch[1], 10);
    if (hours <= 1) {
      return '1h';
    }
    if (hours >= 3) {
      return '3h';
    }
  }
  if (includesAny(lowerMessage, ['toda la noche', 'noche entera'])) {
    return 'Toda la noche';
  }
  return '2h';
}

function inferDistance(lowerMessage) {
  if (
    includesAny(lowerMessage, [
      'esta zona',
      'por aqui',
      'cerca',
      'sin moverme',
      'barrio',
    ])
  ) {
    return 'Cerca';
  }
  if (includesAny(lowerMessage, ['me da igual', 'donde sea', 'moverme'])) {
    return 'Me da igual';
  }
  return 'Media';
}

function inferMoment(lowerMessage) {
  if (includesAny(lowerMessage, ['manana por la manana', 'mañana por la mañana'])) {
    return 'Mañana';
  }
  if (includesAny(lowerMessage, ['esta tarde', 'tarde'])) {
    return 'Tarde';
  }
  if (includesAny(lowerMessage, ['esta noche', 'noche'])) {
    return 'Noche';
  }
  if (includesAny(lowerMessage, ['fin de semana', 'sabado', 'domingo'])) {
    return 'Fin de semana';
  }
  return 'Ahora';
}

function inferLocation(message) {
  const knownCities = [
    'Madrid',
    'Barcelona',
    'Valencia',
    'Sevilla',
    'Bilbao',
    'Malaga',
    'Málaga',
    'Lisboa',
    'Paris',
    'París',
    'Roma',
  ];
  const lowerMessage = normalizeForMatching(message);
  const city = knownCities.find((candidate) => {
    return lowerMessage.includes(normalizeForMatching(candidate));
  });

  if (city) {
    return city;
  }

  const locationMatch = message.match(
    /\b(?:en|por|cerca de)\s+([A-ZÁÉÍÓÚÑ][\wÁÉÍÓÚÜÑáéíóúüñ-]+(?:\s+[A-ZÁÉÍÓÚÑ][\wÁÉÍÓÚÜÑáéíóúüñ-]+){0,2})/,
  );
  return locationMatch ? locationMatch[1].trim() : 'tu zona';
}

function inferWeather(lowerMessage) {
  if (includesAny(lowerMessage, ['lluvia', 'llueve', 'lloviendo'])) {
    return 'Lluvia';
  }
  if (includesAny(lowerMessage, ['calor', 'caluroso'])) {
    return 'Calor';
  }
  if (includesAny(lowerMessage, ['frio', 'frío'])) {
    return 'Frío';
  }
  if (includesAny(lowerMessage, ['sol', 'soleado'])) {
    return 'Soleado';
  }
  if (includesAny(lowerMessage, ['nublado'])) {
    return 'Nublado';
  }
  return 'Automático';
}

function inferGroupSize(lowerMessage) {
  const peopleMatch = lowerMessage.match(/(\d+)\s*(personas|amigos|somos)/);
  if (peopleMatch) {
    return peopleMatch[1];
  }
  if (includesAny(lowerMessage, ['pareja', 'mujer', 'marido', 'novia', 'novio'])) {
    return '2';
  }
  if (includesAny(lowerMessage, ['amigos', 'colegas'])) {
    return '3-5';
  }
  return null;
}

function includesAny(value, needles) {
  return needles.some((needle) => value.includes(normalizeForMatching(needle)));
}

app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Tonight backend running on port ${PORT}`);
});
