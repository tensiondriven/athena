# Camera Control Architecture Notes

## MCP vs Connector Separation

### Current Implementation
- **MCP Server**: `/Users/j/Code/mcp/camera_mcp_server.py`
  - Complete PTZ control implementation
  - Hardware-specific fixes (cameracaptured process handling)
  - Input validation and safety controls
  - Direct integration with webcam-ptz executable and imagesnap
  - JSON-RPC interface for local control

### Proposed Connector Architecture
```
[Multiple Cameras] → [Camera MCP Servers] → [Protocol Connectors] → [athena/External Systems]
     USB/WiFi            Local Control         MQTT/REST/WS         Integration Layer
```

### Benefits of Separation

1. **Reusability**: Single MCP implementation works for all camera types
2. **Protocol Flexibility**: MQTT, REST, WebSocket connectors can all use same MCP
3. **Hardware Abstraction**: MCP handles device-specific quirks once
4. **Scalability**: Easy to add more cameras without duplicating PTZ logic
5. **Maintainability**: PTZ bugs fixed once in MCP, benefits all connectors

### Implementation Strategy

**Phase 1**: MCP Server (✅ Complete)
- PTZ control via webcam-ptz
- Camera discovery
- Screenshot capture
- Input validation

**Phase 2**: MQTT Connector (Next)
- Lightweight bridge between MQTT and Camera MCP
- Protocol translation only
- No PTZ logic duplication

**Phase 3**: athena Integration
- Use MCP directly OR via MQTT bridge
- Focus on AI vision pipeline, not camera control

### Tools Available via MCP
- `list_cameras`: Discover connected cameras
- `take_screenshot`: Capture with base64 encoding
- `ptz_control`: Pan/tilt/zoom commands with validation
- `get_camera_status`: System status and health checks

Date: 2025-06-07