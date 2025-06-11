#!/bin/bash
# Sync Claude Code chat logs to chat-history with redaction
# This script should be called from pre-commit hook

CLAUDE_DIR="$HOME/.claude/projects/-Users-j-Code-athena"
CHAT_HISTORY_DIR="./chat-history"
REDACT_SCRIPT="./scripts/redact-secrets.sh"

echo "Syncing Claude Code conversation logs..."

# Ensure directories exist
mkdir -p "$CHAT_HISTORY_DIR"

# Count synced files
synced=0

# Copy new or modified files with redaction
for file in "$CLAUDE_DIR"/*.jsonl; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        dest="$CHAT_HISTORY_DIR/$filename"
        
        # Check if file needs updating
        if [[ ! -f "$dest" ]] || [[ "$file" -nt "$dest" ]]; then
            # Copy with redaction
            if [[ -x "$REDACT_SCRIPT" ]]; then
                "$REDACT_SCRIPT" < "$file" > "$dest"
            else
                # Fallback: copy with inline redaction
                sed -E \
                    -e 's/github_pat_[A-Za-z0-9_]{82}/REDACTED_GITHUB_TOKEN/g' \
                    -e 's/ghp_[A-Za-z0-9]{36}/REDACTED_GITHUB_TOKEN/g' \
                    -e 's/ghs_[A-Za-z0-9]{36}/REDACTED_GITHUB_SECRET/g' \
                    "$file" > "$dest"
            fi
            
            # Stage the file for commit
            git add "$dest"
            ((synced++))
            echo "  ✓ Synced: $filename"
        fi
    fi
done

if [[ $synced -gt 0 ]]; then
    echo "Synced $synced conversation log(s) with redaction"
else
    echo "No new conversation logs to sync"
fi