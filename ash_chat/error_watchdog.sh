#!/bin/bash

# Simple error log watchdog that notifies Claude Code
# 
# USAGE:
#   ./error_watchdog.sh           - Start continuous monitoring
#   ./error_watchdog.sh --once    - Check once and exit
#   ./error_watchdog.sh --help    - Show this help
#
# The watchdog monitors tmp/error.log for new errors and sends notifications
# to the active Claude Code session via AppleScript when errors are detected.

# Check for help flag first
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Error Watchdog - Monitor error.log and notify Claude Code"
    echo ""
    echo "USAGE:"
    echo "  $0              Start continuous monitoring (default)"
    echo "  $0 --once       Check once and exit"
    echo "  $0 --disable    Disable error notifications"
    echo "  $0 --enable     Enable error notifications"
    echo "  $0 --status     Check if notifications are enabled"
    echo "  $0 --help       Show this help"
    echo ""
    echo "DESCRIPTION:"
    echo "  Monitors tmp/error.log for new errors and automatically sends"
    echo "  notifications to the Claude Code session in iTerm when errors"
    echo "  are detected. Also checks for running Ollama models and updates"
    echo "  room current_model accordingly. Notifications include error context"
    echo "  like module and line numbers when available."
    echo ""
    echo "  The watchdog can be disabled by creating a lockfile (watchdog_disabled.lock)"
    echo "  in the current directory. Use --disable and --enable commands to manage this."
    echo ""
    echo "EXAMPLES:"
    echo "  $0              # Start watching in background"
    echo "  $0 --once       # Check current log once"
    echo "  $0 --disable    # Disable notifications"
    echo "  $0 --enable     # Re-enable notifications"
    echo ""
    echo "RATE LIMITING:"
    echo "  Max ${MAX_NOTIFICATIONS_PER_MINUTE} notifications per minute"
    echo "  Duplicate messages blocked for ${DUPLICATE_WINDOW} seconds"
    echo ""
    exit 0
fi

ERROR_LOG="tmp/error.log"
LAST_LINE_FILE=".error_watchdog_last"
RECENT_MESSAGES_FILE=".error_watchdog_recent"
LOCKFILE="watchdog_disabled.lock"
MAX_NOTIFICATIONS_PER_MINUTE=5
DUPLICATE_WINDOW=30  # seconds
OLLAMA_API_URL="http://localhost:11434"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Handle command line arguments
if [[ "$1" == "--disable" ]]; then
    touch "$LOCKFILE"
    echo -e "${YELLOW}🔒 Error watchdog disabled${NC}"
    echo "Lockfile created: $LOCKFILE"
    exit 0
elif [[ "$1" == "--enable" ]]; then
    if [ -f "$LOCKFILE" ]; then
        rm "$LOCKFILE"
        echo -e "${GREEN}🔓 Error watchdog enabled${NC}"
        echo "Lockfile removed: $LOCKFILE"
    else
        echo -e "${GREEN}✅ Error watchdog is already enabled${NC}"
    fi
    exit 0
elif [[ "$1" == "--status" ]]; then
    if [ -f "$LOCKFILE" ]; then
        echo -e "${YELLOW}🔒 Error watchdog is DISABLED${NC}"
        echo "Lockfile exists: $LOCKFILE"
    else
        echo -e "${GREEN}🔓 Error watchdog is ENABLED${NC}"
        echo "No lockfile found"
    fi
    exit 0
fi

# Parse command line arguments
ONCE_MODE=false
if [[ "$1" == "--once" ]]; then
    ONCE_MODE=true
fi

# Default behavior - show usage if no args
if [[ $# -eq 0 ]]; then
    echo "Error Watchdog - Monitor error.log and notify Claude Code"
    echo ""
    echo "USAGE:"
    echo "  $0              Start continuous monitoring"
    echo "  $0 --once       Check once and exit"
    echo "  $0 --help       Show help"
    echo ""
    echo "PROTECTION: Max $MAX_NOTIFICATIONS_PER_MINUTE/min, ${DUPLICATE_WINDOW}s duplicate blocking"
    echo "Starting continuous monitoring... (use --help for more options)"
    echo ""
fi

if [[ "$ONCE_MODE" == "false" ]]; then
    echo -e "${GREEN}🔍 Error Watchdog Started${NC}"
    echo -e "Monitoring: ${ERROR_LOG}"
    echo -e "Press Ctrl+C to stop\n"
else
    echo -e "${GREEN}🔍 Error Watchdog - One-time Check${NC}"
fi

# Function to clean old entries and check rate limits
clean_and_check_rate_limit() {
    local current_time=$(date +%s)
    local one_minute_ago=$((current_time - 60))
    local cutoff_time=$((current_time - DUPLICATE_WINDOW))
    
    if [ -f "$RECENT_MESSAGES_FILE" ]; then
        # Clean old entries (keep entries newer than max of rate limit and duplicate windows)
        local keep_time=$one_minute_ago
        if [ "$cutoff_time" -lt "$one_minute_ago" ]; then
            keep_time=$cutoff_time
        fi
        
        # Filter to keep only recent entries
        while IFS='|' read -r timestamp msg; do
            if [ "$timestamp" -gt "$keep_time" ]; then
                echo "${timestamp}|${msg}"
            fi
        done < "$RECENT_MESSAGES_FILE" > "${RECENT_MESSAGES_FILE}.tmp"
        mv "${RECENT_MESSAGES_FILE}.tmp" "$RECENT_MESSAGES_FILE"
        
        # Count notifications in the last minute for rate limiting
        local recent_count=0
        while IFS='|' read -r timestamp msg; do
            if [ "$timestamp" -gt "$one_minute_ago" ]; then
                recent_count=$((recent_count + 1))
            fi
        done < "$RECENT_MESSAGES_FILE"
        
        [ "$recent_count" -ge "$MAX_NOTIFICATIONS_PER_MINUTE" ]
    else
        return 1  # No rate limiting needed
    fi
}

# Function to check for duplicate messages
is_duplicate_message() {
    local message="$1"
    local current_time=$(date +%s)
    local cutoff_time=$((current_time - DUPLICATE_WINDOW))
    
    if [ -f "$RECENT_MESSAGES_FILE" ]; then
        # Check if this exact message was sent recently within the time window
        while IFS='|' read -r timestamp msg; do
            if [ "$msg" = "$message" ] && [ "$timestamp" -gt "$cutoff_time" ]; then
                return 0  # Duplicate found within window
            fi
        done < "$RECENT_MESSAGES_FILE"
    fi
    return 1  # Not a duplicate
}

# Function to get current Ollama model
get_current_ollama_model() {
    # Check if Ollama is running and get the current model
    if curl -s "${OLLAMA_API_URL}/api/ps" >/dev/null 2>&1; then
        # Get the first running model from the process list
        local model=$(curl -s "${OLLAMA_API_URL}/api/ps" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ -n "$model" ]; then
            echo "$model"
            return 0
        fi
    fi
    return 1
}

# Function to update room model via mix task
update_room_model() {
    local model="$1"
    
    # Use mix to update the current room's model
    # This is a simple approach - could be enhanced to target specific rooms
    mix run -e "
    rooms = AshChat.Resources.Room.list_visible()
    case rooms do
      [room | _] -> 
        AshChat.Resources.Room.update(room, %{current_model: \"$model\"})
        IO.puts(\"Updated room #{room.id} model to: $model\")
      [] -> 
        IO.puts(\"No visible rooms found to update\")
    end
    " 2>/dev/null
}

# Function to record notification
record_notification() {
    local message="$1"
    local current_time=$(date +%s)
    echo "${current_time}|${message}" >> "$RECENT_MESSAGES_FILE"
}

# Function to send message to Claude via AppleScript
notify_claude() {
    local message="$1"
    
    # Check if watchdog is disabled
    if [ -f "$LOCKFILE" ]; then
        echo -e "${YELLOW}🔒 Watchdog is disabled, skipping notification${NC}"
        return 1
    fi
    
    # Clean old entries and check rate limits
    if clean_and_check_rate_limit; then
        echo -e "${YELLOW}⏳ Rate limiting: too many notifications in the last minute${NC}"
        return 1
    fi
    
    # Check for duplicates
    if is_duplicate_message "$message"; then
        echo -e "${YELLOW}🔄 Skipping duplicate message within ${DUPLICATE_WINDOW}s window${NC}"
        return 1
    fi
    
    # Record this notification
    record_notification "$message"
    
    # Use osascript inline to find iTerm and send the message with Enter
    osascript <<EOF
tell application "iTerm"
    tell current window
        set found_session to false
        
        -- Try current tab first
        repeat with aSession in sessions of current tab
            if name of aSession contains "claude" then
                set found_session to true
                tell aSession
                    write text "$message"
                    delay 0.1
                    write text ""
                end tell
                return
            end if
        end repeat
        
        -- Check all tabs if not found
        repeat with aTab in tabs
            repeat with aSession in sessions of aTab
                if name of aSession contains "claude" then
                    set found_session to true
                    tell aSession
                        write text "$message"
                        delay 0.1
                        write text ""
                    end tell
                    return
                end if
            end repeat
        end repeat
        
        -- If no claude session found, do nothing (noop)
        if not found_session then
            return
        end if
    end tell
end tell
EOF
}

# Initialize last position
if [ -f "$LAST_LINE_FILE" ]; then
    LAST_POSITION=$(cat "$LAST_LINE_FILE")
else
    LAST_POSITION=0
fi

# Function to check for errors
check_for_errors() {
    if [ -f "$ERROR_LOG" ]; then
        CURRENT_SIZE=$(wc -c < "$ERROR_LOG" | tr -d ' ')
        
        if [ "$CURRENT_SIZE" -gt "$LAST_POSITION" ]; then
            # Extract new content
            NEW_CONTENT=$(tail -c +$((LAST_POSITION + 1)) "$ERROR_LOG")
            
            # Check for real error patterns (Elixir/Erlang specific errors)
            # Look for: ** (SomeError), [error], compilation errors, etc.
            if echo "$NEW_CONTENT" | grep -E "(\*\* \(|^\[error\]|cannot compile module|undefined function|CompileError|RuntimeError|ArgumentError|KeyError|MatchError)" > /dev/null && \
               ! echo "$NEW_CONTENT" | grep -q "Errors cleared at commit"; then
                echo -e "${RED}⚠️  Error detected!${NC}"
                
                # Extract the actual error message from the NEW content only
                ERROR_LINE=$(echo "$NEW_CONTENT" | grep -E "\.ex:[0-9]+" | tail -1 | grep -oE "[^/]+\.ex:[0-9]+")
                ERROR_TYPE=$(echo "$NEW_CONTENT" | grep -E "\*\* \(" | tail -1 | sed -E 's/.*\*\* \(([^)]+)\).*/\1/')
                
                # Get the full file path and line number
                FULL_PATH=$(echo "$NEW_CONTENT" | grep -E "\.ex:[0-9]+" | tail -1 | grep -oE "\([^)]+\.ex:[0-9]+\)" | tr -d '()')
                
                # Get the most recent error line for context
                FIRST_ERROR=$(echo "$NEW_CONTENT" | grep -E "(Error|Exception|\*\*)" | tail -1 | sed 's/^[[:space:]]*//' | cut -c1-80)
                
                # Create formatted notification message with better context
                if [ -n "$ERROR_LINE" ] && [ -n "$ERROR_TYPE" ]; then
                    # Extract the error details and value if present
                    ERROR_MSG=$(echo "$NEW_CONTENT" | grep -A2 "Got value:" | tail -1 | sed 's/^[[:space:]]*//' | cut -c1-60)
                    TIMESTAMP=$(echo "$NEW_CONTENT" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" | tail -1)
                    
                    # Extract first 3 lines of stack trace
                    STACK_TRACE=$(echo "$NEW_CONTENT" | grep -A3 -E "\.ex:[0-9]+:" | grep -E "^\s+\(" | head -3 | sed 's/^[[:space:]]*/  /')
                    
                    MESSAGE=$'\n\nAn error just occurred, but it might be a duplicate:'
                    MESSAGE="${MESSAGE}"$'\n'"Type: ${ERROR_TYPE}"
                    MESSAGE="${MESSAGE}"$'\n'"File: ${ERROR_LINE}"
                    if [ -n "$FULL_PATH" ]; then
                        MESSAGE="${MESSAGE}"$'\n'"Path: ${FULL_PATH}"
                    fi
                    if [ -n "$TIMESTAMP" ]; then
                        MESSAGE="${MESSAGE}"$'\n'"Time: ${TIMESTAMP}"
                    fi
                    if [ -n "$ERROR_MSG" ] && [ "$ERROR_MSG" != "" ]; then
                        MESSAGE="${MESSAGE}"$'\n'"Value: ${ERROR_MSG}..."
                    fi
                    if [ -n "$STACK_TRACE" ]; then
                        MESSAGE="${MESSAGE}"$'\n'"Stack:"$'\n'"${STACK_TRACE}"
                    fi
                elif [ -n "$FIRST_ERROR" ]; then
                    MESSAGE=$'\n\nAn error just occurred, but it might be a duplicate:\n'"${FIRST_ERROR}"
                else
                    MESSAGE=$'\n\nAn error just occurred, but it might be a duplicate:\n'"Check error.log for details"
                fi
                
                echo -e "${YELLOW}📨 Notifying Claude: ${MESSAGE}${NC}"
                notify_claude "$MESSAGE"
                return 0  # Error found
            fi
            
            # Update position
            echo "$CURRENT_SIZE" > "$LAST_LINE_FILE"
            LAST_POSITION=$CURRENT_SIZE
        fi
    fi
    return 1  # No error found
}

# Function to check and update model if needed
check_and_update_model() {
    if current_model=$(get_current_ollama_model); then
        echo -e "${GREEN}🤖 Detected Ollama model: ${current_model}${NC}"
        if update_room_model "$current_model"; then
            echo -e "${GREEN}✅ Updated room model to: ${current_model}${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No running Ollama models detected${NC}"
    fi
}

# Main execution
if [[ "$ONCE_MODE" == "true" ]]; then
    # One-time check mode
    check_and_update_model
    check_for_errors
    if [ $? -eq 1 ]; then
        echo -e "${GREEN}✅ No new errors found${NC}"
    fi
    exit 0
else
    # Continuous monitoring loop
    echo -e "${GREEN}🔍 Checking current Ollama model...${NC}"
    check_and_update_model
    
    while true; do
        check_for_errors
        
        # Check for model changes every 30 seconds (15 cycles)
        if [ $(($(date +%s) % 30)) -eq 0 ]; then
            check_and_update_model
        fi
        
        sleep 2
    done
fi