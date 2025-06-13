# Future Work

*Ideas and wishes for system improvements*

## Documentation System
- Force-directed graph visualization for blog/journal entries showing concept relationships
- Git-based search with concept clustering
- Auto-generated concept maps from glossary terms

## Task Management
- Lightweight "Least Responsible Moment" task tracker
- QA Game integration for requirements gathering
- Visual task dependency graphs

## MCP Integrations
- iTerm2 MCP server for terminal state queries
- Playwright-based browser automation MCP
- Claude Code as MCP server for other tools
- Parallel sidequest execution ("clone" for branching explorations)

## Athena Web UI Enhancements

### Process Tagging System
- Auto-detect when established processes are being applied in conversations
- Tag messages with process indicators (e.g., #bias-for-action, #minimize-wip, #reflection-protocol)
- Three tag states:
  - **Suggested** (AI-detected, unconfirmed)
  - **Confirmed** (human-verified)
  - **Re-rolled** (human requested different detection)
- Tags require extra confirmation to delete (prevent accidental removal)
- Visual distinction between states (opacity, border style, etc.)
- Hoverable tooltips showing why tag was applied
- Stats dashboard showing process usage over time

Example: When I add something to glossary after being asked, UI suggests #bias-for-action tag

## Collaboration Features
- Real-time collaborative documentation editing
- Version control integration in UI
- Inline concept previews (hover over glossary terms)

## AI Improvements

### Ollama Model Loading Status Detection
**Priority: Medium**

Currently, when switching between inference backends (OpenRouter vs Ollama), there's no visibility into whether Ollama models are loaded or need to be loaded. This can cause delays or failures when attempting to use Ollama-based agents.

**Proposed Implementation:**
- Add `OllamaModelStatus` module in `lib/ash_chat/ai/`
- Status detection: Check if required models are loaded before routing requests
- Proactive loading: Auto-load models when agents are activated
- UI feedback: Show loading status in profiles/backend selection interface  
- Graceful fallback: Switch to OpenRouter temporarily if Ollama models aren't ready
- Extend inference config system to include model readiness checks

**Benefits:** Improved UX with clear feedback, reduced latency, better reliability through fallback mechanisms, enhanced debugging for inference pipeline issues.

### Context Assembler Minimap UI
**Priority: Medium**

A VSCode minimap-style visualization for context assembly debugging and optimization.

**Core Interface:**
- 200-300px wide, 500px tall floating panel
- Toggleable sections (system prompt, conversation history, agent settings, metadata)
- Drag-to-reorder section priority
- Individual refresh buttons for dynamic content (timestamps, status, recent messages)
- Real-time preview of assembled context length and token count

**Section Types:**
- Static: System prompts, agent cards, base configuration
- Dynamic: Recent messages, room metadata, user presence, model status
- Computed: Context statistics, assembly warnings, optimization suggestions

**Interaction Model:**
- Click section headers to toggle on/off (like Word 87 toolbar customization)
- Drag sections to reorder assembly priority
- Refresh icon per section for dynamic content updates
- Collapse/expand for detailed view vs overview

**Implementation:**
- New LiveView component: `ContextAssemblerMinimap`
- Real-time updates via Phoenix PubSub
- Integration with existing `ContextAssembler.inspect_components/1`
- Overlay positioning similar to VSCode minimap

**Use Cases:**
- Debug context assembly issues during conversation
- Optimize token usage by toggling unnecessary sections
- Visualize context composition for different agent configurations
- Monitor dynamic content refresh rates and impact

### Advanced Context Management
- Better context management for long conversations
- Automatic concept extraction and relationship mapping
- Pattern detection across multiple conversations

## Infrastructure
- Event-driven architecture completion
- Distributed collector implementation
- Real-time synchronization between components

---
*Living document - wishes become features*