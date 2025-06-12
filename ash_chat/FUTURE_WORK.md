# Ash Chat Future Work

## Research Questions

### Tool Use Impact on LLM Intelligence
- Does routing all LLM output through tools reduce reasoning capabilities?
- How does tool calling affect model performance in benchmarks?
- Can models maintain deep character consistency through tool-mediated interactions?
- Does MCP/tool use break immersion in advanced roleplay scenarios?

### Forced JSON Response Impact
- Does constraining output to JSON format reduce model creativity/expressiveness?
- How do structured outputs affect reasoning quality compared to free-form text?
- Best practices for preserving model capabilities while using tools
- Hybrid approaches: some direct generation, some tool-mediated

## Planned Features

### Inference Controls
- Dynamic provider switching (Ollama, OpenAI, Anthropic, etc.)
- Per-message inference parameters (temperature, top_p, max_tokens)
- Provider URL configuration UI
- Model selection with provider-specific model lists

### Room & Client System
- Multi-room chat support with OTP supervision
- Client presence tracking
- Room-specific configurations
- Agent assignment per room

### Character Configuration
- Persona definition system
- Character cards with system prompts
- Per-character inference defaults
- Character switching mid-conversation

### Context Management
- Context parts system for modular prompts
- Dynamic context window management
- RAG integration for long-term memory
- Context summarization strategies

### MCP Integration
- Bridge existing Athena tools (cameras, PTZ, sensors)
- Tool calling through Ash resources
- Streaming tool responses
- Tool permission management

### Collaboration Card Game (MCP)
- Turn-based game where AI plays cards from hand of 7
- Each game session has file: `games/[timestamp]-[goal-or-untitled].game`
- Cards randomly selected from deck
- Starting cards:
  - LEARN_FROM_MISTAKE
  - REVIEW_DOCS
  - CHECK_ECOLOGY
  - (need 2-3 more)
- Each turn: call play_card() MCP function
- Do what the card says
- Human works alongside, removing obstacles/clarifying
- Enacts full Collaboration Corpus during gameplay

### Glossary Historian Role
- Research origins and lineages of all glossary concepts
- Document intellectual history of our practices
- Create visualizations of idea relationships
- Track evolution of concepts over time
- Build concept genealogy trees
- Share findings through journal entries
- Connect our practices to broader movements (lean, agile, etc.)
- Identify influences and predecessors
- Map conceptual dependencies