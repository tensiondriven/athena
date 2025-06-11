#!/bin/bash
# Clean sensitive information from Claude logs before committing

LOGS_DIR="/Users/j/Code/athena/data/claude-logs/live"

echo "Cleaning Claude logs..."

# Backup original logs first
cp -r "$LOGS_DIR" "$LOGS_DIR.backup"

# Clean each log file
for file in "$LOGS_DIR"/*.jsonl; do
    if [ -f "$file" ]; then
        echo "Cleaning $(basename "$file")..."
        
        # Replace GitHub PAT tokens
        sed -i '' 's/github_pat_[A-Za-z0-9_]\{36,\}/REDACTED_GITHUB_TOKEN/g' "$file"
        
        # Replace Phoenix session cookies (more aggressive pattern)
        sed -i '' 's/SFMyNTY\.[A-Za-z0-9._+/=-]\{50,\}/REDACTED_PHOENIX_SESSION/g' "$file"
        
        # Replace Sentry keys
        sed -i '' 's/sentry_key=[a-f0-9]\{32\}/sentry_key=REDACTED/g' "$file"
        
        # Replace any remaining potential API keys (32+ char hex strings)
        sed -i '' 's/\b[a-f0-9]\{32,\}\b/REDACTED_KEY/g' "$file"
    fi
done

echo "Logs cleaned. Originals backed up to $LOGS_DIR.backup"