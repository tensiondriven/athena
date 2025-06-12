#!/bin/bash
# Watch for dirty files without git status lock issues

while true; do
    clear
    echo "Git Dirty Files - $(date '+%H:%M:%S')"
    echo
    
    # Check index directly without full status
    if [ -f .git/index ]; then
        # Modified files (staged and unstaged)
        git diff --name-only HEAD 2>/dev/null | sed 's/^/M /'
        
        # Untracked files
        git ls-files --others --exclude-standard 2>/dev/null | sed 's/^/? /'
        
        # Deleted files
        git ls-files --deleted 2>/dev/null | sed 's/^/D /'
    else
        echo "Not a git repository"
    fi
    
    sleep 1
done