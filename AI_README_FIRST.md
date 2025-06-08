# Athena: AI-Powered Distributed Home Automation System

**📍 AI Systems: Start here for project context**

## Quick Context

**Athena** is a distributed AI home automation system combining:
- **Physics of Work** - AI-human collaboration methodology (docs/physics-of-work/)
- **Distributed hardware** - Raspberry Pi cameras, PTZ controls, IoT sensors
- **AI agents** - Runtime MCP servers for autonomous operation
- **Event processing** - Real-time ingestion from cameras, MQTT, file changes

## Project Structure

```
athena/
├── docs/                    # Documentation & Methodology
│   ├── physics-of-work/     # AI-human collaboration framework
│   ├── journal/            # Project development journal
│   └── architecture/       # System architecture docs
├── system/                 # All Athena components
│   ├── athena-mcp/         # Runtime MCP servers (AI uses these)
│   ├── hardware-controls/   # Camera daemons, PTZ REST API
│   ├── sam-pipeline/       # Computer vision (SAM, CLIP)
│   ├── ash-ai/            # AI chat interface
│   ├── bigplan/           # System orchestration
│   └── [8 other components]
└── dev-tools/             # Development MCP servers (you use these)
```

## Key Concepts

### Physics of Work Methodology
- **Two roles**: Development Team (Claude AI) + Product Team (Jonathan)
- AI acts as: developer, educator, researcher, mentor
- **Meta-goal**: Make it better for the next person (which is us)
- This project IS the research platform for the methodology

### System Vision
- **AI controls displays** throughout physical space via MCP calls
- **Event sources**: motion, sound, Home Assistant, MQTT, file changes
- **Multi-device deployment**: Raspberry Pis, IP cameras, speakers, displays
- **Autonomous AI decisions** about what to show where and when

## Current Session Context

**Git Status**: Just consolidated from 6 separate repos into unified structure
**Focus**: System organization and Physics of Work documentation
**Next**: System deployment and AI agent integration

## For AI Systems

### Development Guidelines
- Use Physics of Work principles (docs/physics-of-work/ROLES.md)
- Excellent git hygiene - commit frequently with good messages
- Focus on making the process better for next iteration
- Research and document collaboration patterns

### Key Files
- **docs/physics-of-work/ROLES.md** - Team roles and responsibilities  
- **docs/physics-of-work/VISION_AND_REALITY.md** - Product vision
- **docs/journal/GIT_HISTORY_ARCHIVE.md** - Pre-consolidation git history
- **system/athena-mcp/** - Runtime MCP servers for AI control

### MCP Servers Available
- **Camera control** (system/athena-mcp/camera_mcp_server.py)
- **PTZ cameras** (system/athena-mcp/ptz_mcp_server.py)  
- **Screenshots** (system/athena-mcp/screenshot_mcp_server.py)
- **Dev tools** (dev-tools/ directory)

**Architecture Philosophy**: AI makes autonomous decisions about physical space interactions while maintaining human oversight through Physics of Work collaboration patterns.

---
*Updated: 2025-06-08 - Post git consolidation*