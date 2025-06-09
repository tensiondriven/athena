#!/bin/bash
# Athena macOS File Event Collector - Shell Edition
# Monitors Claude logs and other directories using fswatch
# Writes events directly to SQLite database

set -e

# Configuration
DATA_DIR="${ATHENA_DATA_DIR:-$PWD/data}"
DB_PATH="$DATA_DIR/collector.sqlite"
FILES_DIR="$DATA_DIR/files"

# Watch paths - Updated to monitor active Claude conversations
CLAUDE_ACTIVE_DIR="$HOME/.claude/projects/-Users-j-Code-athena"
CLAUDE_CODE_LOGS_DIR="$HOME/.claude-code/logs"
DESKTOP_DIR="$HOME/Desktop"
DOWNLOADS_DIR="$HOME/Downloads"

# Phoenix app endpoint for sending events
PHOENIX_ENDPOINT="${PHOENIX_ENDPOINT:-http://localhost:4000/api/events}"

# Ensure directories exist
mkdir -p "$DATA_DIR" "$FILES_DIR"

# Initialize database if it doesn't exist
init_database() {
    if [[ ! -f "$DB_PATH" ]]; then
        sqlite3 "$DB_PATH" "
        CREATE TABLE file_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            event_type TEXT NOT NULL,
            source_path TEXT NOT NULL,
            file_hash TEXT,
            file_size INTEGER,
            mime_type TEXT,
            metadata TEXT,
            stored_path TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX idx_timestamp ON file_events(timestamp);
        CREATE INDEX idx_event_type ON file_events(event_type);
        "
    fi
}

# Calculate file hash
get_file_hash() {
    local file="$1"
    if [[ -f "$file" ]]; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        echo ""
    fi
}

# Store file content and return stored path
store_file() {
    local file="$1"
    local hash="$2"
    
    if [[ -f "$file" && -s "$file" ]]; then
        local ext="${file##*.}"
        local stored_path="$FILES_DIR/${hash}"
        
        # Add extension for JSONL files
        if [[ "$ext" == "jsonl" ]]; then
            stored_path="${stored_path}.jsonl"
        fi
        
        cp "$file" "$stored_path" 2>/dev/null || true
        echo "$stored_path"
    else
        echo ""
    fi
}

# Record event in database
record_event() {
    local event_type="$1"
    local source_path="$2"
    local metadata="${3:-}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    local file_hash=""
    local file_size=""
    local mime_type=""
    local stored_path=""
    
    if [[ -f "$source_path" ]]; then
        file_hash=$(get_file_hash "$source_path")
        file_size=$(stat -f%z "$source_path" 2>/dev/null || echo "")
        mime_type=$(file --mime-type -b "$source_path" 2>/dev/null || echo "")
        
        # Store file if it's a JSONL
        if [[ "$source_path" == *.jsonl ]]; then
            stored_path=$(store_file "$source_path" "$file_hash")
            if [[ -n "$stored_path" ]]; then
                stored_path="${stored_path#$DATA_DIR/}"
            fi
        fi
    fi
    
    # Escape single quotes for SQL
    local escaped_path="${source_path//\'/\'\'}"
    local escaped_metadata="${metadata//\'/\'\'}"
    local escaped_stored="${stored_path//\'/\'\'}"
    
    sqlite3 "$DB_PATH" "
    INSERT INTO file_events (timestamp, event_type, source_path, file_hash, file_size, mime_type, metadata, stored_path)
    VALUES ('$timestamp', '$event_type', '$escaped_path', '$file_hash', '$file_size', '$mime_type', '$escaped_metadata', '$escaped_stored');
    "
    
    echo "$(date): $event_type - $source_path"
}

# Send event to Phoenix app
send_to_phoenix() {
    local event_type="$1"
    local source_path="$2"
    local content="$3"
    local metadata="${4:-}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    
    # Create JSON payload with proper inspector fields
    local file_size=${#content}
    local description="File modified: $(basename "$source_path") (${file_size} chars)"
    
    if [[ "$event_type" == "claude_code.conversation.updated" ]]; then
        description="Claude Code conversation updated: $(basename "$source_path") (${file_size} chars)"
    elif [[ "$event_type" == "filesystem.file.modified" ]]; then
        description="File system change: $(basename "$source_path") (${file_size} chars)"
    fi
    
    local json_payload=$(cat <<EOF
{
  "timestamp": "$timestamp",
  "type": "$event_type",
  "source_id": "claude-collector-shell",
  "source_path": "$source_path",
  "description": "$description",
  "content": $(echo "$content" | jq -Rs .),
  "metadata": $metadata
}
EOF
)
    
    # Send to Phoenix (non-blocking)
    curl -s -X POST "$PHOENIX_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d "$json_payload" &
}

# Send startup event
send_startup() {
    record_event "collector_startup" "athena-collector-shell" "{\"version\": \"2.0.0\", \"pid\": $$}"
}

# Send heartbeat every 5 minutes
send_heartbeat() {
    while true; do
        sleep 300
        local uptime_minutes=$(( ($(date +%s) - start_time) / 60 ))
        record_event "heartbeat" "athena-collector-shell" "{\"uptime_minutes\": $uptime_minutes}"
    done
}

# Process fswatch output
process_events() {
    while read -r line; do
        if [[ -n "$line" ]]; then
            # Determine event type based on file state
            if [[ -f "$line" ]]; then
                # Check file size (1MB = 1048576 bytes)
                local file_size=$(stat -f%z "$line" 2>/dev/null || echo "0")
                local file_content=""
                
                if [[ "$line" == *.jsonl ]]; then
                    # For JSONL files, send whole file content to Phoenix
                    file_content=$(cat "$line" 2>/dev/null || echo "")
                    local filename=$(basename "$line")
                    record_event "modified" "$line" "{\"source_type\": \"claude_log\", \"filename\": \"$filename\"}"
                    send_to_phoenix "claude_code.conversation.updated" "$line" "$file_content" "{\"source_type\": \"claude_code_jsonl\", \"filename\": \"$filename\"}"
                elif [[ $file_size -lt 1048576 ]]; then
                    # For small files (<1MB), include content
                    file_content=$(cat "$line" 2>/dev/null || echo "")
                    send_to_phoenix "filesystem.file.modified" "$line" "$file_content" "{\"source_type\": \"filesystem\", \"file_size\": $file_size}"
                else
                    # For large files, just record the event without content
                    record_event "modified" "$line" "{\"file_size\": $file_size}"
                fi
            else
                record_event "deleted" "$line"
            fi
        fi
    done
}

# Cleanup function
cleanup() {
    echo "$(date): Shutting down collector..."
    kill $heartbeat_pid 2>/dev/null || true
    kill $fswatch_pid 2>/dev/null || true
    exit 0
}

# Main execution
main() {
    echo "Starting Athena macOS File Event Collector (Shell Edition)"
    echo "Database: $DB_PATH"
    echo "Monitoring: $CLAUDE_ACTIVE_DIR, $CLAUDE_CODE_LOGS_DIR, $DESKTOP_DIR, $DOWNLOADS_DIR"
    
    # Check if fswatch is available
    if ! command -v fswatch >/dev/null 2>&1; then
        echo "Error: fswatch not found. Install with: brew install fswatch"
        exit 1
    fi
    
    # Initialize
    init_database
    start_time=$(date +%s)
    send_startup
    
    # Set up signal handlers
    trap cleanup SIGTERM SIGINT
    
    # Start heartbeat in background
    send_heartbeat &
    heartbeat_pid=$!
    
    # Start monitoring - prioritize active Claude conversations
    fswatch -r "$CLAUDE_ACTIVE_DIR" "$CLAUDE_CODE_LOGS_DIR" "$DESKTOP_DIR" "$DOWNLOADS_DIR" | process_events &
    fswatch_pid=$!
    
    # Wait for fswatch to exit
    wait $fswatch_pid
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi