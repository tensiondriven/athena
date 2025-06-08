# AI Collaboration Framework

**📍 This is the master copy - also copied to `/Users/j/Code/AI_README_FIRST.md` for easy AI discovery**

## Quick Context for AI Systems

This directory contains a comprehensive framework for AI-assisted development, including:

### 🎯 **MCP Servers** (`/mcp/`)
- **Camera MCP Server**: Complete PTZ camera control with MQTT bridge
- **BetterBash MCP**: Enhanced shell execution with safety controls  
- **Cheatsheet MCP**: AI collaboration context injection

### 🎥 **PTZ Camera Control** (`/logi-ptz/`)
- Hardware integration with Logitech PTZ cameras
- MCP server architecture for distributed control
- MQTT connector for remote camera management
- REST API and web interface

### 📋 **AI Collaboration Protocols**
- **AI_AGREEMENT.md**: Session agreements and collaboration guidelines
- **Integration Pause Protocol**: "Ask User A Question" pattern
- **BetterBash MCP Usage**: Mandatory enhanced shell execution

### 🔧 **Current Session Context**
- Working on camera PTZ integration with MQTT bridge architecture
- MCP servers provide hardware control, connectors handle protocols
- Ready for athena-capture integration and AI vision pipelines

### 🚀 **Quick Start**
```bash
# Camera control via MCP
python3 ai-collab/mcp/camera_mcp_server.py

# MQTT bridge for distributed control  
python3 ai-collab/mcp/camera_mqtt_connector.py --camera-id camera1

# Enhanced shell with safety controls
claude mcp add betterbash python3 ai-collab/mcp/betterbash_server.py
```

**Architecture Philosophy**: Separate concerns - MCP servers handle device logic, connectors handle protocols, AI systems integrate via clean interfaces.

Date: 2025-06-07