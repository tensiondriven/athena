# Ash AI Reference for AshChat

## Key Questions This Answers

**Q: How does Ash AI handle "agents" vs "characters"?**
A: Ash AI uses prompt-backed actions and tool calling, but doesn't have built-in "character" or "persona" concepts. We need to build Agent Cards ourselves.

**Q: What's the context management story?**
A: Ash AI provides chat generation (`mix ash_ai.gen.chat`) with conversation persistence, but context assembly is manual. We need a plug-like context manager.

**Q: How do vectorization and tool calling work together?**
A: Vectorization is for semantic search over data. Tool calling exposes Ash actions to LLMs. They're separate - we could vector-search conversation history to build context for tools.

## Relevant Ash AI Features for Our Use Case

### Chat Generation (`mix ash_ai.gen.chat`)
- Generates LiveView chat with streaming (Phoenix PubSub)
- Conversation persistence (Ash + Oban)
- Tool calling integration
- **Missing**: Character/persona management, context assembly

### Prompt-Backed Actions
```elixir
action :analyze_sentiment do
  argument :text, :string
  returns :map  # structured output
  
  # Uses LLM to analyze and return structured data
end
```
**Key insight**: This is for LLM → structured data, not conversation management.

### Tool Definition
```elixir
# In your Ash resource
action :create_task do
  argument :title, :string
  # This action can be called by LLM as a tool
end
```
**Key insight**: Any Ash action can become an LLM tool.

### Vectorization
```elixir
ash_ai do
  vectorize text: :content,
           on: [:create, :update],
           store: MyApp.VectorStore
end
```
**Key insight**: Auto-embeds content for semantic search.

## What We Need to Build

### 1. Agent Cards Resource
```elixir
# Agent cards = character profiles
attributes do
  attribute :name, :string           # "Helpful Assistant"
  attribute :system_message, :string # Core personality prompt
  attribute :model_preferences, :map # temperature, etc.
  attribute :available_tools, :list  # which tools this agent can use
end
```

### 2. Context Manager (Plug-like)
```elixir
# Assembles context from multiple sources
defmodule ContextManager do
  def build_context(room, agent_card, opts \\ []) do
    []
    |> add_system_message(agent_card.system_message)
    |> add_conversation_history(room, opts[:history_limit])
    |> add_relevant_context(room, opts[:vector_search])
    |> add_room_metadata(room)
  end
end
```

### 3. Room Hierarchy
```elixir
# Rooms can have parent rooms for context inheritance
belongs_to :parent_room, AshChat.Resources.Room
has_many :child_rooms, AshChat.Resources.Room, destination_attribute: :parent_room_id
```

## Integration Points

**Agent Cards + Profiles**: Agent card selects which Profile (Ollama/OpenAI/Anthropic) to use
**Context Manager + Vectorization**: Use vectorized conversation history for relevant context
**Room Hierarchy + Context**: Child rooms inherit parent context
**Tool Calling + Agent Cards**: Each agent card defines available tools

## Next Steps
1. Build Agent Cards resource
2. Build Context Manager system  
3. Integrate with existing Profile system
4. Test with room hierarchy

---
*Focused on what we actually need to build, not exhaustive feature coverage*