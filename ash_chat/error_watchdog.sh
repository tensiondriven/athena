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
    echo "  $0 --help       Show this help"
    echo ""
    echo "DESCRIPTION:"
    echo "  Monitors tmp/error.log for new errors and automatically sends"
    echo "  notifications to the Claude Code session in iTerm when errors"
    echo "  are detected. Notifications include error context like module"
    echo "  and line numbers when available."
    echo ""
    echo "EXAMPLES:"
    echo "  $0              # Start watching in background"
    echo "  $0 --once       # Check current log once"
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
MAX_NOTIFICATIONS_PER_MINUTE=5
DUPLICATE_WINDOW=30  # seconds

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

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

# Function to record notification
record_notification() {
    local message="$1"
    local current_time=$(date +%s)
    echo "${current_time}|${message}" >> "$RECENT_MESSAGES_FILE"
}

# Function to send message to Claude via AppleScript
notify_claude() {
    local message="$1"
    
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
        -- Try current tab first
        repeat with aSession in sessions of current tab
            if name of aSession contains "claude" then
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
                    tell aSession
                        write text "$message"
                        delay 0.1
                        write text ""
                    end tell
                    return
                end if
            end repeat
        end repeat
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
            
            # Check for error patterns (but skip the cleared marker)
            if echo "$NEW_CONTENT" | grep -E "(error]|Error|Exception|undefined function|cannot compile)" > /dev/null && ! echo "$NEW_CONTENT" | grep -q "Errors cleared at commit"; then
                echo -e "${RED}⚠️  Error detected!${NC}"
                
                # Extract the actual error message from the NEW content only
                ERROR_LINE=$(echo "$NEW_CONTENT" | grep -E "\.ex:[0-9]+" | tail -1 | grep -oE "[^/]+\.ex:[0-9]+")
                ERROR_TYPE=$(echo "$NEW_CONTENT" | grep -E "\*\* \(" | tail -1 | sed -E 's/.*\*\* \(([^)]+)\).*/\1/')
                
                # Get the most recent error line for context
                FIRST_ERROR=$(echo "$NEW_CONTENT" | grep -E "(Error|Exception|\*\*)" | tail -1 | sed 's/^[[:space:]]*//' | cut -c1-80)
                
                # Create simple notification message
                if [ -n "$ERROR_LINE" ] && [ -n "$ERROR_TYPE" ]; then
                    MESSAGE="Check errors: ${ERROR_TYPE} in ${ERROR_LINE}"
                elif [ -n "$FIRST_ERROR" ]; then
                    MESSAGE="Check errors: ${FIRST_ERROR}"
                else
                    MESSAGE="Check errors: new exception in error.log"
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

# Main execution
if [[ "$ONCE_MODE" == "true" ]]; then
    # One-time check mode
    check_for_errors
    if [ $? -eq 1 ]; then
        echo -e "${GREEN}✅ No new errors found${NC}"
    fi
    exit 0
else
    # Continuous monitoring loop
    while true; do
        check_for_errors
        sleep 2
    done
fi