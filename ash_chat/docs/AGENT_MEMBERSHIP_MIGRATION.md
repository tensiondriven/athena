# Agent Membership Architecture Migration

## Challenge: One Agent Per Room → Agents as Room Members

### Problem Identified
- **Current**: `Room.agent_card_id` - each room "belongs to" one agent (broken architecture)
- **Needed**: Agents should be **members** of rooms, just like users
- **Architecture**: Channels/Rooms can have multiple agents participating

### Solution Design
1. **Remove `agent_card_id`** from Room resource
2. **Create `AgentMembership`** resource (similar to `RoomMembership`)
3. **Add `add_to_new_rooms` flag** to AgentCard for default agents
4. **Auto-join logic** when creating new rooms

## Implementation Progress

### Turn 1: Core Architecture ✅
- ✅ Created `AgentMembership` resource with proper relationships
- ✅ Added `add_to_new_rooms` flag to `AgentCard`
- ✅ Removed `agent_card_id` from `Room`
- ✅ Added `AgentMembership` to domain
- ✅ Updated relationships: Room ↔ AgentCard via AgentMembership

### Challenges Encountered

#### Turn 1 Issues:
- **Relationship complexity**: Many-to-many through join table requires careful setup
- **Breaking change**: Existing demo data will need migration
- **UI dependencies**: LiveView currently expects `room.agent_card_id`
- **GitHub secrets**: Push blocked due to token in chat-history files (needs cleanup)
- **Atomic actions**: Had to add `require_atomic? false` to toggle_auto_respond

### Turn 2: Update ChatAgent to handle multiple agents ✅
- ✅ Updated `create_room()` to auto-add agents with `add_to_new_rooms` flag
- ✅ Fixed `get_agent_card_for_room()` to use AgentMembership instead of room.agent_card_id
- ✅ Added `add_default_agents_to_room()` function for auto-joining logic
- ✅ Updated agent card creation to set `add_to_new_rooms: true` for defaults

### Turn 3: Update demo data for new architecture ✅
- ✅ Added `add_to_new_rooms: true` to helpful_assistant in demo data
- ✅ Removed `agent_card_id` from Room.create! calls in setup
- ✅ Added AgentMembership import and cleanup in reset_demo_data
- ✅ Created AgentMembership records for all demo rooms
- ✅ Set up multi-agent example: General Chat has both Helpful Assistant (auto) and Research Assistant (manual)

### Next Steps
- Turn 4: Update UI to show agent members instead of single agent
- Turn 5: Update demo data and test full integration

#### Turn 2 Issues:
- **Preloading needed**: May need to preload AgentMembership relationships for efficiency
- **Multiple agents**: Currently only uses first auto-responder - may need smarter selection logic

## Technical Notes
- `AgentMembership.auto_respond` controls which agents respond automatically
- `AgentCard.add_to_new_rooms` flags which agents join new rooms by default
- Maintains backward compatibility patterns from `RoomMembership`