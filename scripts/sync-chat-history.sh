#!/bin/bash
# Sync Claude Code chat logs to chat-history with redaction
# This script should be called from pre-commit hook

CLAUDE_DIR="$HOME/.claude/projects/-Users-j-Code-athena"
CHAT_HISTORY_DIR="./chat-history"

echo "Syncing Claude Code conversation logs..."

# Ensure directories exist
mkdir -p "$CHAT_HISTORY_DIR"

# Count synced files and failures
synced=0
failed=0

# Inline redaction function
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
        -e 's/([A-Z][A-Z0-9_]+_API_KEY)=([^ ]+)/\1=REDACTED/g' \
        -e 's/([A-Z][A-Z0-9_]{3,})=([^ ]+)/\1=REDACTED_POSSIBLE_SECRET/g'
}

# Copy new or modified files with redaction
for file in "$CLAUDE_DIR"/*.jsonl; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        dest="$CHAT_HISTORY_DIR/$filename"
        
        # Check if file needs updating
        if [[ ! -f "$dest" ]] || [[ "$file" -nt "$dest" ]]; then
            # Get file info for error reporting
            file_size=$(ls -lh "$file" | awk '{print $5}')
            file_date=$(ls -lh "$file" | awk '{print $6, $7, $8}')
            
            # Copy with redaction
            redact_secrets < "$file" > "$dest.tmp"
            
            # Use gitleaks to check if any real secrets remain
            if gitleaks detect --no-git -s "$dest.tmp" 2>&1 | grep -q "leaks found"; then
                echo "  ⚠️  Gitleaks detected secrets in: $filename"
                echo "     File size: $file_size, Last modified: $file_date"
                echo "     Running additional redaction..."
                
                # Get the specific secrets gitleaks found
                gitleaks detect --no-git -s "$dest.tmp" --report-format json --report-path "$dest.leak" 2>/dev/null || true
                
                # If we have findings, show them
                if [[ -f "$dest.leak" ]]; then
                    echo "     Secrets found by gitleaks:"
                    # Parse JSON to show secret types
                    jq -r '.[] | "       - \(.RuleID): \(.Secret[0:20])..."' "$dest.leak" 2>/dev/null | head -5 || true
                    rm "$dest.leak"
                fi
                
                # Apply more aggressive redaction based on what gitleaks typically finds
                sed -i.bak -E \
                    -e 's/sk-[a-zA-Z0-9_-]{20,}/REDACTED_API_KEY/g' \
                    -e 's/[a-zA-Z0-9_-]{32,}/REDACTED_LONG_TOKEN/g' \
                    "$dest.tmp"
                
                # Check again
                if gitleaks detect --no-git -s "$dest.tmp" 2>&1 | grep -q "leaks found"; then
                    echo "     ❌ Still contains secrets after additional redaction"
                    rm "$dest.tmp" "$dest.tmp.bak" 2>/dev/null
                    ((failed++))
                else
                    echo "     ✅ Additional redaction successful"
                    rm "$dest.tmp.bak"
                    mv "$dest.tmp" "$dest"
                    git add "$dest"
                    ((synced++))
                fi
            else
                mv "$dest.tmp" "$dest"
                # Stage the file for commit
                git add "$dest"
                ((synced++))
                echo "  ✓ Synced: $filename"
            fi
        fi
    fi
done

if [[ $failed -gt 0 ]]; then
    echo ""
    echo "⚠️  Failed to redact secrets from $failed file(s)!"
    echo "Please update the redaction patterns in this script."
    exit 1
fi

if [[ $synced -gt 0 ]]; then
    echo "Synced $synced conversation log(s) with redaction"
else
    echo "No new conversation logs to sync"
fi
