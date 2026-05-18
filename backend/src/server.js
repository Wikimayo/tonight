require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { generatePlanWithOpenAI } = require('./services/openaiPlanService');
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

function generateMockPlan(
  { mood, budget, time, distance, moment, location, weather, groupSize },
  options = {},
) {
  const now = new Date();
  return {
    id: `backend-mock-${now.getTime()}`,
    createdAt: now.toISOString(),
    title: `Plan ${mood} en ${location}`,
    description:
      `Una propuesta lista para Tonight con mood ${mood}, ` +
      `presupuesto ${budget} y clima ${weather}.`,
    estimatedCost: budget,
    estimatedDuration: time,
    estimatedDistance: distance,
    mood,
    budget,
    time,
    distance,
    moment,
    location,
    weather,
    groupSize: groupSize || null,
    source: 'mock',
    reason: options.reason || null,
    places: [
      {
        id: 'mock-place-1',
        name: 'Punto de encuentro Tonight',
        category: 'Inicio',
        location,
        moodTags: [mood],
        weatherTags: [weather],
        priceLevel: budget,
        description: 'Un lugar comodo para empezar el plan sin complicaciones.',
        latitude: null,
        longitude: null,
      },
      {
        id: 'mock-place-2',
        name: 'Parada principal',
        category: 'Experiencia',
        location,
        moodTags: [mood],
        weatherTags: [weather],
        priceLevel: budget,
        description: 'La parte central del plan, pensada para encajar con el momento.',
        latitude: null,
        longitude: null,
      },
    ],
    itinerarySteps: [
      `Empieza en una zona facil de ${location}.`,
      `Sigue con una experiencia de mood ${mood} para ${moment}.`,
      `Cierra el plan dentro de ${time}, manteniendo distancia ${distance}.`,
    ],
    whyItFits:
      `Encaja porque combina ${mood}, presupuesto ${budget}, ` +
      `clima ${weather} y el momento ${moment}.`,
    vibe: `Tonight mock vibe: ${mood}, simple y listo para evolucionar con IA.`,
  };
}

app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Tonight backend running on port ${PORT}`);
});
