# AI Onboarding Quick Start

> For new AI sessions starting work on Athena. Read this first!

## 🚀 First 3 Steps

1. **Load the protocol**: 
   ```bash
   cat AI_COLLABORATION_PROTOCOL.md
   ```

2. **Check current state**:
   ```bash
   TodoRead  # What's in progress?
   git status  # Clean working directory?
   ```

3. **Get oriented**:
   ```bash
   cat docs/QUICK_START.md  # System overview
   ls docs/  # Available documentation
   ```

## 📋 Essential Checklists

**[Development Checklists](DEVELOPMENT_CHECKLISTS.md)** - Lightweight reminders:
- ⚡ Quick checklist for simple changes
- 🚀 Starting new features
- 🚨 When things go wrong
- 🎯 Philosophy checks (minimal approach)

## 🗺️ Key Documentation Map

### System Understanding
- **[QUICK_START.md](QUICK_START.md)** - 5-minute system overview
- **[SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)** - Technical design
- **[EXISTING_TOOLS_AND_SYSTEMS.md](EXISTING_TOOLS_AND_SYSTEMS.md)** - What's already built (CHECK FIRST!)
- **ash_chat/** - Main Phoenix LiveView application

### Philosophy & Methodology  
- **[AI_COLLABORATION_PROTOCOL.md](../AI_COLLABORATION_PROTOCOL.md)** - How we work
- **[COLLABORATION_METHODOLOGY.md](COLLABORATION_METHODOLOGY.md)** - Research patterns
- **[journal/](journal/)** - Real discoveries and learnings

### Practical Resources
- **[AI_QUICK_REFERENCE.md](AI_QUICK_REFERENCE.md)** - Common commands
- **[DEVELOPMENT_CHECKLISTS.md](DEVELOPMENT_CHECKLISTS.md)** - Process reminders
- **[CONVERSATION_ARCHAEOLOGY.md](CONVERSATION_ARCHAEOLOGY.md)** - Tracing decisions

## 🔑 Key Commands

```elixir
# In IEx (cd ash_chat && iex -S mix)
AshChat.Setup.reset_demo_data()  # Create test data
AshChat.Setup.quick_test()       # Verify system

# Check persistence (new!)
./test_demo_persistence.sh       # SQLite status
```

## ⚠️ Common Pitfalls

1. **Testing in wrong context** - Use IEx, not standalone scripts
2. **Missing dependencies** - Check with `mix hex.info package_name`
3. **Gitleaks blocking commits** - Check `.gitleaks.toml` for allowlist
4. **Over-engineering** - Ask "What's the minimal solution?"

## 🎯 Core Philosophy

- **Small sharp tools** - Single purpose, does it well
- **High agility** - Easy to modify or remove
- **Minimal approach** - What's the smallest useful version?
- **Push every commit** - Real-time progress tracking

## 📊 Current System State

- **Chat persistence**: SQLite added (messages, rooms, users, agent_cards)
- **100+ conversations** preserved in chat-history/
- **Phoenix server**: Usually running on port 4000
- **Multi-agent chat**: Sam and Maya bots in Conversation Lounge

## 🚦 Ready to Start?

1. ✅ Protocol loaded
2. ✅ Todos checked  
3. ✅ Git status clean
4. ✅ Philosophy understood
5. **Go build something minimal and useful!**

---

*Remember: When in doubt, check the checklists and keep it minimal.*
