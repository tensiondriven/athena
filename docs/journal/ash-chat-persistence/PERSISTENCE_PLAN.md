# Chat Persistence Implementation Plan

## Overview
Add database persistence to ash_chat to preserve rooms, users, messages, and agent configurations across server restarts.

## Architectural Decision

### Option 1: Separate SQLite Database (Recommended for Phase 1)
**Pros:**
- Quick to implement
- Isolated from event system
- Clear domain boundaries
- Easy to migrate later

**Cons:**
- Two databases to manage
- Potential data sync issues

### Option 2: Unified Event-Based Storage (Future Consideration)
**Pros:**
- Single source of truth
- Messages become events in the event stream
- Unified querying across all data
- Natural audit trail

**Cons:**
- Requires significant refactoring
- Mixing concerns (chat vs events)
- Need to define event schemas for all chat entities

## Implementation Steps

### Phase 1: Add SQLite to ash_chat

1. **Add Dependencies**
```elixir
# mix.exs
{:ash_sqlite, "~> 0.1.3"},
{:ecto_sql, "~> 3.10"},
{:ecto_sqlite3, "~> 0.15"}
```

2. **Create Repo Module**
```elixir
defmodule AshChat.Repo do
  use AshSqlite.Repo,
    otp_app: :ash_chat
end
```

3. **Update Resources**
Convert each resource from ETS to SQLite:
- User
- Room  
- Message
- AgentCard
- AgentMembership
- RoomMembership
- Profile

4. **Create Migrations**
Generate migration files for each resource with proper indexes.

5. **Update Configuration**
Add database configuration to config files.

### Phase 2: Consider Event-Based Architecture

If we want messages as events:

```elixir
# Message becomes an event
%Event{
  type: "chat.message.created",
  source_id: "room:#{room_id}",
  actor_id: "user:#{user_id}",
  data: %{
    content: "Hello world",
    role: "user",
    metadata: %{}
  }
}
```

**Questions to Address:**
1. Are messages the canonical source or derived from events?
2. How do we handle message edits/deletes?
3. Do we duplicate data or use event sourcing patterns?
4. Performance implications of reconstructing chat from events?

## Recommendation

Start with **Option 1** (separate SQLite) because:
1. Faster to implement and test
2. Maintains current application structure
3. Can migrate to unified approach later
4. Allows us to evaluate event-based patterns without breaking current functionality

## Next Steps

1. Install dependencies
2. Create a simple SQLite repo
3. Migrate one resource (Message) as proof of concept
4. Test persistence across restarts
5. Migrate remaining resources
6. Add proper indexes for performance
7. Document the new persistence layer

Would you like me to proceed with implementing Option 1?