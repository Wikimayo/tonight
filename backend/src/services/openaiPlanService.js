const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';

const planSchema = {
  type: 'object',
  additionalProperties: false,
  required: [
    'title',
    'description',
    'estimatedCost',
    'estimatedDuration',
    'estimatedDistance',
    'itinerarySteps',
    'whyItFits',
    'vibe',
    'mood',
    'budget',
    'time',
    'distance',
    'moment',
    'location',
    'weather',
    'groupSize',
    'source',
  ],
  properties: {
    title: { type: 'string' },
    description: { type: 'string' },
    estimatedCost: { type: 'string' },
    estimatedDuration: { type: 'string' },
    estimatedDistance: { type: 'string' },
    itinerarySteps: {
      type: 'array',
      minItems: 3,
      maxItems: 6,
      items: { type: 'string' },
    },
    whyItFits: { type: 'string' },
    vibe: { type: 'string' },
    mood: { type: 'string' },
    budget: { type: 'string' },
    time: { type: 'string' },
    distance: { type: 'string' },
    moment: { type: 'string' },
    location: { type: 'string' },
    weather: { type: 'string' },
    groupSize: {
      type: ['string', 'null'],
    },
    source: {
      type: 'string',
      enum: ['ai'],
    },
  },
};

async function generatePlanWithOpenAI(planRequest) {
  const normalizedRequest = {
    ...planRequest,
    language: normalizeLanguage(planRequest.language),
  };
  const OpenAI = loadOpenAI();
  const client = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
  });

  const response = await client.responses.create({
    model,
    input: [
      {
        role: 'system',
        content:
          'Eres un planificador local experto en experiencias urbanas, citas, planes con amigos, viajes y planes espontaneos. Tu trabajo es crear planes realistas, seguros, atractivos y faciles de compartir. Responde siempre en JSON estricto con las claves del schema exactamente como se solicitan.',
      },
      {
        role: 'user',
        content: buildPrompt(normalizedRequest),
      },
    ],
    text: {
      format: {
        type: 'json_schema',
        name: 'tonight_plan',
        strict: true,
        schema: planSchema,
      },
    },
  });

  const outputText = response.output_text;
  if (!outputText) {
    throw new Error('OpenAI response did not include output_text');
  }

  const aiPlan = JSON.parse(outputText);
  return normalizePlan(aiPlan, normalizedRequest);
}

async function generatePlanFromChatWithOpenAI(message, language = 'es') {
  const normalizedLanguage = normalizeLanguage(language);
  const OpenAI = loadOpenAI();
  const client = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
  });

  const response = await client.responses.create({
    model,
    input: [
      {
        role: 'system',
        content:
          'Eres un planificador local experto en experiencias urbanas. Interpretas mensajes libres del usuario y devuelves un plan compatible con Tonight en JSON estricto con las claves del schema exactamente como se solicitan.',
      },
      {
        role: 'user',
        content: buildChatPrompt(message, normalizedLanguage),
      },
    ],
    text: {
      format: {
        type: 'json_schema',
        name: 'tonight_chat_plan',
        strict: true,
        schema: planSchema,
      },
    },
  });

  const outputText = response.output_text;
  if (!outputText) {
    throw new Error('OpenAI response did not include output_text');
  }

  const aiPlan = JSON.parse(outputText);
  return normalizePlan(aiPlan, {
    ...inferPlanRequestFromAiPlan(aiPlan),
    language: normalizedLanguage,
  });
}

function loadOpenAI() {
  const openaiModule = require('openai');
  return openaiModule.default || openaiModule;
}

function buildPrompt({
  mood,
  budget,
  time,
  distance,
  moment,
  location,
  weather,
  groupSize,
  language = 'es',
}) {
  const outputLanguage = getOutputLanguageInstruction(language);

  return `
Genera un plan para Tonight con estos datos de contexto:
- mood: ${mood}
- budget: ${budget}
- time: ${time}
- distance: ${distance}
- moment: ${moment}
- location: ${location}
- weather: ${weather}
- groupSize: ${groupSize || 'null'}
- language: ${language}

Rol:
- Actua como un planificador local experto en experiencias urbanas, citas, planes con amigos, viajes y planes espontaneos.
- El plan debe sonar moderno, emocional, util y compartible, sin parecer generico.

Reglas de adaptacion:
- Adapta todo a mood, budget, time, distance, moment, location, weather y groupSize.
- Si weather indica lluvia, prioriza planes indoor o cubiertos.
- Si weather indica calor, prioriza horarios suaves, sombra, interiores, tarde o noche.
- Si weather indica frio, prioriza sitios acogedores, interiores y ritmos comodos.
- Si mood es viaje o travel, crea una ruta turistica/local con sensacion de descubrimiento.
- Si mood es grupo o groupSize existe, crea un plan facil de coordinar, con puntos simples de encuentro y poca friccion.
- Si mood es cita, cuida el ritmo, la conversacion y un cierre memorable pero natural.
- Si mood es amigos, prioriza energia social, flexibilidad y lugares donde sea facil hablar.
- Si mood es sorpresa o espontaneo, incluye un giro pequeno pero seguro y realista.

Reglas de realismo y seguridad:
- No inventes direcciones exactas, telefonos, horarios comerciales ni nombres de negocios concretos si no estas seguro.
- Puedes usar lugares genericos y verosimiles, por ejemplo "cafeteria especial en Malasana" o "bar tranquilo cerca del centro".
- Evita actividades peligrosas, ilegales, demasiado caras para el budget o imposibles para el time/distance.
- Manten estimatedCost, estimatedDuration y estimatedDistance coherentes con budget, time y distance.

Formato:
- Devuelve solo JSON valido y estricto, sin Markdown ni texto extra.
- El JSON debe cumplir exactamente el schema solicitado.
- Manten siempre los nombres de claves JSON en ingles exactamente como estan en el schema: title, description, estimatedCost, estimatedDuration, estimatedDistance, itinerarySteps, whyItFits, vibe, mood, budget, time, distance, moment, location, weather, groupSize y source.
- No traduzcas nombres de claves JSON ni anadas claves nuevas.
- Escribe todos los valores visibles de texto en ${outputLanguage}. Esto incluye title, description, estimatedCost, estimatedDuration, estimatedDistance, itinerarySteps, whyItFits, vibe y cualquier valor textual que generes para mood, budget, time, distance, moment, location o weather.
- Conserva nombres propios, ubicaciones y simbolos como EUR o euro cuando corresponda.
- Haz que itinerarySteps tenga entre 3 y 6 pasos concretos.
- Si groupSize no existe, devuelve groupSize como null.
- Devuelve source como "ai".
`.trim();
}

function buildChatPrompt(message, language = 'es') {
  const outputLanguage = getOutputLanguageInstruction(language);

  return `
El usuario ha escrito este mensaje libre para crear un plan:
"${message}"
- language: ${language}

Objetivo:
- Interpreta el mensaje y genera un plan Tonight completo.
- Extrae de forma aproximada mood, budget, time, distance, moment, location, weather y groupSize si aplica.

Guia de extraccion:
- Si habla de pareja, mujer, marido, cita o plan romantico, usa mood "Cita".
- Si habla de amigos, usa mood "Amigos".
- Si habla de viaje, turismo o algo local al visitar una ciudad, usa mood "Viaje".
- Si habla de tranquilidad, tarde suave o relax, usa mood "Chill".
- Si no esta claro, usa mood "Sorpresa".
- Si aparece una cantidad de dinero, traduce a budget: 0-10 "Gratis", 10-25 "€", 25-60 "€€", mas de 60 "€€€".
- Si no aparece presupuesto, usa "€€".
- Si dice "por esta zona", "cerca" o similar, usa distance "Cerca"; si no, "Media".
- Si menciona tarde, noche, manana, ahora o fin de semana, reflejalo en moment; si no, usa "Ahora".
- Si no hay clima claro, usa weather "Automático".
- Si no hay tiempo claro, usa time "2h".
- Si no hay ubicacion clara, usa location "tu zona".

Reglas importantes:
- No inventes direcciones exactas, telefonos, horarios comerciales ni nombres de negocios concretos si no estas seguro.
- Puedes usar lugares genericos y verosimiles: "cafeteria especial por el centro", "bar tranquilo de barrio", "mercado cubierto".
- Evita actividades peligrosas, ilegales o incoherentes con el presupuesto.
- Devuelve solo JSON valido y estricto, sin Markdown ni texto extra.
- Manten siempre los nombres de claves JSON en ingles exactamente como estan en el schema: title, description, estimatedCost, estimatedDuration, estimatedDistance, itinerarySteps, whyItFits, vibe, mood, budget, time, distance, moment, location, weather, groupSize y source.
- No traduzcas nombres de claves JSON ni anadas claves nuevas.
- Escribe todos los valores visibles de texto en ${outputLanguage}. Esto incluye title, description, estimatedCost, estimatedDuration, estimatedDistance, itinerarySteps, whyItFits, vibe y cualquier valor textual que generes para mood, budget, time, distance, moment, location o weather.
- Conserva nombres propios, ubicaciones y simbolos como EUR o euro cuando corresponda.
- itinerarySteps debe tener entre 3 y 6 pasos concretos.
- source debe ser "ai".
`.trim();
}

function normalizePlan(aiPlan, planRequest) {
  const now = new Date();
  const language = normalizeLanguage(planRequest.language);
  const title = normalizeText(
    aiPlan.title,
    language === 'en'
      ? `Surprise plan in ${planRequest.location}`
      : `Plan sorpresa en ${planRequest.location}`,
  );
  const itinerarySteps = normalizeItinerarySteps(
    aiPlan.itinerarySteps,
    planRequest,
    language,
  );

  return {
    id: `openai-${now.getTime()}`,
    createdAt: now.toISOString(),
    title,
    description: normalizeText(
      aiPlan.description,
      language === 'en'
        ? `A plan designed for ${planRequest.moment} in ${planRequest.location}, with a ${planRequest.mood} mood and ${planRequest.weather} weather.`
        : `Un plan pensado para ${planRequest.moment} en ${planRequest.location}, con mood ${planRequest.mood} y clima ${planRequest.weather}.`,
    ),
    estimatedCost: normalizeText(aiPlan.estimatedCost, planRequest.budget),
    estimatedDuration: normalizeText(aiPlan.estimatedDuration, planRequest.time),
    estimatedDistance: normalizeText(
      aiPlan.estimatedDistance,
      planRequest.distance,
    ),
    mood: aiPlan.mood || planRequest.mood,
    budget: aiPlan.budget || planRequest.budget,
    time: aiPlan.time || planRequest.time,
    distance: aiPlan.distance || planRequest.distance,
    moment: aiPlan.moment || planRequest.moment,
    location: aiPlan.location || planRequest.location,
    weather: aiPlan.weather || planRequest.weather,
    groupSize: aiPlan.groupSize || planRequest.groupSize || null,
    source: aiPlan.source === 'ai' ? aiPlan.source : 'ai',
    places: [],
    itinerarySteps,
    whyItFits: normalizeText(
      aiPlan.whyItFits,
      language === 'en'
        ? `It fits ${planRequest.mood}, ${planRequest.budget}, ${planRequest.time}, ${planRequest.distance} and ${planRequest.weather} weather.`
        : `Encaja con ${planRequest.mood}, ${planRequest.budget}, ${planRequest.time}, ${planRequest.distance} y el clima ${planRequest.weather}.`,
    ),
    vibe: normalizeText(
      aiPlan.vibe,
      language === 'en'
        ? `Urban, flexible and easy to share.`
        : `Urbano, flexible y facil de compartir.`,
    ),
  };
}

function inferPlanRequestFromAiPlan(aiPlan) {
  return {
    mood: normalizeText(aiPlan.mood, 'Sorpresa'),
    budget: normalizeText(aiPlan.budget, '€€'),
    time: normalizeText(aiPlan.time, '2h'),
    distance: normalizeText(aiPlan.distance, 'Media'),
    moment: normalizeText(aiPlan.moment, 'Ahora'),
    location: normalizeText(aiPlan.location, 'tu zona'),
    weather: normalizeText(aiPlan.weather, 'Automático'),
    groupSize: aiPlan.groupSize || null,
  };
}

function normalizeText(value, fallback) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function normalizeItinerarySteps(value, planRequest, language = 'es') {
  if (Array.isArray(value)) {
    const steps = value
      .filter((step) => typeof step === 'string' && step.trim())
      .map((step) => step.trim());

    if (steps.length > 0) {
      return steps;
    }
  }

  if (normalizeLanguage(language) === 'en') {
    return [
      `Start in an easy-to-find area of ${planRequest.location}.`,
      `Continue with a ${planRequest.mood} experience adapted to ${planRequest.weather}.`,
      `Wrap it up within ${planRequest.time}, keeping the distance ${planRequest.distance}.`,
    ];
  }

  return [
    `Empieza por una zona facil de encontrar en ${planRequest.location}.`,
    `Sigue con una experiencia ${planRequest.mood} adaptada a ${planRequest.weather}.`,
    `Cierra dentro de ${planRequest.time}, manteniendo distancia ${planRequest.distance}.`,
  ];
}

function getOutputLanguageInstruction(language) {
  return normalizeLanguage(language) === 'en'
    ? 'English'
    : 'espanol de Espana, natural y claro';
}

function normalizeLanguage(language) {
  return language === 'en' ? 'en' : 'es';
}

module.exports = {
  generatePlanWithOpenAI,
  generatePlanFromChatWithOpenAI,
};
