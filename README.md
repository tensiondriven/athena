# Athena: Distributed AI System + Collaboration Research

**Research through practice: Building a real distributed AI system while developing universal AI-human collaboration methodology**

## What This Is

Athena is a **distributed AI system** with physical components (cameras, sensors, displays) that make intelligent decisions and control devices. What makes it unique is that it's built using **research through practice** - simultaneously developing the system AND the methodology for effective AI-human collaboration.

### 🎯 Dual Purpose Design

**Practical Output**: Distributed AI system with:
- **Physical components** - PTZ cameras, sensors, displays, Raspberry Pis
- **Event processing** - Motion, sound, MQTT, file changes, Home Assistant integration  
- **AI decision making** - Process events, control devices, display information
- **Real-time interfaces** - Phoenix LiveView dashboards and chat system

**Research Output**: Universal AI-human collaboration patterns:
- **Physics of Work methodology** - Make it better for the next person (which is us)
- **Two-role framework** - AI as development team, human as product team
- **Conversation archaeology** - Complete development consciousness preservation
- **Decision confidence protocols** - Systematic risk assessment for AI autonomy

### 🔍 What Makes This Unique

This isn't just building software OR studying methodology - it's **research through practice**. Every component is both functional system code AND a laboratory for discovering collaboration patterns that work at scale.

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

**Physics of Work in Practice**: This project demonstrates:

- **Iterative process improvement** - Each component development improves the methodology
- **Knowledge transfer patterns** - AI learns from human expertise, human learns from AI systematic thinking
- **Decision confidence protocols** - Proven risk assessment for autonomous AI development
- **Universal applicability** - Patterns that work across project types and technical domains

## Documentation

### Essential Reading
- **[Conversation Archaeology](docs/CONVERSATION_ARCHAEOLOGY.md)** - The core innovation explained
- **[Quick Start Guide](docs/QUICK_START.md)** - Get running in 5 minutes
- **[Collaboration Methodology](docs/COLLABORATION_METHODOLOGY.md)** - Proven AI-human patterns

### For AI Collaborators  
- **[AI Collaboration Protocol](AI_COLLABORATION_PROTOCOL.md)** - Core working agreements
- **[AI Quick Reference](docs/AI_QUICK_REFERENCE.md)** - Commands and patterns
- **[Development Journal](docs/journal/)** - Real-time discoveries and insights

## Impact

**Practical**: A working distributed AI system with real hardware integration, event processing, and intelligent decision-making capabilities.

**Methodological**: Proven patterns for AI-human collaboration that scale beyond individual projects, with complete development consciousness preservation as a side benefit.

**Future**: Universal methodology that any AI-human team can adopt for effective collaboration, regardless of domain or technical stack.

---

*Research through practice: Building the future while learning how to build it better.*