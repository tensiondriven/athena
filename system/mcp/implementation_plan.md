# Camera Control Implementation Plan

## Phase 1: MQTT Connector (Immediate)
**Goal**: Create lightweight MQTT bridge to Camera MCP Server

### Components to Build
1. **MQTT Connector** (`/Users/j/Code/mcp/camera_mqtt_connector.py`)
   - Subscribe to MQTT PTZ commands
   - Forward to Camera MCP Server via JSON-RPC
   - Publish responses back to MQTT
   - Handle connection management

2. **Configuration**
   - MQTT broker settings
   - Camera MCP Server connection
   - Topic structure for commands/responses

### MQTT Topic Structure
```
camera/ptz/command       # Incoming PTZ commands
camera/ptz/response      # PTZ command results
camera/screenshot/command # Screenshot requests
camera/screenshot/response # Screenshot data (base64)
camera/status/request    # Status queries
camera/status/response   # Camera status info
```

## Phase 2: Testing & Validation
1. **Local Testing**
   - Start Camera MCP Server
   - Start MQTT Connector
   - Send test commands via MQTT
   - Verify PTZ execution and responses

2. **Multi-Camera Testing**
   - Multiple camera instances
   - Topic routing by camera ID
   - Concurrent command handling

## Phase 3: athena Integration
1. **Direct MCP Integration** OR **MQTT Bridge**
2. **AI Vision Pipeline** using screenshot capability
3. **Automated PTZ positioning** based on vision analysis

## Implementation Priority
1. ✅ Camera MCP Server (Complete)
2. 🔄 MQTT Connector (Next)
3. ⏳ Multi-camera scaling
4. ⏳ athena integration

Date: 2025-06-07