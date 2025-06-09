# Event Inspector Documentation

## Quick Reference

- **[EVENT_INSPECTOR.md](./EVENT_INSPECTOR.md)** - Main interface guide and features
- **[API.md](./API.md)** - HTTP endpoints for event ingestion  
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Implementation notes and gotchas

## Service Management

**Start the system:**
```bash
# From dev-tools directory
./ashchat-service.sh start
```

**Monitor the system:**
```bash
./ashchat-service.sh status   # Check if running
./ashchat-service.sh logs     # Tail server logs
```

**Stop the system:**
```bash
./ashchat-service.sh stop
```

## Live Interface

Event Inspector: `http://localhost:4000/events`

## Quick Test

```bash
curl -X POST http://localhost:4000/webhook/test \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
    "type": "test.demo",
    "source": "docs",
    "description": "Test event from documentation"
  }'
```

The event will appear instantly in the Event Inspector (no refresh needed - it's real-time!).