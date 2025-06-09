on run argv
    set command to item 1 of argv
    
    tell application "iTerm2"
        tell current window
            repeat with theTab in tabs
                repeat with theSession in sessions of theTab
                    set sessionName to name of theSession
                    if sessionName contains "athena" then
                        tell theSession
                            write text "cd /Users/j/Code/athena/system/athena-ingest/claude_collector"
                            delay 1
                            write text command
                            delay 3
                            set terminalContent to contents
                            if terminalContent contains "1. Yes" then
                                write text ""
                                delay 1
                            end if
                        end tell
                        return
                    end if
                end repeat
            end repeat
        end tell
        
        -- Session not found - offer to create one
        display dialog "Session 'athena' not found. Would you like me to create a new split pane and name it 'athena'?" buttons {"Cancel", "Create"} default button "Create"
        if button returned of result is "Create" then
            tell current session of current tab of current window
                split horizontally with default profile
                delay 1
            end tell
            tell current session of current tab of current window
                set name to "athena"
                write text "cd /Users/j/Code/athena/system/athena-ingest/claude_collector"
                delay 1
                write text command
                delay 3
                set terminalContent to contents
                if terminalContent contains "1. Yes" then
                    write text ""
                    delay 1
                end if
            end tell
        end if
    end tell
end run