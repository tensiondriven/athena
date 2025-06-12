#!/bin/bash
# Sync Claude Code chat logs to chat-history with redaction
# This script should be called from pre-commit hook

CLAUDE_DIR="$HOME/.claude/projects/-Users-j-Code-athena"
CHAT_HISTORY_DIR="./chat-history"

echo "Syncing Claude Code conversation logs..."

# Ensure directories exist
mkdir -p "$CHAT_HISTORY_DIR"

# Count synced files
synced=0

# Inline redaction function - comprehensive pattern matching
redact_secrets() {
    sed -E \
        -e 's/github_pat_[A-Za-z0-9_]+/REDACTED_GITHUB_TOKEN/g' \
        -e 's/ghp_[A-Za-z0-9]{36}/REDACTED_GITHUB_TOKEN/g' \
        -e 's/ghs_[A-Za-z0-9]{36}/REDACTED_GITHUB_SECRET/g' \
        -e 's/sk-or-v1-[A-Za-z0-9]+/REDACTED_OPENROUTER_KEY/g' \
        -e 's/sk-ant-[A-Za-z0-9_-]+/REDACTED_ANTHROPIC_KEY/g' \
        -e 's/sentry_key=[A-Za-z0-9]+/sentry_key=REDACTED/g' \
        -e 's/SFMyNTY\.[A-Za-z0-9\._-]+/REDACTED_PHOENIX_SESSION/g' \
        -e 's/"api_key":\s*"[^"]+"/\"api_key\": \"REDACTED\"/g' \
        -e 's/"openrouter_key":\s*"[^"]+"/\"openrouter_key\": \"REDACTED\"/g' \
        -e 's/"token":\s*"[^"]+"/\"token\": \"REDACTED\"/g' \
        -e 's/"password":\s*"[^"]+"/\"password\": \"REDACTED\"/g' \
        -e 's/"secret":\s*"[^"]+"/\"secret\": \"REDACTED\"/g' \
        -e 's/([A-Z][A-Z0-9_]*_KEY)=([^ ]+)/\1=REDACTED/g' \
        -e 's/([A-Z][A-Z0-9_]*_TOKEN)=([^ ]+)/\1=REDACTED/g' \
        -e 's/([A-Z][A-Z0-9_]*_SECRET)=([^ ]+)/\1=REDACTED/g' \
        -e 's/([A-Z][A-Z0-9_]*_PASSWORD)=([^ ]+)/\1=REDACTED/g' \
        -e 's/(OPENROUTER_[A-Z0-9_]+)=([^ ]+)/\1=REDACTED/g' \
        -e 's/([A-Z][A-Z0-9_]+_API_KEY)=([^ ]+)/\1=REDACTED/g'
}

# Copy new or modified files with redaction
for file in "$CLAUDE_DIR"/*.jsonl; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        dest="$CHAT_HISTORY_DIR/$filename"
        
        # Check if file needs updating
        if [[ ! -f "$dest" ]] || [[ "$file" -nt "$dest" ]]; then
            # Copy with redaction
            redact_secrets < "$file" > "$dest"
            
            # Stage the file - pre-commit will run gitleaks as final check
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

# Let pre-commit hook handle the final gitleaks check
# This eliminates duplicate warnings and confusing output