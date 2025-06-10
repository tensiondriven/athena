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

### Next Steps
- Turn 2: Update ChatAgent to handle multiple agents per room
- Turn 3: Fix room creation to auto-add default agents  
- Turn 4: Update UI to show agent members instead of single agent
- Turn 5: Update demo data and test full integration

## Technical Notes
- `AgentMembership.auto_respond` controls which agents respond automatically
- `AgentCard.add_to_new_rooms` flags which agents join new rooms by default
- Maintains backward compatibility patterns from `RoomMembership`