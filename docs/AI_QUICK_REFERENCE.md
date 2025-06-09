# AI Quick Reference - Athena Project

**Core Patterns & Quick Answers for Future AI Sessions**

## Project Structure
```
athena/
├── data/claude-logs/           # Claude conversation archives (append-only)
├── system/ash-ai/ash_chat/     # Main web UI (Phoenix LiveView)
├── system/athena-ingest/       # Event collectors (Elixir Broadway)
├── system/athena-mcp/          # MCP servers for hardware control
├── docs/                       # Documentation & collaboration guides
└── dev-tools/                  # Development MCP servers
```

## Key Services & Locations

### Web UI
- **URL**: http://localhost:4000
- **Main app**: `/system/ash-ai/ash_chat/`
- **Routes**: Chat (`/chat`), Events (`/events`), System (`/system`)
- **Tech**: Phoenix LiveView + Tailwind CSS

### Event Collection
- **Claude logs**: `~/.claude/projects/*.jsonl` → `/data/claude-logs/live/`
- **Collectors**: `/system/athena-ingest/{claude_collector,camera_collector}/`
- **Neo4j**: Running on `j@llm:7474` (docker container)

### Hardware Control
- **PTZ cameras**: MCP servers in `/system/athena-mcp/`
- **Camera daemon**: `/system/hardware-controls/`

## Common Tasks

### Start/Check Services
```bash
# Web UI (if not running)
cd /Users/j/Code/athena/system/ash-ai/ash_chat && mix phx.server

# Claude collector
cd /Users/j/Code/athena/system/athena-ingest/claude_collector && mix run --no-halt

# Check what's on port 4000
lsof -i :4000

# Neo4j status
ssh j@llm "docker ps | grep neo4j"
```

### UI Updates
- **Layout**: `/lib/ash_chat_web/components/layouts/app.html.heex`
- **LiveViews**: `/lib/ash_chat_web/live/*.ex` (inline rendering with `~H"""`)
- **Routes**: `/lib/ash_chat_web/router.ex`
- **Navigation**: Already has unified menu (Chat, Events, System)

### Git Workflow
```bash
git status
git add -A
git commit -m "Brief description + thinking log"
git push origin master
```

## Architecture Patterns

### Physics of Work
- **Autonomous execution**: "I'll proceed with..." not "Should I..."
- **Stewardship**: Make it better for the next person
- **Documentation**: Journal entries in `/docs/journal/`

### Event Pipeline
```
Source → File Watcher → Broadway Pipeline → Neo4j → Dashboard
```

### Safety Principles
- **Append-only logs**: Never delete Claude conversations
- **Idempotent operations**: Safe to run multiple times
- **Multiple backups**: Archive + live sync + git

## Quick Fixes

### Port Already in Use
```bash
lsof -i :4000  # Check what's using port
# Usually means service is already running
```

### Neo4j Connection Errors
```bash
ssh j@llm "docker restart neo4j"
```

### Missing Dependencies
```bash
cd /path/to/elixir/project && mix deps.get
```

### File Permissions
```bash
chmod +x script.sh
```

## File Editing Patterns

### LiveView Layout Updates
- Use Tailwind classes: `bg-white border border-gray-200 rounded-lg`
- Responsive: `grid grid-cols-1 lg:grid-cols-2 gap-6`
- Height calc: `h-[calc(100vh-12rem)]`

### Navigation Menu
Already implemented in app layout with emoji icons:
- 💬 Chat
- 📊 Events  
- ⚙️ System

### Common Elixir/Phoenix
- Routes: `live "/path", ModuleLive`
- Links: `<.link navigate={~p"/path"}>Label</.link>`
- Inline rendering: `def render(assigns) do ~H""" ... """`

## Current Session Context
- Claude logs collection ✅ DONE
- Web UI navigation ✅ IN PROGRESS  
- Event streaming ✅ WORKING

## Remember
- Use TodoWrite for task tracking
- Minimal structural changes (as requested)
- Test in browser at http://localhost:4000
- Commit frequently with thinking logs

---
*Quick reference for efficient AI collaboration on Athena*