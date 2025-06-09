on run argv
    set command to item 1 of argv
    tell application "iTerm2"
        tell current session of current tab of current window
            write text command
        end tell
    end tell
end run