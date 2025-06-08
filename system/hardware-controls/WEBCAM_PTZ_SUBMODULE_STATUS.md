# Webcam-PTZ Submodule Status

**For the next person working on this project:**

## Current State
The `system/hardware-controls/webcam-ptz` directory is a git submodule that shows as "dirty" in git status. This contains a functional PTZ camera control tool written in C.

## What It Does
- Command-line tool to pan, tilt, and zoom UVC-compatible USB webcams
- Tested with Logitech Brio and Webcam Pro 9000
- Integrates with Athena's hardware control layer for camera automation

## Integration Context
This tool is part of Athena's distributed camera system:
- **Purpose**: Low-level hardware control for PTZ cameras
- **Architecture**: Called by PTZ REST API (`../ptz-rest-api/`) 
- **MCP Integration**: Controlled via `system/athena-mcp/ptz_mcp_server.py`
- **Dependencies**: libuvc and libusb (see README.md for build instructions)

## Known Working State
- ✅ Camera responds to `./webcam-ptz pan middle` commands
- ⚠️ May get blocked by `cameracaptured` process after ~30 seconds
- 🔧 **Fix**: `sudo pkill cameracaptured` to release camera control

## Git Submodule Notes
- Original repo: External PTZ camera tool
- Modified for Athena integration
- Contains CLAUDE.md with detailed session context from PTZ integration work
- Shows as "dirty" due to local modifications for Athena compatibility

## Next Steps for Developers
1. Test camera connectivity: `./webcam-ptz pan middle`
2. Review CLAUDE.md for detailed integration history
3. Check PTZ REST API integration status
4. Verify MCP server communication pathway

---
*Created: 2025-06-08 - Git consolidation documentation*