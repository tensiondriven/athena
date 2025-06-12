#!/bin/bash
# Sync chat logs and create a journal entry about the conversation

echo "=== Sync and Journal ==="
echo ""

# First, run the sync
echo "📂 Syncing conversation logs..."
./scripts/sync-chat-history.sh
echo ""

# Check if anything was synced
if ! git diff --cached --name-only | grep -q "chat-history/"; then
    echo "ℹ️  No new conversations to sync"
    exit 0
fi

# Get the synced files
SYNCED_FILES=$(git diff --cached --name-only | grep "chat-history/" | wc -l | tr -d ' ')
echo "📝 Creating journal entry for $SYNCED_FILES conversation(s)..."

# Create journal entry
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
JOURNAL_FILE="docs/journal/${DATE}-conversation-sync.md"

# If journal already exists for today, append
if [[ -f "$JOURNAL_FILE" ]]; then
    echo "" >> "$JOURNAL_FILE"
    echo "## Sync at $TIME" >> "$JOURNAL_FILE"
else
    cat > "$JOURNAL_FILE" << EOF
# Conversation Sync - $DATE

*Syncing chat logs that might not have been captured by normal commits*

## Sync at $TIME
EOF
fi

# Add entry about what was synced
echo "" >> "$JOURNAL_FILE"
echo "Synced $SYNCED_FILES conversation log(s)." >> "$JOURNAL_FILE"
echo "" >> "$JOURNAL_FILE"

# Open editor for manual notes (with timeout)
echo ""
echo "✏️  Add notes about the conversation (press Ctrl+D when done, or wait 30s to skip):"
echo ""

# Read user input with timeout
if command -v timeout >/dev/null 2>&1; then
    NOTES=$(timeout 30 cat)
else
    # Fallback for systems without timeout
    NOTES=$(perl -e 'alarm 30; $_ = <STDIN>; print' 2>/dev/null || echo "")
fi

if [[ -n "$NOTES" ]]; then
    echo "### Notes" >> "$JOURNAL_FILE"
    echo "" >> "$JOURNAL_FILE"
    echo "$NOTES" >> "$JOURNAL_FILE"
else
    echo "### Notes" >> "$JOURNAL_FILE"
    echo "" >> "$JOURNAL_FILE"
    echo "*No manual notes added*" >> "$JOURNAL_FILE"
fi

echo "" >> "$JOURNAL_FILE"
echo "---" >> "$JOURNAL_FILE"

# Stage the journal
git add "$JOURNAL_FILE"

# Show what will be committed
echo ""
echo "📋 Ready to commit:"
git diff --cached --name-only

# Commit with descriptive message
echo ""
echo "💾 Committing..."
git commit -m "Sync conversation logs with journal entry

- Synced $SYNCED_FILES conversation log(s)
- Added journal entry for context
- Ensures chat history is preserved even without code changes"

echo ""
echo "✅ Done! Conversation logs synced and journaled."
echo ""
echo "💡 Tip: Run 'git push' to share the synced conversations"