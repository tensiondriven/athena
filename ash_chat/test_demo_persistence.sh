#!/bin/bash
# Test if demo data creation triggers persistence

echo "=== Testing Demo Data Persistence ==="
echo

# Check initial state
echo "Initial database state:"
if [ -f ash_chat.db ]; then
    for table in messages rooms users agent_cards; do
        count=$(sqlite3 ash_chat.db "SELECT COUNT(*) FROM $table 2>/dev/null" 2>/dev/null || echo "0")
        echo "  $table: $count records"
    done
else
    echo "  No database exists yet"
fi

echo
echo "To test persistence:"
echo "1. In one terminal: cd ash_chat && iex -S mix"
echo "2. Run: AshChat.Setup.reset_demo_data()"
echo "3. Run this script again to see if data was persisted"
echo
echo "Expected results:"
echo "  - rooms table should have entries (Tech Talk, Conversation Lounge, Random)"
echo "  - users table should have entries (Alice, Bob, Charlie)"
echo "  - agent_cards table should have entries (Sam, Maya)"