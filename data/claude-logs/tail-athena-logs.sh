#!/bin/bash
# Tail athena claude logs in real-time

echo "=== Athena Claude Logs Monitor ==="
echo "Watching for new conversation events..."
echo ""

# Watch the sync log
echo "📋 Sync Activity:"
tail -f sync.log &
SYNC_PID=$!

# Watch for new JSONL entries in the current project
echo ""
echo "💬 Live Conversations:"
CURRENT_PROJECT="live/-Users-j-Code-athena"
if [ -d "$CURRENT_PROJECT" ]; then
    # Use tail -f on all JSONL files, showing new lines as they appear
    tail -f "$CURRENT_PROJECT"/*.jsonl 2>/dev/null | while read line; do
        # Pretty print JSON if jq is available
        if command -v jq &> /dev/null; then
            echo "$line" | jq -C '.'
        else
            echo "$line"
        fi
    done &
    CONV_PID=$!
else
    echo "No current project logs found yet"
fi

# Cleanup on exit
trap "kill $SYNC_PID $CONV_PID 2>/dev/null" EXIT

# Wait for interrupt
echo ""
echo "Press Ctrl+C to stop monitoring..."
wait