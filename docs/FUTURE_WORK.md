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
- Better context management for long conversations
- Automatic concept extraction and relationship mapping
- Pattern detection across multiple conversations

## Infrastructure
- Event-driven architecture completion
- Distributed collector implementation
- Real-time synchronization between components

---
*Living document - wishes become features*