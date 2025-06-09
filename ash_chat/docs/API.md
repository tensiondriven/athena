# Event API Reference

## Create Event

Both endpoints accept the same payload format and use the same controller action:

**Standard API endpoint:**
```bash
curl -X POST http://localhost:4000/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "id": "optional-id",
    "timestamp": "2025-06-09T03:14:34.000Z",
    "type": "user.login_success",
    "source": "web_app", 
    "confidence": 0.95,
    "description": "User logged in successfully",
    "metadata": {
      "user_id": "12345",
      "session_id": "sess_abc123"
    }
  }'
```

**Legacy webhook endpoint (for existing collectors):**
```bash
curl -X POST http://localhost:4000/webhook/test \
  -H "Content-Type: application/json" \
  -d '{ ... same payload ... }'
```

**Response**: `{"status": "success", "event_id": "uuid", "message": "Event created successfully"}`

## Field Mapping

The controller maps collector format to Event resource:

```elixir
# Collector sends -> Event resource expects
"type" -> "event_type"
"source" -> "source_id"
```

## Required Fields

- `timestamp` (ISO8601 format)
- `type` (event_type)
- `source` (source_id)

## Optional Fields

- `id` (UUID generated if not provided)
- `confidence` (0.0-1.0)
- `description` (human-readable summary)
- `metadata` (any JSON object)

## Event Stats

```bash
curl http://localhost:4000/api/events/stats
```

## Health Check

```bash
curl http://localhost:4000/api/events/health
```