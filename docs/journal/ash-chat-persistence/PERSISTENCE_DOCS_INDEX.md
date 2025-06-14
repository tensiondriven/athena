# Persistence Documentation Index

## Implementation Guides
- [PERSISTENCE_PLAN.md](PERSISTENCE_PLAN.md) - Original implementation plan
- [PERSISTENCE_SUMMARY.md](PERSISTENCE_SUMMARY.md) - Technical implementation details
- [MINIMAL_PERSISTENCE_NOTES.md](MINIMAL_PERSISTENCE_NOTES.md) - Philosophy and design decisions

## Usage Documentation
- [PERSISTENCE_QUICK_REFERENCE.md](PERSISTENCE_QUICK_REFERENCE.md) - SQLite queries and commands
- [test_demo_persistence.sh](test_demo_persistence.sh) - Test script for demo data
- [verify_persistence.exs](verify_persistence.exs) - Verification script

## Meta Documentation
- [PERSISTENCE_LESSONS_LEARNED.md](PERSISTENCE_LESSONS_LEARNED.md) - What worked and challenges
- [SESSION_SUMMARY.md](SESSION_SUMMARY.md) - 50-turn implementation summary
- [CONVERSATION_ARCHAEOLOGY_EXAMPLE.md](CONVERSATION_ARCHAEOLOGY_EXAMPLE.md) - Tracing decisions

## Code Changes
Modified files:
- `lib/ash_chat/resources/message.ex` - Message persistence
- `lib/ash_chat/resources/room.ex` - Room persistence
- `lib/ash_chat/resources/user.ex` - User persistence
- `lib/ash_chat/resources/agent_card.ex` - AgentCard persistence
- `mix.exs` - Added exqlite dependency

## Database
- **Location**: `ash_chat.db`
- **Tables**: messages, rooms, users, agent_cards
- **Created**: On first entity creation