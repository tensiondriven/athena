# Companion Model Migration Plan

## Overview

We're consolidating the fragmented Persona + SystemPrompt + AgentCard model into a single, unified `Companion` entity that better represents the diverse types of chat participants in Athena.

## Why "Companion"?

- Avoids conflict with Ash Framework's "agent" concepts
- Better represents the variety of participants: AI assistants, simulated people, experts, friends
- More human-centered naming that aligns with the conversational nature of the system

## Model Comparison

### Old Model (3 entities)
```
Persona (backend config) → SystemPrompt (personality) → AgentCard (chat settings)
```

Problems:
- Confusing 3-hop relationship
- Unclear separation of concerns
- Difficult to duplicate/version
- Hard to understand what belongs where

### New Model (1 entity)
```
Companion (everything in one place)
```

Benefits:
- Single source of truth
- Clear versioning story
- Easy duplication
- Intuitive for users

## Key Features of Companion Model

### 1. Companion Types
- `:assistant` - AI helpers like Maya
- `:expert` - Domain specialists like Coda
- `:employee` - Simulated coworkers
- `:friend` - Casual conversation partners
- `:character` - Fictional personas
- `:visitor` - Temporary participants
- `:guest` - External participants

### 2. Rich Metadata
- **Tags**: For grouping/filtering (e.g., "technical", "friendly")
- **Capabilities**: What they can do (e.g., `:memory`, `:code_execution`)
- **Response Style**: How they communicate (formality, verbosity, emoji use)
- **Personality Notes**: Free-form backstory and traits

### 3. Flexible Context Strategies
- `:consolidated` - Everything in one user message (token-efficient)
- `:message_per_message` - Traditional OpenAI style
- `:claude_style` - Human/Assistant format

### 4. Provider Abstraction
- Clean provider behavior pattern
- Backend-specific implementations
- Easy to add new providers

## Migration Steps

### Phase 1: Parallel Running
1. Keep old entities for backward compatibility
2. Create new Companion entity
3. Update UI to show both
4. Test companion creation/editing

### Phase 2: Data Migration
```elixir
# Migration script
def migrate_to_companions do
  AgentCard.read!()
  |> Ash.load!([:system_prompt, :persona])
  |> Enum.map(&create_companion_from_agent_card/1)
end
```

### Phase 3: UI Cutover
1. Update ProfilesLive to use Companions
2. Update ChatLive to use Companions
3. Remove old UI code

### Phase 4: Cleanup
1. Remove old resources
2. Update all references
3. Clean up domain model

## Configuration Management

All companions now defined in `config/companions.yaml`:
- Keeps LLM instructions out of code
- Easy to version control
- Clear separation of config vs logic
- Environment variable support

## UI Updates Needed

1. **Settings Page**
   - Show companions grouped by type
   - Add filtering by tags
   - Show capabilities as badges
   - Quick duplicate button

2. **Chat Page**
   - Companion selector with avatars
   - Show companion type and description
   - Indicate capabilities in UI

3. **New Features**
   - Companion gallery/marketplace
   - Import/export companions
   - Share companion configurations

## Breaking Changes

1. `agent_card_id` → `companion_id` in messages
2. `AgentMembership` → `CompanionMembership` 
3. API endpoints change from `/agent_cards` to `/companions`

## Benefits Summary

1. **Simpler Mental Model**: One entity to understand
2. **Better UX**: Users think in terms of "who" not "what backend"
3. **Extensibility**: Easy to add new companion types and capabilities
4. **Maintainability**: Less code, clearer relationships
5. **Human-Centered**: Focuses on conversation partners, not technical details

## Next Steps

1. [ ] Test Companion CRUD operations
2. [ ] Build migration script
3. [ ] Update UI components
4. [ ] Update documentation
5. [ ] Plan deprecation timeline
6. [ ] Communicate changes to users

---

*This migration represents a shift from infrastructure-focused modeling to human-centered design, making Athena more intuitive and powerful.*