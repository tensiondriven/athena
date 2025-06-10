# Athena System Architecture

**Distributed AI system with physical components and intelligent decision-making**

## System Overview

Athena is a distributed AI system that processes events from multiple sources and makes intelligent decisions about device control and information display.

```
┌─ Physical Layer ─────────────────────────────────────────┐
│                                                          │
│  📹 PTZ Cameras    🎤 Microphones    📺 Displays        │
│  📱 Raspberry Pis  🔊 Speakers       🏠 Home Assistant  │
│                                                          │
└─────────────────┬────────────────────────────────────────┘
                  │
┌─ Event Layer ───▼────────────────────────────────────────┐
│                                                          │
│  • Motion events from cameras/PIR sensors               │
│  • Sound events from microphones                        │
│  • MQTT messages from IoT devices                       │ 
│  • File system changes (logs, conversations)            │
│  • Home Assistant events                                │
│                                                          │
└─────────────────┬────────────────────────────────────────┘
                  │
┌─ Processing ────▼────────────────────────────────────────┐
│                                                          │
│  🧠 AI Decision Engine (Phoenix LiveView + Ash)         │
│  │                                                      │
│  ├─ Event Router (Elixir Broadway pipelines)            │
│  ├─ Context Manager (conversation state)                │
│  ├─ Vision Pipeline (SAM, CLIP computer vision)         │
│  └─ Chat Interface (multi-user AI agents)               │
│                                                          │
└─────────────────┬────────────────────────────────────────┘
                  │
┌─ Control Layer ─▼────────────────────────────────────────┐
│                                                          │
│  🎛️ MCP Tool Calls:                                      │
│  • Display HTML/messages on specific screens            │
│  • Control PTZ cameras (pan, tilt, zoom)                │
│  • Trigger audio playback on speakers                   │
│  • Capture screenshots and video                        │
│  • Update Home Assistant entities                       │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Core Components

### Physical Infrastructure
- **PTZ Cameras**: Pan-tilt-zoom cameras for dynamic monitoring
- **Fixed Cameras**: USB webcams for static monitoring
- **Raspberry Pi Nodes**: Distributed processing and sensor nodes
- **Display Devices**: Screens for information presentation
- **Audio Devices**: Microphones and speakers for sound interaction
- **IoT Integration**: Home Assistant connected devices

### Event Processing Pipeline
- **Collectors**: Python/Elixir services gathering events from each source
- **Event Router**: Broadway-based Elixir pipeline for event processing  
- **Event Store**: Persistent storage with Neo4j graph database
- **Real-time Updates**: Phoenix PubSub for live dashboard updates

### AI Decision Layer
- **Chat Interface**: Multi-user system with AI agent personalities
- **Context Manager**: Maintains conversation and system state
- **Decision Engine**: Processes events and determines appropriate actions
- **Vision Analysis**: Computer vision pipeline using SAM and CLIP

### Device Control
- **MCP Servers**: Model Context Protocol servers for tool access
- **Hardware Abstraction**: Generic interfaces for camera/audio/display control
- **Command Routing**: Intelligent routing of control commands to devices

## Unique Architecture Features

### 1. Event-Driven Intelligence
Unlike traditional home automation that follows if-then rules, Athena processes events through an AI decision layer that can:
- **Correlate events** across multiple sources
- **Understand context** from previous interactions  
- **Make nuanced decisions** based on current system state
- **Learn from outcomes** and adjust behavior

### 2. Distributed Yet Coordinated
- **Edge processing** on Raspberry Pi nodes for low latency
- **Central coordination** through the Elixir/Phoenix backend
- **Mesh connectivity** allowing devices to work independently if needed
- **Graceful degradation** when network connections are interrupted

### 3. Multi-Modal Interaction
- **Visual input** through computer vision processing
- **Audio input** through sound event detection
- **Text input** through chat interface and file monitoring
- **Physical output** through device control and display

### 4. Research Through Practice Design
Every component serves dual purposes:
- **Practical function** for the distributed AI system
- **Research platform** for developing AI-human collaboration patterns

## Implementation Status

### ✅ Working Components
- **Phoenix LiveView Interface** - Real-time chat and event dashboards
- **Event Collection** - File monitoring, camera integration
- **Computer Vision** - SAM pipeline for image analysis
- **MCP Tool Integration** - Camera control, screenshot capture
- **Multi-user Chat** - Agent personalities and room hierarchy

### 🔄 In Development  
- **Event Router** - Broadway pipeline for event processing
- **Neo4j Integration** - Graph database for event storage
- **Distributed Deployment** - Raspberry Pi node coordination
- **Home Assistant Bridge** - IoT device integration

### 📋 Planned
- **Audio Processing** - Sound event detection and response
- **Mobile Interface** - Touch screen control panels
- **Voice Interaction** - Natural language device control
- **Mesh Networking** - Resilient inter-node communication

## Research Value

This architecture enables research into:
- **Multi-modal AI systems** processing diverse event types
- **Distributed intelligence** with edge and central processing
- **Human-AI collaboration** in physical/digital hybrid environments
- **Event correlation** and intelligent decision-making at scale

---

*Real distributed AI system architecture emerging from research through practice methodology*