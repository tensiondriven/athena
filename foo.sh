watch -n 0.33 "find /Users/$(whoami)/Code/athena -type f -mtime -1h -exec stat -f '%m %N' {} \; 2>/dev/null | sort -nr | head 10 | while read timestamp path; do echo \"\$(date -r \$timestamp '+%H:%M:%S') (\$(echo \$(( \$(date +%s) - \$timestamp )) | awk '{if(\$1<60) print \$1\"s ago\"; else if(\$1<3600) print int(\$1/60)\"m ago\"; else print int(\$1/3600)\"h ago\"}')) \$(basename \"\$path\")\";

