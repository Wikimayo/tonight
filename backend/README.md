# Tonight Backend

Backend minimo de Node.js + Express para generar planes de Tonight.

Si `OPENAI_API_KEY` esta configurada, el endpoint `/generate-plan` usa OpenAI desde el backend. Si no hay clave o la llamada falla, devuelve un plan mock compatible con `PlanModel` de Flutter.

## Arrancar

```bash
npm install
npm run dev
```

El servidor usa `PORT=3000` por defecto.

Para activar OpenAI, crea un archivo `.env` basado en `.env.example` y configura:

```bash
OPENAI_API_KEY=your_api_key_here
```

## Endpoints

### GET /health

Devuelve:

```json
{ "status": "ok" }
```

### POST /generate-plan

Body esperado:

```json
{
  "mood": "Cita",
  "budget": "Medio",
  "time": "2 horas",
  "distance": "Cerca",
  "moment": "Esta noche",
  "location": "Madrid",
  "weather": "Soleado",
  "groupSize": "2"
}
```

`groupSize` es opcional.

## Deploy en Railway

Configura la variable de entorno `OPENAI_API_KEY` en Railway. No subas un archivo `.env` real al repositorio.

Railway asigna `PORT` automaticamente, y el servidor ya lo lee desde `process.env.PORT`. En local, si Railway no define `PORT`, el backend usa `3000` por defecto.
