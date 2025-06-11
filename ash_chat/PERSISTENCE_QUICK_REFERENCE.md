# Persistence Quick Reference

## Check What's Persisted
```bash
# See all tables
sqlite3 ash_chat.db ".tables"

# Count records
sqlite3 ash_chat.db "SELECT 'messages', COUNT(*) FROM messages UNION ALL SELECT 'rooms', COUNT(*) FROM rooms UNION ALL SELECT 'users', COUNT(*) FROM users UNION ALL SELECT 'agent_cards', COUNT(*) FROM agent_cards;"

# View recent messages
sqlite3 ash_chat.db "SELECT datetime(created_at), role, substr(content, 1, 50) FROM messages ORDER BY created_at DESC LIMIT 5;"

# View rooms
sqlite3 ash_chat.db "SELECT title, hidden, datetime(created_at) FROM rooms;"

# View users  
sqlite3 ash_chat.db "SELECT name, display_name, is_active FROM users;"

# View AI agents
sqlite3 ash_chat.db "SELECT name, substr(description, 1, 50) FROM agent_cards;"
```

## Test Persistence
```bash
# Check before/after demo data
./test_demo_persistence.sh

# In IEx, create test data
AshChat.Setup.reset_demo_data()

# Check again
./test_demo_persistence.sh
```

## SQLite Database
- **Location**: `ash_chat/ash_chat.db`
- **Created**: Automatically on first entity creation
- **Tables**: messages, rooms, users, agent_cards
- **No migrations needed**: Tables created on demand