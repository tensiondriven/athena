#!/bin/bash

# Flash error log watchdog that notifies Claude Code
# Similar to error_watchdog.sh but for flash messages
# 
# USAGE:
#   ./flash_watchdog.sh           - Start continuous monitoring
#   ./flash_watchdog.sh --once    - Check once and exit
#   ./flash_watchdog.sh --help    - Show this help

# Check for help flag first
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Flash Error Watchdog - Monitor flash_errors.log and notify Claude Code"
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
    echo "  Monitors tmp/flash_errors.log for UI error messages and automatically"
    echo "  sends notifications to the Claude Code session in iTerm."
    echo ""
    exit 0
fi

FLASH_LOG="tmp/flash_errors.log"
LAST_LINE_FILE=".flash_watchdog_last"
RECENT_MESSAGES_FILE=".flash_watchdog_recent"
LOCKFILE="flash_watchdog_disabled.lock"
MAX_NOTIFICATIONS_PER_MINUTE=10
DUPLICATE_WINDOW=30  # seconds

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Handle command line arguments
if [[ "$1" == "--disable" ]]; then
    touch "$LOCKFILE"
    echo -e "${YELLOW}🔒 Flash watchdog disabled${NC}"
    echo "Lockfile created: $LOCKFILE"
    exit 0
elif [[ "$1" == "--enable" ]]; then
    if [ -f "$LOCKFILE" ]; then
        rm "$LOCKFILE"
        echo -e "${GREEN}🔓 Flash watchdog enabled${NC}"
        echo "Lockfile removed: $LOCKFILE"
    else
        echo -e "${GREEN}✅ Flash watchdog is already enabled${NC}"
    fi
    exit 0
elif [[ "$1" == "--status" ]]; then
    if [ -f "$LOCKFILE" ]; then
        echo -e "${YELLOW}🔒 Flash watchdog is DISABLED${NC}"
        echo "Lockfile exists: $LOCKFILE"
    else
        echo -e "${GREEN}🔓 Flash watchdog is ENABLED${NC}"
        echo "No lockfile found"
    fi
    exit 0
fi

# Parse command line arguments
ONCE_MODE=false
if [[ "$1" == "--once" ]]; then
    ONCE_MODE=true
fi

if [[ "$ONCE_MODE" == "false" ]]; then
    echo -e "${GREEN}🔍 Flash Error Watchdog Started${NC}"
    echo -e "Monitoring: ${FLASH_LOG}"
    echo -e "Press Ctrl+C to stop\n"
else
    echo -e "${GREEN}🔍 Flash Error Watchdog - One-time Check${NC}"
fi

# Function to clean old entries and check rate limits
clean_and_check_rate_limit() {
    local current_time=$(date +%s)
    local one_minute_ago=$((current_time - 60))
    local cutoff_time=$((current_time - DUPLICATE_WINDOW))
    
    if [ -f "$RECENT_MESSAGES_FILE" ]; then
        # Clean old entries
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

# Function to check for flash errors
check_for_flash_errors() {
    if [ -f "$FLASH_LOG" ]; then
        CURRENT_SIZE=$(wc -c < "$FLASH_LOG" | tr -d ' ')
        
        if [ "$CURRENT_SIZE" -gt "$LAST_POSITION" ]; then
            # Extract new content
            NEW_CONTENT=$(tail -c +$((LAST_POSITION + 1)) "$FLASH_LOG")
            
            # Parse JSON log entries
            while IFS= read -r line; do
                if [ -n "$line" ]; then
                    # Extract message from JSON using grep and sed
                    ERROR_MSG=$(echo "$line" | grep -o '"message":"[^"]*"' | sed 's/"message":"\(.*\)"/\1/')
                    TIMESTAMP=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | sed 's/"timestamp":"\(.*\)"/\1/')
                    
                    if [ -n "$ERROR_MSG" ]; then
                        echo -e "${RED}⚠️  Flash error detected!${NC}"
                        
                        # Create notification message
                        MESSAGE=$'\n\nUI Error occurred:'
                        MESSAGE="${MESSAGE}"$'\n'"${ERROR_MSG}"
                        if [ -n "$TIMESTAMP" ]; then
                            TIME_SHORT=$(echo "$TIMESTAMP" | cut -d'T' -f2 | cut -d'.' -f1)
                            MESSAGE="${MESSAGE}"$'\n'"Time: ${TIME_SHORT}"
                        fi
                        
                        echo -e "${YELLOW}📨 Notifying Claude: UI Error${NC}"
                        notify_claude "$MESSAGE"
                    fi
                fi
            done <<< "$NEW_CONTENT"
            
            # Update position
            echo "$CURRENT_SIZE" > "$LAST_LINE_FILE"
            LAST_POSITION=$CURRENT_SIZE
        fi
    fi
}

# Main execution
if [[ "$ONCE_MODE" == "true" ]]; then
    # One-time check mode
    check_for_flash_errors
    exit 0
else
    # Continuous monitoring loop
    while true; do
        check_for_flash_errors
        sleep 2
    done
fi