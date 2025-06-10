# Quick Start Guide

Get Athena running in under 5 minutes and see the conversation archaeology in action.

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

## 4. Explore Conversation Archaeology

The magic happens in `chat-history/`:

```bash
# See the complete development history
ls chat-history/ | wc -l
# Shows: 90+ conversation files

# Check total size of preserved consciousness  
du -sh chat-history/
# Shows: ~50MB of structured development data

# Look at a conversation file
head chat-history/3c00c241-4f9f-4d2b-aebd-34f7d5392654.jsonl
```

**Each conversation file contains:**
- Complete tool usage with context
- Every architectural decision with reasoning
- Debugging steps and solutions
- Git commit correlation

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

1. **Working multi-user AI chat system** with agent personalities
2. **Real-time event processing** with auto-discovery
3. **Complete conversation archaeology** - every development decision preserved
4. **Traceability** from any line of code back to its original reasoning

## Next Steps

- **[Collaboration Methodology](COLLABORATION_METHODOLOGY.md)** - Learn the proven patterns
- **[Development Journal](journal/)** - Read real-time discoveries  
- **[AI Quick Reference](AI_QUICK_REFERENCE.md)** - Key commands and patterns

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