tell application "iTerm2"
    tell current session of current tab of current window
        get contents
    end tell
end tell