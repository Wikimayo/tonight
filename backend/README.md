# Tonight Backend

Backend minimo de Node.js + Express para generar planes de Tonight.

Si `OPENAI_API_KEY` esta configurada, los endpoints `/generate-plan` y `/generate-plan-from-chat` usan OpenAI desde el backend. Si no hay clave o la llamada falla, devuelven un plan mock compatible con `PlanModel` de Flutter.

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
  "groupSize": "2",
  "language": "es"
}
```

`groupSize` y `language` son opcionales. Si `language` es `"en"`, el plan se genera en ingles. Si es `"es"` o falta, se genera en espanol. Las claves JSON de respuesta no cambian.

### POST /generate-plan-from-chat

Body esperado:

```json
{
  "message": "Estoy en Madrid, tengo 20 euros, voy con mi mujer y quiero un plan por esta zona",
  "language": "es"
}
```

`language` es opcional y sigue la misma regla: `"en"` para ingles, `"es"` o ausente para espanol. El backend interpreta el texto libre, extrae mood, presupuesto, momento, ubicacion y compania de forma aproximada, y devuelve un `PlanModel` compatible. No expone la API key y no inventa direcciones exactas.

## Deploy en Railway

Configura la variable de entorno `OPENAI_API_KEY` en Railway. No subas un archivo `.env` real al repositorio.

Railway asigna `PORT` automaticamente, y el servidor ya lo lee desde `process.env.PORT`. En local, si Railway no define `PORT`, el backend usa `3000` por defecto.
