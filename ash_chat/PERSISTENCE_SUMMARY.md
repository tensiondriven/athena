# Minimal SQLite Persistence Implementation

## Overview
Added minimal SQLite persistence to ash_chat for conversation data collection, following the "small sharp tools, high agility" principle.

## Implementation Details

### 1. Message Persistence
- **File**: `lib/ash_chat/resources/message.ex`
- **Hook**: Added to `create_text_message` action
- **Fields**: id, room_id, user_id, content, role, created_at
- **Status**: ✅ Implemented and tested

### 2. Room Persistence  
- **File**: `lib/ash_chat/resources/room.ex`
- **Hook**: Added to `create` action
- **Fields**: id, title, parent_room_id, starting_message, hidden, created_at
- **Status**: ✅ Implemented

### 3. User Persistence
- **File**: `lib/ash_chat/resources/user.ex`
- **Hook**: Added to `create` action
- **Fields**: id, name, email, display_name, avatar_url, preferences (JSON), is_active, created_at
- **Status**: ✅ Implemented

### 4. AgentCard Persistence
- **File**: `lib/ash_chat/resources/agent_card.ex`
- **Hook**: Added to `create` action
- **Fields**: id, name, description, system_message, model_preferences (JSON), available_tools (JSON), context_settings (JSON), avatar_url, is_default, add_to_new_rooms, default_profile_id, created_at
- **Status**: ✅ Implemented

## Technical Decisions

1. **Async Persistence**: Used `Task.start` to avoid blocking the main flow
2. **Silent Failures**: If DB is unavailable, chat continues to work (in-memory ETS)
3. **Simple SQLite**: Direct usage via exqlite, no ORM or complex abstractions
4. **JSON Storage**: Complex fields (preferences, settings) stored as JSON strings
5. **Minimal Scope**: Only persist on create, not updates or deletes

## Database Location
- **Path**: `ash_chat/ash_chat.db`
- **Tables**: Created lazily when first entity of each type is created

## Testing
```bash
# Check database
sqlite3 ash_chat.db ".tables"

# Check messages
sqlite3 ash_chat.db "SELECT * FROM messages;"

# Run verification script (requires app context)
cd ash_chat && iex -S mix
c("verify_persistence.exs")
```

## Next Steps (Not Implemented)
- Persist relationship tables (room_memberships, agent_memberships)
- Add update/delete persistence hooks
- Consider event-based architecture for persistence
- Migration to proper Ash data layer if needed

## Philosophy
This implementation follows the project's "small sharp tools" philosophy - minimal code that does one thing well (persist chat data) without over-engineering or creating comprehensive solutions.