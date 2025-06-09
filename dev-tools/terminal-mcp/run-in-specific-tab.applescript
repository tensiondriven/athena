on run argv
    if (count of argv) < 2 then
        display dialog "Usage: script command tabName"
        return
    end if
    
    set command to item 1 of argv
    set tabName to item 2 of argv
    
    tell application "iTerm2"
        set foundTab to false
        repeat with win in windows
            repeat with tab in tabs of win
                if name of current session of tab contains tabName then
                    set foundTab to true
                    tell current session of tab
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
                    exit repeat
                end if
            end repeat
            if foundTab then exit repeat
        end repeat
        
        if not foundTab then
            display dialog "Could not find tab named '" & tabName & "'. Please create a tab and rename it to '" & tabName & "'."
        end if
    end tell
end run