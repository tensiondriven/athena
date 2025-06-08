# Camera MQTT Connector

## Overview
MQTT bridge that connects to the Camera MCP Server for distributed PTZ control. Allows remote camera control via MQTT while keeping all camera logic centralized in the MCP server.

## Architecture
```
[MQTT Commands] → [MQTT Connector] → [Camera MCP Server] → [Hardware]
     Remote           Bridge            Local Control       USB/PTZ
```

## Quick Start

### 1. Install Dependencies
```bash
# Option 1: Use system package manager
brew install mosquitto-clients

# Option 2: Use virtual environment
python3 -m venv venv
source venv/bin/activate
pip install paho-mqtt

# Option 3: Use pipx (recommended)
brew install pipx
pipx install paho-mqtt
```

### 2. Start MQTT Broker (if needed)
```bash
# Using Docker
docker run -it -p 1883:1883 eclipse-mosquitto

# Or install locally
brew install mosquitto
brew services start mosquitto
```

### 3. Start Camera MQTT Connector
```bash
python3 /Users/j/Code/mcp/camera_mqtt_connector.py --camera-id camera1
```

### 4. Test the Connection
```bash
python3 /Users/j/Code/mcp/test_mqtt_connector.py --camera-id camera1
```

## MQTT Topics

### Commands (Publish to these)
- `camera/{camera_id}/ptz/command` - PTZ control
- `camera/{camera_id}/screenshot/command` - Screenshot capture
- `camera/{camera_id}/status/request` - Status queries

### Responses (Subscribe to these)
- `camera/{camera_id}/ptz/response` - PTZ results
- `camera/{camera_id}/screenshot/response` - Screenshot data
- `camera/{camera_id}/status/response` - Status info

## Example Commands

### PTZ Control
```json
{
  "command": "pan",
  "value": "middle",
  "id": 12345
}
```

### Screenshot
```json
{
  "camera_name": "PTZ Pro Camera",
  "id": 12346
}
```

### Status
```json
{
  "id": 12347
}
```

## Multi-Camera Setup
```bash
# Camera 1
python3 camera_mqtt_connector.py --camera-id camera1 &

# Camera 2 
python3 camera_mqtt_connector.py --camera-id camera2 &

# Camera 3
python3 camera_mqtt_connector.py --camera-id camera3 &
```

## Integration with athena
The MQTT connector can be used with athena-capture by:
1. **Direct Integration**: athena subscribes to MQTT topics
2. **REST Bridge**: Create REST API that publishes to MQTT
3. **MCP Direct**: athena uses Camera MCP Server directly

## Benefits
- ✅ **Scalable**: Easy multi-camera deployment
- ✅ **Remote**: Control cameras over network
- ✅ **Decoupled**: Camera logic separate from protocol
- ✅ **Reliable**: Uses proven MQTT for messaging
- ✅ **Flexible**: Multiple integration options

Date: 2025-06-07