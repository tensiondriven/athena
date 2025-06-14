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
  - SHARE_INFORMATION (tactical action)
  - REQUEST_INFORMATION (tactical action)
  - REQUEST_PROJECT (requires role/purpose)
  - SET_EXPECTATION (establish ongoing responsibility)
- Each turn: call play_card() MCP function
- Do what the card says
- Human works alongside, removing obstacles/clarifying
- Enacts full Collaboration Corpus during gameplay

### Async Sidequests
- Make sidequests asynchronous/parallel
- AI can dispatch sidequest and continue main work
- Sidequest results arrive when ready
- Multiple sidequests can run concurrently

### Claude Code as MCP
- Research: Can Claude Code itself be exposed as MCP server?
- Would allow other tools to invoke Claude Code capabilities
- Meta-MCP: MCP server that runs Claude Code instances
- Could enable multi-agent collaboration patterns
- TODO: Kick the tires on claude-mcp server implementations
  - Test ferrislucas/iterm-mcp for terminal control
  - Test steipete/claude-code-mcp for Claude-in-Claude
  - Explore async sidequest potential
  - Document setup and capabilities

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

### Self-Reflective Role Update Agent
- Infrastructure for periodic role self-reflection
- Triggers: After 50 turns OR once/hour on active days
- Process:
  1. Load role definition + recent work history
  2. Analyze what role actually did vs definition
  3. Create up to 12 micro git commits updating role
  4. Reflect between each commit
  5. Add/update "Questions" section at role bottom
  6. Document cognitive dissonances specific to role
  7. Tag questions with dates (e.g., <!-- 2025-06-11 -->)
- Questions focus on:
  - Role boundary confusion
  - Missing capabilities discovered during work
  - Tensions between defined and actual behavior
  - Unclear directives encountered
- Enables roles to evolve based on practice
- Creates audit trail of role evolution

### Role Schema Enforcement System
- Define formal schemas for roles and structured data
- Generate validators/enforcers from schemas
- Benefits:
  - Consistent role structure across all definitions
  - Type-safe role capabilities and requirements
  - Automated validation on role updates
  - Enable tooling (role switcher, capability matcher)
- Schema elements:
  - Required fields (persona, responsibilities, capabilities)
  - Optional fields (tools, philosophy, questions)
  - Field types and constraints
  - Relationship definitions between roles
- Implementation options:
  - JSON Schema for role definitions
  - TypeScript interfaces generated from schema
  - Elixir structs with Ecto changesets
  - GraphQL schema for role queries
- "Hardcore structured role data" → enabling role composition and analysis

### iTerm2 MCP Integration
- MCP server for iTerm2 control
- Capabilities:
  - Open new tabs/windows
  - Run interactive commands
  - Display live output streams
  - Split panes for monitoring
  - Execute AppleScript for macOS automation
- Use cases:
  - Launch monitoring scripts in dedicated panes
  - Run test suites with live output
  - Open multiple file watchers
  - Create development dashboard layouts
- Could use iTerm2's Python API
- Alternative: AppleScript execution MCP for broader macOS control

### Blog Publishing
- Consider publishing "Scared of the Blank" on GitHub Pages
- Other journal entries worth sharing publicly
- Create publication workflow for insights
- Balance transparency with working notes

### Advanced Context Management System
- **Context Presets**: Named configurations of context pieces
  - Shareable across agents
  - Tool-generated pieces (list managers, monitors)
  - User-created custom blocks
  - Enable/disable individual pieces
  - Drag-and-drop reordering
- **Dynamic Context Manager**: Background process after each message
  - Compacts and summarizes conversation context
  - Identifies and preserves highly relevant information
  - Prevents context window overflow
- **Tool Context Registration**: API for tools to register context pieces
  - Dynamic updates when tool data changes
  - Examples: todo summaries, project status, error logs
- Start simple with database-backed pieces, add complexity as needed

### LLM Request Router
- Use small LLM to classify incoming requests as simple/complex
- Route simple requests to cheap models, complex to expensive ones
- Learn from failures when cheap model can't handle it

### Performance Profiling Analysis
- Profile Claude Code to understand where time is spent during inference
- Profile Athena application for performance bottlenecks
- Key questions to answer:
  - How much time waiting for API calls vs token generation?
  - Where are the latency hotspots in the request pipeline?
  - What's the breakdown between:
    - Network I/O (API requests)
    - Token generation/streaming
    - Tool execution overhead
    - Context assembly/formatting
    - Message processing/routing
- Tools to consider:
  - Elixir's :observer for OTP process monitoring
  - Telemetry metrics for Phoenix/LiveView
  - Custom timing instrumentation around LLM calls
  - Chrome DevTools for frontend performance
- Could help optimize response times and identify scaling issues