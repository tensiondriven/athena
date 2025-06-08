# Webcam PTZ Control (Native Implementation)

**Simple PTZ camera control for Athena system**

## Overview
Native implementation of PTZ (Pan-Tilt-Zoom) camera control, copied from external repository for Athena integration. No longer a git submodule - this is now native Athena code.

## Files
- `webcam-ptz.c` - Source code (5.5KB)
- `webcam-ptz` - Compiled executable (34KB) 
- `run-as-root` - Helper script for camera access permissions
- `CLAUDE.md` - Integration session history
- `mcp_config.json` - MCP server configuration
- `PTZ_CAMERA_INTERFACE_GUIDE.md` - Detailed interface documentation

## Usage
```bash
./webcam-ptz pan|tilt|zoom min|max|middle|<steps>
```

## Integration
- **PTZ REST API**: Called by `../ptz-rest-api/`
- **MCP Server**: Controlled via `../../athena-mcp/ptz_mcp_server.py`
- **Hardware**: Tested with Logitech PTZ Pro cameras

## Dependencies
- libuvc and libusb (for compilation)
- Camera permissions (see `run-as-root` script)

## Notes
- Originally external git submodule, now native for simplicity
- Ancient but stable code - no upstream updates expected
- Executable included for immediate use without compilation

---
*Converted to native implementation: 2025-06-08*