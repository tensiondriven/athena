#!/bin/bash
# Watch git index modification time

echo "Watching .git/index for changes..."
echo

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    stat -f "Index last modified: %Sm" -t "%Y-%m-%d %H:%M:%S" .git/index
    fswatch -o .git/index | while read num ; do
        clear
        echo "Git index changed at $(date '+%H:%M:%S')"
        stat -f "Index last modified: %Sm" -t "%Y-%m-%d %H:%M:%S" .git/index
        echo
        # Quick dirty check without lock
        echo "Dirty files:"
        git diff --name-only HEAD 2>/dev/null || echo "(locked)"
    done
else
    # Linux  
    inotifywait -m -e modify .git/index --format '%T' --timefmt '%H:%M:%S' | while read time; do
        echo "[$time] Git index updated"
    done
fi