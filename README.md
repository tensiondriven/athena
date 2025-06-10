# Athena: AI Collaboration Research Platform

**A living laboratory for AI-human collaboration with complete conversation archaeology**

## What This Is

Athena started as a home automation project but has evolved into something more significant: a research platform demonstrating **conversation archaeology** - the complete preservation of AI development consciousness alongside code.

### Key Innovation: Development Archaeology

Every architectural decision, debugging step, and design choice is captured with complete context and rationale. When you encounter unfamiliar code, you can:

1. **Check git blame** to find the commit
2. **Look for conversation UUID** in that commit's chat-history  
3. **Extract full context** from the JSONL conversation
4. **Understand the complete thought process** behind the implementation

**Result**: Development transforms from "archaeological guesswork" to "documented decision archaeology."

## Quick Start

### Running the System
```bash
# Start the chat interface (main application)
cd ash_chat && mix phx.server

# Access the interface
open http://localhost:4000
```

### Demo the Multi-User Chat
```bash
# Start an IEx session
cd ash_chat && iex -S mix

# Create demo data with users, rooms, and AI agents
AshChat.Setup.reset_demo_data()
```

## Architecture Overview

- **`ash_chat/`** - Production Phoenix LiveView chat system with AI agents
- **`chat-history/`** - 90 conversations (50MB) of complete development archaeology
- **`docs/journal/`** - 30+ real-time development discoveries
- **`domains/`** - Event processing, hardware integration (migration in progress)
- **`system/`** - Hardware controls, computer vision, MCP servers

## Core Components

### Multi-User AI Chat (`ash_chat/`)
- **Agent Cards** - Character-driven AI personalities  
- **Room Hierarchy** - Parent-child room relationships
- **Real-time Events** - LiveView interfaces with auto-discovery
- **Multi-model Support** - Switch AI providers per conversation

### Conversation Archaeology (`chat-history/`)
- **90 conversation files** with structured JSONL metadata
- **Complete development timeline** from project inception
- **Tool usage, decisions, and context** fully preserved
- **Git correlation** linking conversations to specific commits

### Hardware Integration (`system/`)
- **PTZ camera controls** via MCP servers
- **Computer vision pipeline** (SAM, CLIP) 
- **Event collection** from multiple sources
- **MQTT/sensor integration**

## Research Value

This project demonstrates:

- **Complete development consciousness preservation** 
- **Proven AI-human collaboration patterns**
- **Automatic documentation** of architectural decisions
- **Knowledge transfer** that survives beyond individual sessions

## Documentation

- **[AI Collaboration Protocol](AI_COLLABORATION_PROTOCOL.md)** - Core working agreements
- **[Quick Reference](docs/AI_QUICK_REFERENCE.md)** - Key patterns and commands
- **[Development Journal](docs/journal/)** - Real-time discoveries and insights
- **[Physics of Work](docs/physics-of-work/)** - Collaboration methodology

## Impact

Athena has accidentally become one of the most documented software development processes in history - not through manual effort, but through **automatic consciousness preservation**. This could fundamentally change how we approach AI-assisted development.

---

*The archaeology was the side benefit that became the main discovery.*