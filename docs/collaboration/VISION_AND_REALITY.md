# Athena System: Product Vision and Current Reality

## The Vision
A distributed AI system where:

### Physical Components
- **Raspberry Pis** with cameras (wireless deployment)
- **IP cameras** with PTZ controls
- **Microphones** (pure audio input)
- **Speakers** (pure audio output)
- **Displays** (screens, dashboards) - tracked in database

### Event Sources
- Motion events from cameras/sensors
- Sound events from microphones
- Home Assistant events
- MQTT messages
- File system changes (including chat logs like this conversation)
- Log file changes

### AI Capabilities
- AI can call MCP to display HTML/messages on specific displays
- AI processes all these events and makes decisions
- AI controls PTZ cameras, speakers, displays

### Backend/Frontend
- **Backend**: Elixir/Ash framework
- **Frontend**: TBD (web dashboards, touch screens)
- **Database**: Display registry, event storage

## Current Reality (What We Have)

### Working Components
```
sam-pipeline/          # Computer vision (SAM, CLIP)
athena-ingest/         # Event collection, MQTT
athena-capture/        # Screenshots, PTZ control
ash-ai/               # Chat interface, Claude integration
bigplan/              # System orchestration, dashboards
mcp/                  # MCP servers for AI tools
```

### Git Repository Issues
- 9 different git repos scattered around
- 5 repos need attention (untracked files, modifications)
- Confusing nested structure
- Hard to understand what belongs where

## The Problem
The filesystem organization doesn't match the vision - it's confusing for both humans and AI to navigate and understand the system architecture.

## What Needs Organizing
1. **Clear separation** between components
2. **Obvious naming** that matches function
3. **Simple git structure** - fewer repos, clearer boundaries
4. **Easy navigation** - both human and AI should instantly understand what each part does