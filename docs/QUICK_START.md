# Quick Start Guide

Get the Athena distributed AI system running in under 5 minutes and see research through practice in action.

## Prerequisites

- Elixir 1.15+
- Phoenix 1.7+ 
- Git

## 1. Start the Chat System

```bash
# Navigate to the main application
cd ash_chat

# Install dependencies  
mix deps.get

# Start the Phoenix server
mix phx.server
```

## 2. Access the Interface

Open your browser to: **http://localhost:4000**

You'll see:
- **Chat** - Multi-user AI chat with agent personalities
- **Events** - Real-time event monitoring and inspection  
- **System** - System status and controls

## 3. Create Demo Data

```bash
# In a new terminal, start an IEx session
cd ash_chat && iex -S mix

# Create demo users, rooms, and AI agents  
AshChat.Setup.reset_demo_data()

# Test the multi-user system
AshChat.Setup.quick_test()
```

## 4. Explore the Dual Purpose System

### A. Practical System: Distributed AI

**Event Processing:**
```bash
# Send a test event to the system
curl -X POST http://localhost:4000/webhook/test \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
    "type": "motion.detected", 
    "source": "camera_01",
    "description": "Motion detected in living room"
  }'

# Watch it appear in real-time on the Events dashboard
# Visit http://localhost:4000/events
```

**AI Decision Making:**
- System receives events from cameras, sensors, file changes
- AI processes events and makes intelligent decisions
- Triggers actions through MCP tools (camera control, displays)

### B. Research Output: Methodology Development

**Conversation Archaeology:**
```bash
# See methodology development preserved in real-time
ls chat-history/ | wc -l
# Shows: 90+ conversation files documenting collaboration patterns

# Each conversation shows how the practical system was built
head chat-history/3c00c241-4f9f-4d2b-aebd-34f7d5392654.jsonl
```

**Research Through Practice:**
- Building real system components reveals collaboration patterns
- Each technical challenge improves the methodology
- Practical constraints drive methodology refinement

## 5. Trace a Decision

Try this archaeological workflow:

```bash
# Find a piece of code you're curious about
git blame ash_chat/lib/ash_chat/resources/room.ex

# Look for the commit hash in the conversation history
grep -r "c3e13db" chat-history/

# Read the full conversation that created that code
# Every line of code has complete provenance!
```

## What You've Just Seen

**Practical System:**
1. **Distributed AI event processing** - real-time ingestion and intelligent handling
2. **Multi-user chat interface** with AI agent personalities  
3. **MCP tool integration** - AI can control cameras, capture screenshots, process events
4. **Phoenix LiveView dashboards** - real-time system monitoring

**Research Methodology:**
1. **Research through practice** - building real system while developing collaboration patterns
2. **Conversation archaeology** - complete development decision preservation
3. **Two-role framework** - AI as development team, human as product team in action
4. **Physics of Work** - making it better for the next person (which is us)

## Next Steps

### 🤖 For AI Collaborators
**Start Here:** **[AI Onboarding Quick Start](AI_ONBOARDING_QUICKSTART.md)** - Essential first steps for new AI sessions

**Core Resources:**
- **[AI Collaboration Protocol](../AI_COLLABORATION_PROTOCOL.md)** - How we work together
- **[Development Checklists](DEVELOPMENT_CHECKLISTS.md)** - Process reminders from experience
- **[AI Quick Reference](AI_QUICK_REFERENCE.md)** - Common commands and patterns

### 📚 Understanding the System
- **[System Architecture](SYSTEM_ARCHITECTURE.md)** - Complete distributed AI system design
- **[Collaboration Methodology](COLLABORATION_METHODOLOGY.md)** - Research through practice patterns
- **[Development Journal](journal/)** - Real-time discoveries and insights

### 🔍 Deep Dives
- **[Conversation Archaeology](CONVERSATION_ARCHAEOLOGY.md)** - How methodology emerges from practice
- **Chat Persistence** - Check `ash_chat/PERSISTENCE_*.md` for SQLite implementation

## Troubleshooting

**Port 4000 already in use:**
```bash
lsof -i :4000  # Check what's using the port
# Usually means Phoenix is already running
```

**Dependencies not found:**
```bash
cd ash_chat && mix deps.get
```

**Compilation errors:**
```bash
cd ash_chat && mix compile
```

---

*You're now running a system that preserves complete AI development consciousness alongside working code.*
