#!/bin/bash
# Monitor Claude Code logs for write timing

LOGS_DIR="$HOME/.claude/projects/-Users-j-Code-athena"

while true; do
    clear
    echo "Claude Logs - $(date '+%H:%M:%S')"
    echo
    
    # Last 10 files with relative times
    ls -lt "$LOGS_DIR"/*.jsonl 2>/dev/null | head -10 | while read line; do
        file=$(basename "$(echo "$line" | awk '{print $9}')")
        size=$(echo "$line" | awk '{print $5}')
        
        # Get seconds since modification
        if [[ "$OSTYPE" == "darwin"* ]]; then
            mod_time=$(stat -f "%m" "$LOGS_DIR/$file")
        else
            mod_time=$(stat -c "%Y" "$LOGS_DIR/$file")
        fi
        
        now=$(date +%s)
        ago=$((now - mod_time))
        
        # Format time
        if [ $ago -lt 60 ]; then
            time_str="${ago}s"
        elif [ $ago -lt 3600 ]; then
            time_str="$((ago / 60))m"
        else
            time_str="$((ago / 3600))h"
        fi
        
        printf "%-40s %8s  %6s ago\n" "${file:0:40}" "$size" "$time_str"
    done
    
    sleep 1
done