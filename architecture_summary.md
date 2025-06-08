# Clean Camera Architecture Implementation

## ✅ **Architecture Achieved**

```
[PTZ MCP Server] + [Screenshot MCP Server] → [Collector Daemons]
   PTZ Operations            Screenshot Ops       Hardware Specific
   - list_ptz_cameras        - list_screenshot_cameras   - Logitech PTZ Collector (PTZ + screenshot)
   - ptz_control             - take_screenshot           - USB Webcam Collector (screenshot only)
   - pan/tilt/zoom only      - All camera types          - ONVIF Collector (future)
```

## **Component Separation**

### 🎯 **PTZ MCP Server** (`/mcp/ptz_mcp_server.py`)
- **Purpose**: PTZ-only camera control interface
- **Responsibilities**: 
  - PTZ command validation (pan/tilt/zoom only)
  - PTZ-capable camera discovery
  - PTZ command routing to capable daemons
- **Filters**: Only works with PTZ-capable cameras

### 📷 **Screenshot MCP Server** (`/mcp/screenshot_mcp_server.py`)
- **Purpose**: Screenshot-only camera interface
- **Responsibilities**:
  - Screenshot command handling
  - All camera discovery (PTZ and non-PTZ)
  - Screenshot routing to all camera types
- **Universal**: Works with any camera that supports screenshots

### 🔧 **Collector Daemons** (`/logi-ptz/daemons/`)
- **Purpose**: Hardware-specific camera implementations
- **Current Implementations**:
  - `logitech_ptz_daemon.py` - PTZ + screenshot (Logitech PTZ cameras)
  - `usb_webcam_daemon.py` - Screenshot only (basic USB webcams)
- **Future**: `onvif_daemon.py` (PTZ + screenshot), `ip_camera_daemon.py` (screenshot), etc.
- **Capabilities Declaration**: Each daemon declares what it supports in config.json
- **Clear Separation**: PTZ daemons vs Screenshot-only daemons

### 📋 **Configuration** (`/logi-ptz/daemons/config.json`)
- **Purpose**: Daemon registry and capabilities
- **Contains**: Daemon paths, supported commands, metadata
- **Extensible**: Easy to add new collector daemons

## **Benefits Achieved**

✅ **Clean Separation**: MCP handles protocol, daemons handle hardware  
✅ **Scalable**: Add new camera types by adding collector daemons  
✅ **Maintainable**: Hardware bugs fixed once in relevant daemon  
✅ **Reusable**: Generic MCP works with any camera hardware  
✅ **Testable**: Each component can be tested independently  

## **Integration Ready**

- **athena-capture**: Can use generic MCP interface
- **MQTT Bridge**: Can translate between MQTT and generic MCP
- **REST API**: Can expose generic camera controls via HTTP
- **Multi-camera**: Each daemon handles multiple devices of its type

## **Command Interface**

### MCP Commands (Capability Specific)

**PTZ MCP Server:**
```json
{"method": "list_ptz_cameras"}
{"method": "ptz_control", "params": {"camera_id": "logitech-123", "command": "pan", "value": "middle"}}
```

**Screenshot MCP Server:**
```json
{"method": "list_screenshot_cameras"} 
{"method": "take_screenshot", "params": {"camera_id": "logitech-123"}}
{"method": "take_screenshot", "params": {"camera_id": "usb-webcam-0"}}
```

### Daemon Commands (Hardware Specific)  
```bash
python3 logitech_ptz_daemon.py list
python3 logitech_ptz_daemon.py pan --camera-id logitech-123 --value middle
python3 logitech_ptz_daemon.py screenshot --camera-id logitech-123
```

Date: 2025-06-07