# Athena Capture - Project Context

## Overview
Athena Capture is a distributed event monitoring and capture system built in Elixir. It consists of agent processes (sources/sinks) that run on multiple machines and communicate with a central athena collector server.

## Architecture

### Distributed Agent Model
- **Agent Processes**: Lightweight Elixir applications that run on individual machines
- **Sources**: Capture events (screenshots, PTZ camera, conversations, file changes)  
- **Sinks**: Process and forward events to collectors
- **Central Collector**: Athena server that aggregates events from all agents

### Communication Flow
```
[Machine 1] → Agent Process → Register with Collector → Bidirectional Comms
[Machine 2] → Agent Process → Register with Collector → Bidirectional Comms  
[Machine N] → Agent Process → Register with Collector → Bidirectional Comms
                                      ↓
                              Central Athena Server
                                      ↓
                              Knowledge Graph Pipeline
```

## Current Capabilities

### Event Sources
- **Screenshot Capture**: Full screen, active window, interactive selection
- **PTZ Camera**: Positioned camera stills with movement control
- **Conversation Monitor**: Claude session logs and interactions
- **Event Store**: Durable SQLite storage for all captured events

### Boot-time Agent Requirements
- Auto-start on machine boot
- Self-registration with collector server
- Heartbeat/health monitoring
- Graceful reconnection on network issues
- Local event buffering during disconnection

## Project Structure
```
athena_capture/
├── lib/athena_capture/
│   ├── application.ex           # OTP application supervisor
│   ├── event_store.ex          # SQLite event persistence
│   ├── screenshot_capture.ex   # Screen capture functionality
│   ├── ptz_camera_capture.ex   # PTZ camera control
│   ├── conversation_monitor.ex # Claude session monitoring
│   └── event_dashboard.ex      # Activity monitoring dashboard
```

## Development Commands

### Testing
```bash
cd athena_capture && mix test
```

### Running Locally
```bash
cd athena_capture && mix run --no-halt
```

### Building Release
```bash
cd athena_capture && mix release
```

## PTZ Connector Agent - MQTT Architecture

### Agent Identity & Discovery
- **Agent ID**: `ptz-connector-{hostname}-{mac_suffix}` (e.g., `ptz-connector-office-a1b2`)
- **Discovery**: MQTT topic `athena/agents/discover` for agent announcements
- **Registry**: MQTT retained messages on `athena/agents/registry/{agent_id}`

### MQTT Topic Structure
```
athena/
├── agents/
│   ├── discover                    # Agent discovery announcements
│   ├── registry/{agent_id}         # Agent capabilities (retained)
│   ├── heartbeat/{agent_id}        # Periodic health checks
│   └── commands/{agent_id}         # Commands to specific agent
├── events/
│   ├── ptz/{agent_id}/capture      # PTZ capture events
│   ├── ptz/{agent_id}/position     # Position change events
│   └── ptz/{agent_id}/status       # Camera status updates
└── responses/
    └── {agent_id}/{command_id}     # Command responses
```

### Agent Registration Flow
1. **Boot**: PTZ Connector starts and connects to MQTT
2. **Announce**: Publishes to `athena/agents/discover` with capabilities
3. **Register**: Sets retained message on `athena/agents/registry/{agent_id}`
4. **Heartbeat**: Periodic ping on `athena/agents/heartbeat/{agent_id}`

### Command Protocol
```json
// Command: athena/commands/ptz-connector-office-a1b2
{
  "command_id": "uuid-1234",
  "type": "capture_with_position",
  "params": {
    "pan": "left",
    "tilt": "up", 
    "zoom": 2
  }
}

// Response: athena/responses/ptz-connector-office-a1b2/uuid-1234
{
  "command_id": "uuid-1234",
  "status": "success",
  "data": {
    "image_path": "/tmp/capture_20250607_123456.jpg",
    "position": {"pan": -45, "tilt": 15, "zoom": 2},
    "timestamp": "2025-06-07T12:34:56Z"
  }
}
```

### Agent Capabilities Registration
```json
{
  "agent_id": "ptz-connector-office-a1b2",
  "type": "ptz_camera",
  "hostname": "office-pi",
  "capabilities": [
    "capture_still",
    "position_control", 
    "get_position",
    "capture_with_position"
  ],
  "camera_model": "Logitech PTZ Pro 2",
  "last_seen": "2025-06-07T12:34:56Z",
  "version": "1.0.0"
}
```

## Implementation Plan

### 1. PTZ Connector Module
- Extend existing `AthenaCapture.PTZCameraCapture`
- Add MQTT client integration
- Implement agent registration and heartbeat

### 2. MQTT Integration
- Use `tortoise` or `emqtt` Elixir MQTT client
- Connection management and auto-reconnect
- Message handling for commands and responses

### 3. Boot Service
- Create standalone PTZ Connector OTP release
- Systemd service file for auto-start
- Configuration file for MQTT broker details

### 4. Collector Interface
- Simple web dashboard showing registered agents
- Command dispatch through MQTT
- Event aggregation from agent topics

## Related Files
- `athena_capture/lib/athena_capture.ex` - Main API module
- `athena_capture/lib/athena_capture/application.ex` - OTP supervisor tree
- `README.md` - Project documentation and setup instructions