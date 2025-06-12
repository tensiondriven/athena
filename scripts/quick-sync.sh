#!/bin/bash
# Quick sync of chat logs with auto-generated commit message

echo "🚀 Quick sync starting..."

# Run the sync
./scripts/sync-chat-history.sh

# Check if anything was synced
if ! git diff --cached --name-only | grep -q "chat-history/"; then
    echo "ℹ️  Already up to date"
    exit 0
fi

# Count synced files
SYNCED=$(git diff --cached --name-only | grep "chat-history/" | wc -l | tr -d ' ')
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Commit immediately
git commit -m "Sync conversation logs - $TIMESTAMP

Auto-synced $SYNCED conversation log(s) to preserve chat history"

echo "✅ Synced and committed $SYNCED conversation(s)"
echo "💡 Run 'git push' when ready"