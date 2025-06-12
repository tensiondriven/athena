#!/usr/bin/osascript
-- Split iTerm2 and run git monitoring script

tell application "iTerm2"
    tell current session of current window
        -- Split horizontally
        set newSession to (split horizontally with default profile)
        
        tell newSession
            -- Run the git dirty watcher
            write text "cd " & (POSIX path of (path to home folder)) & "Code/athena"
            write text "./scripts/watch-git-dirty.sh"
        end tell
    end tell
end tell