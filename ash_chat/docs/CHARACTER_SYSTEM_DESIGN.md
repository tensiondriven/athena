# Character System Design Reference

## Architecture Decision Summary

### Core Design: RPG Character Model
- **Character**: The complete "AI character" (like a D&D character sheet)
- **Role**: Functional capabilities (like character class - Wizard, Cleric, Fighter)  
- **Persona**: Behavioral traits (like alignment/background - Lawful Good, Chaotic Neutral)

### Data Strategy: ETS + Stubbed AshAI (Phase 1)
Following existing Message.ex pattern:
- **ETS DataLayer**: Fast iteration, no migrations needed
- **Stubbed vectorization**: Ready for Phase 3 Neo4j migration
- **JSON-LD export helpers**: Schema.org + athena: namespace ready

### Integration Points
- **Character ↔ Room**: Via future CharacterMembership (like RoomMembership)
- **Character ↔ ChatAgent**: Generate dynamic system prompts  
- **Character ↔ AshAI**: Tool calling + semantic search (when enabled)

## Implementation Plan

### Phase 1: Basic CRUD ✅ Current
1. Character/Role/Persona Ash resources (ETS storage)
2. Add to AshChat.Domain
3. LiveView CRUD interface  
4. Demo data with sample characters
5. Basic system prompt generation

### Phase 2: Chat Integration 
1. ChatAgent integration for character-based conversations
2. Room-specific character instances (CharacterMembership)
3. Character selection UI in chat interface
4. Dynamic prompt generation with room context

### Phase 3: Semantic Features
1. Enable AshAI vectorization (async with :ash_oban)
2. Semantic character search ("find characters like...")
3. Neo4j migration for graph relationships
4. Advanced character analytics

## Technical Patterns to Follow

### Resource Structure (Following existing patterns)
```elixir
defmodule Character do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets  # Like Message.ex
    
  # Stubbed AshAI (like Message.ex pattern)
  # ash_ai do
  #   vectorize text: [:description, :system_prompt_template],
  #            strategy: :ash_oban,  # Production-ready async
  #            store: AshChat.VectorStore
  # end
end
```

### Relationship Patterns (Following User ↔ RoomMembership)
```elixir
# Character blueprint
belongs_to :role, Role
belongs_to :persona, Persona

# Future: Character instances in rooms
# CharacterMembership: character_id, room_id, user_id, instance_config
```

### Action Design (Following existing conventions)
```elixir
actions do
  defaults [:read, :destroy]
  create :create do
    accept [:name, :description, :drive, :traits, :role_id, :persona_id]
  end
  
  # Business logic actions
  read :active do
    filter expr(is_active == true)
  end
end
```

### JSON-LD Export (Ready for Neo4j Phase 3)
```elixir
def to_json_ld(%Character{} = character) do
  %{
    "@context" => %{
      "schema" => "https://schema.org/",
      "athena" => "https://athena.local/vocab/"
    },
    "@type" => ["schema:Person", "athena:Character"],
    "schema:name" => character.name,
    "athena:drive" => character.drive,
    "athena:hasRole" => %{"@id" => "role_#{character.role_id}"}
  }
end
```

## Sample Character Roster

### Starting Characters (Demo Data)
1. **Helpful Alice** 
   - Role: Support Specialist  
   - Persona: Empathic Guide
   - Drive: "Help users succeed and feel supported"

2. **Direct Dave**
   - Role: Code Reviewer
   - Persona: Analytical Challenger  
   - Drive: "Improve code quality through direct feedback"

3. **Creative Casey**
   - Role: Brainstorm Facilitator
   - Persona: Energetic Innovator
   - Drive: "Generate novel solutions and inspire creativity"

4. **Wise Professor**
   - Role: Technical Educator
   - Persona: Patient Mentor
   - Drive: "Share deep understanding clearly and thoroughly"

## Next Actions
1. Update Character/Role/Persona resources to follow these patterns
2. Add to AshChat.Domain
3. Create migration (when ready to move to SQLite/PostgreSQL)
4. Build basic CRUD LiveView
5. Create demo data with sample character roster

---

*Design based on Ash 3.x best practices, AshAI production patterns, and existing AshChat codebase analysis*