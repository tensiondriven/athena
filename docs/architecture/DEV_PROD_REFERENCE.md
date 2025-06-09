# Development/Production Environment Reference

**Last Updated**: 2025-06-09  
**Status**: Phase 1 - Simplified Single Environment

## Architecture Overview

### Phase 1: Nuts and Bolts (Current)
**Goal**: Get chat conversation data flowing into real-time dashboard  
**Approach**: Single environment, minimal processing, focus on data visibility

### Phase 2: Intelligence (Future)
**Goal**: Knowledge graph extraction, transformations, multimodal processing  
**Approach**: Multiple environments, complex data processing, AI workflows

## Current System Design

### Environment Strategy
- **Single Environment**: No dev/prod separation for now
- **Hybrid Services**: Local development can consume remote services (Ollama at 10.1.2.200)
- **Data Source**: Claude Code JSONL files treated as immutable source of truth

### Data Flow Architecture

```
Claude Code JSONL Files
         ↓
   Shell Collector (local)
         ↓
   Phoenix PubSub
         ↓
   LiveView Dashboard
```

### Components

**Data Sources:**
- Claude Code conversation logs (`~/.claude-code/logs/*.jsonl`)
- File modification events (existing, keep working)

**Collection:**
- Shell-based collector (replaces Python complexity)
- Watches JSONL files for changes
- Stores entire file contents (complete/easy approach)

**Display:**
- ash_chat Phoenix app with "/live-events" page
- Real-time updates via LiveView + PubSub
- Shows chat conversations flowing in

## Key Decisions

### Simplified Choices
- ✅ Single environment (no dev/prod complexity)
- ✅ Store entire files (vs incremental processing)
- ✅ Extend existing ash_chat app (vs new app)
- ✅ Keep existing file metrics (vs rebuild everything)

### Future Flexibility
- 🔮 Architecture supports multimodal data sources (images, audio)
- 🔮 Clear separation between Phase 1 (collection) and Phase 2 (processing)
- 🔮 Can add dev/prod environments when needed

## Service Distribution

### Local (Development Machine)
- ash_chat Phoenix application
- Shell collector processes
- Git repositories and development tools

### Remote (10.1.2.200 LLM Server)
- Ollama service (llama3.2 model)
- Neo4j (for future Phase 2)
- Long-running production services

## Success Metrics

**Phase 1 Success**: 
- See chat conversations appearing in real-time dashboard
- File modification metrics continue working
- Numbers going up as conversations happen

**Core Requirement**:
> "As I'm having conversations with you, I want to see one of the Phoenix apps. I want to see a webpage that shows messages coming in, which include flood chat data."