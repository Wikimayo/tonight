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
          'Eres un planificador local experto en experiencias urbanas, citas, planes con amigos, viajes y planes espontaneos. Tu trabajo es crear planes realistas, seguros, atractivos y faciles de compartir. Responde siempre en JSON estricto.',
      },
      {
        role: 'user',
        content: buildPrompt(planRequest),
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
  return normalizePlan(aiPlan, planRequest);
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
}) {
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
- Usa textos naturales en espanol.
- Haz que itinerarySteps tenga entre 3 y 6 pasos concretos.
- Si groupSize no existe, devuelve groupSize como null.
- Devuelve source como "ai".
`.trim();
}

function normalizePlan(aiPlan, planRequest) {
  const now = new Date();
  const title = normalizeText(
    aiPlan.title,
    `Plan sorpresa en ${planRequest.location}`,
  );
  const itinerarySteps = normalizeItinerarySteps(
    aiPlan.itinerarySteps,
    planRequest,
  );

  return {
    id: `openai-${now.getTime()}`,
    createdAt: now.toISOString(),
    title,
    description: normalizeText(
      aiPlan.description,
      `Un plan pensado para ${planRequest.moment} en ${planRequest.location}, con mood ${planRequest.mood} y clima ${planRequest.weather}.`,
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
      `Encaja con ${planRequest.mood}, ${planRequest.budget}, ${planRequest.time}, ${planRequest.distance} y el clima ${planRequest.weather}.`,
    ),
    vibe: normalizeText(
      aiPlan.vibe,
      `Urbano, flexible y facil de compartir.`,
    ),
  };
}

function normalizeText(value, fallback) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function normalizeItinerarySteps(value, planRequest) {
  if (Array.isArray(value)) {
    const steps = value
      .filter((step) => typeof step === 'string' && step.trim())
      .map((step) => step.trim());

    if (steps.length > 0) {
      return steps;
    }
  }

  return [
    `Empieza por una zona facil de encontrar en ${planRequest.location}.`,
    `Sigue con una experiencia ${planRequest.mood} adaptada a ${planRequest.weather}.`,
    `Cierra dentro de ${planRequest.time}, manteniendo distancia ${planRequest.distance}.`,
  ];
}

module.exports = {
  generatePlanWithOpenAI,
};
