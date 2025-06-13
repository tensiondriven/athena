# Context System Design Exploration

## Two Separate Concepts

### 1. LLM Backends (formerly Profiles)
- Fixed entries: Claude Code, OpenRouter, Ollama
- Connection settings (URL, model)
- Secrets from environment variables
- Each agent selects one backend

### 2. Context Presets/Builds 
- Collections of context pieces
- Sources:
  - **Tool-generated pieces** (e.g., list manager outputs, summaries)
  - User-created custom blocks
  - Can be registered/unregistered (enabled/disabled)
- Features:
  - Drag/drop reordering
  - Dynamic pieces that update
- Each agent selects one context preset

### 3. Dynamic Context Manager (Background)
- Runs after each message
- Compacts/summarizes context
- Incorporates highly relevant information
- Keeps context fresh and focused

## Clarified Design

- Context presets are **shared named configurations** (e.g., "Research Context", "Creative Writing Context")
- Cannot delete a preset if any agent is using it
- Each agent selects one context preset (or "System Default")

## Questions Remaining

- Should context pieces be stored as database records with a "source" field (tool/user/system)?
- Should we start with just the static context preset system and add dynamic management later?
- How should tools register their context pieces? Through a specific API/interface?