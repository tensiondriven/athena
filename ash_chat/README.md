# AshChat - Event Inspector System

Real-time event monitoring and inspection for the Athena ecosystem, built with Phoenix LiveView and Ash Framework.

## Quick Start

**Using the service script (recommended):**
```bash
# From dev-tools directory
./ashchat-service.sh start    # Start the server
./ashchat-service.sh status   # Check if running
./ashchat-service.sh logs     # View server logs
./ashchat-service.sh stop     # Stop the server
```

**Manual start:**
```bash
cd /path/to/ash_chat
mix deps.get
mix phx.server
```

## Access Points

- **Event Inspector**: http://localhost:4000/events (main interface)
- **API Health**: http://localhost:4000/api/events/health
- **API Stats**: http://localhost:4000/api/events/stats
- **Event Ingestion**: `POST http://localhost:4000/webhook/test`

## Quick Test

```bash
# Send a test event
curl -X POST http://localhost:4000/webhook/test \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
    "type": "test.demo",
    "source": "docs",
    "description": "Test event from documentation"
  }'
```

Then visit the Event Inspector to see your event appear in real-time.

## Documentation

- **[Event Inspector Guide](docs/EVENT_INSPECTOR.md)** - Complete interface documentation
- **[API Reference](docs/API.md)** - HTTP endpoints for integration
- **[Architecture Notes](docs/ARCHITECTURE.md)** - Implementation details

## Features

- ⚡ **Real-time updates** via Phoenix LiveView and PubSub
- 🎯 **Master-detail interface** for rapid event scanning and deep inspection
- 🌈 **Intelligent color coding** based on event namespaces
- 🔍 **Auto-discovery** of new event types
- 📊 **Live statistics** and event type aggregation
- 🔗 **HTTP API** for easy integration

## System Requirements

- Elixir 1.15+
- Phoenix 1.7+
- Ash Framework 3.0+

The system uses ETS for in-memory event storage, making it perfect for development and monitoring without external database dependencies.
