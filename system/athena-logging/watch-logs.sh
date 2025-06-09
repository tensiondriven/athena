#!/bin/bash
# Athena Log Viewer - Watch all centralized logs

ATHENA_LOG_DIR="${ATHENA_LOG_DIR:-/Users/j/Code/athena/logs}"
LOG_FILE="$ATHENA_LOG_DIR/athena.log"

echo "🔍 Watching Athena logs at: $LOG_FILE"
echo "Press Ctrl+C to exit"
echo "----------------------------------------"

# Create log file if it doesn't exist
mkdir -p "$ATHENA_LOG_DIR"
touch "$LOG_FILE"

# Tail the log file with color coding
tail -f "$LOG_FILE" | while read -r line; do
    case "$line" in
        *"[ERROR]"*) echo -e "\033[31m$line\033[0m" ;;  # Red
        *"[WARN]"*)  echo -e "\033[33m$line\033[0m" ;;  # Yellow  
        *"[INFO]"*)  echo -e "\033[32m$line\033[0m" ;;  # Green
        *"[DEBUG]"*) echo -e "\033[36m$line\033[0m" ;;  # Cyan
        *)           echo "$line" ;;
    esac
done