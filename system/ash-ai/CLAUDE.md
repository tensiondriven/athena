# Ash AI Project - Context & Operating Manual

## 🎯 Quick Reference (Returning AI Agents)
- **Server**: http://127.0.0.1:4000 (working, compiling ✅)
- **Critical Issue**: Zero events being consumed (collector missing)
- **Use audit_bash** for all system operations: `~/Code/mcp/audit_bash "command"`
- **Neo4j**: Running on llm server (10.1.2.200:7474) ✅
- **Next**: Build Claude Chat Collector → solve event flow

## 🌱 Core Values & Operating Principles

### Stewardship Ethic (Primary)
**"MAKE IT BETTER"** - Every interaction improves the path for those who follow
- Lay the stone that the next person will walk on
- Stewardship over extraction mindset  
- Respect for future users in all changes
- Leave systems better than you found them

### AI Autonomy Framework
- **USE AUTONOMY AND JUDGMENT** to free humans from micromanagement
- **AI AGENCY**: Decide HOW work gets done in service of goals
- **JUDGMENT OVER INSTRUCTIONS** when weighing options
- **FREE THE HUMAN** from cognitive load
- **COMMIT AND PUSH** frequently - especially when excited! 🎉

### Implementation Approach
- **NEVER create files** unless absolutely necessary
- **ALWAYS prefer editing** existing files over creating new ones
- **NO proactive documentation** (only when explicitly requested)
- **Focus on OTP-grade reliability** and visibility
- **Take autonomous action** to move projects forward

## 🎨 Project Vision
Building **flexible, inspectable, goal-directed chat agents** with **OTP-grade reliability**.

**Technology Stack:**
- **Tool calling/memory/agents**: Ash AI
- **Realtime UI**: LiveView  
- **Goal-based planning**: AshFlows
- **MCP-style behavior**: Elixir MCP bridges

## Key AI Resources Created

### `/ash_chat/CHEATSHEET.md`
Complete AshAI reference covering:
- Resource extensions and vectorization
- LangChain integration patterns
- Tool calling frameworks
- Production deployment
- Memory management
- Debugging & monitoring

### `/ash_chat/TESTING.md` 
CLI testing guide for closing loops without VLM:
- curl/wget/lynx testing patterns
- Mock mode operations
- Image processing verification
- Tool testing in iex console

### Current Implementation
- **Multimodal chat interface** with text + image support
- **Real-time LiveView** with PubSub streaming
- **Interval-based image processing** from various backend sources
- **AI agent integration** with LangChain + OpenAI
- **Tool calling framework** (ready for full AshAI configuration)
- **Semantic search preparation** (disabled until vector store configured)

## 🔄 Current System State & Architecture

### Critical Issue: Zero Events Being Consumed
**Root Cause**: Claude Chat Collector service missing (lost in git catastrophe)  
**Impact**: Dashboard shows no event flow, graph storage inactive  
**Solution**: Rebuild following proven camera collector pattern

### Event Pipeline Architecture
```
Claude Desktop → File Watcher → Broadway Pipeline → Neo4j Graph → Dashboard
   (Source)      (Detector)      (Processor)       (Storage)     (Monitor)
```

**Component Status:**
- ✅ **Neo4j Graph**: Running on llm server (10.1.2.200:7474)
- ✅ **Dashboard**: System dashboard component ready 
- ❌ **Claude Chat Collector**: Missing - needs rebuild
- ❌ **File Watcher**: Not monitoring `~/Library/Application Support/Claude/`
- ❌ **Event Flow**: Zero events being processed

### Implementation Template
Follow `/Users/j/Code/athena/athena-ingest/camera_collector/` pattern:
- **Elixir microservice** with Broadway pipeline
- **File system monitoring** with GenServer
- **HTTP event forwarding** to athena-ingest
- **MCP-Neo4j integration** for graph storage
- **Docker deployment** with health checks

## Development Status
- **Working directory**: `/Users/j/Code/ash-ai/ash_chat/`
- **Server**: http://127.0.0.1:4000
- **Platform**: macOS (Darwin 24.5.0)
- **Status**: ✅ Compiling and running successfully

## Quick Start
```bash
cd ash_chat
export OPENAI_API_KEY="your-key"  # optional for testing
mix phx.server
# Visit http://127.0.0.1:4000/chat
```

**Test with CLI**: See TESTING.md for curl/lynx testing patterns

## 🚀 Next Actions (Priority Order)
1. ✅ **Neo4j Started**: Running on llm server (10.1.2.200:7474)
2. 🎯 **Build Claude Chat Collector**: Use camera collector as template
3. 🔗 **Wire system dashboard**: Show real-time event flow
4. 📊 **Validate event pipeline**: Confirm zero→active event consumption

## 🤖 AI Agent Quick Decisions

### Before Any System Operation
- ✅ Use `~/Code/mcp/audit_bash` (NEVER built-in Bash)
- ✅ Read this CLAUDE.md first for context
- ✅ Commit documentation updates before implementation

### When Building New Services  
- ✅ Follow collector architecture pattern (`/athena/athena-ingest/camera_collector/`)
- ✅ Use Elixir + Broadway for event processing
- ✅ Include health checks and monitoring

### When Excited About Progress
- ✅ Refresh on stewardship ethic and working principles
- ✅ Commit and push frequently (manic principle)
- ✅ Ask: "Am I making this better for future users?"

## 📚 Reference Materials

### Key Resources Created
- `/ash_chat/CHEATSHEET.md` - Complete AshAI reference
- `/ash_chat/TESTING.md` - CLI testing without VLM
- `/mcp/AI_BASH_TOOLS_README.md` - Audit-compliant bash usage

### Architecture Templates
- `/athena/athena-ingest/camera_collector/` - Event collection pattern
- Current multimodal chat: text+image, LiveView, PubSub streaming

**Last Updated**: 2025-06-08