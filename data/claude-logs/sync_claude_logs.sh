#!/bin/bash
# Append-only sync of Claude conversation logs
# This script safely copies Claude logs without modifying originals

SOURCE_DIR="$HOME/.claude/projects"
DEST_DIR="/Users/j/Code/athena/data/claude-logs/live"
LOG_FILE="/Users/j/Code/athena/data/claude-logs/sync.log"

# Create destination if it doesn't exist
mkdir -p "$DEST_DIR"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Start sync
log "Starting Claude logs sync from $SOURCE_DIR to $DEST_DIR"

# Use rsync with append-only options
# --append: append to files, don't overwrite
# --append-verify: like --append but verify the data
# --recursive: recurse into directories
# --times: preserve modification times
# --verbose: increase verbosity
# --itemize-changes: output change summary
rsync -rtvi --append-verify "$SOURCE_DIR/" "$DEST_DIR/" 2>&1 | while read line; do
    if [[ -n "$line" ]]; then
        log "$line"
    fi
done

log "Sync completed"

# Git commits removed - sync only, no version control noise