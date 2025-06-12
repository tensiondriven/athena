#!/usr/bin/osascript
-- Get configuration of topmost iTerm2 window

tell application "iTerm2"
    if (count of windows) > 0 then
        tell current window
            set windowInfo to "Window ID: " & id & return
            set windowInfo to windowInfo & "Window Name: " & name & return
            set windowInfo to windowInfo & "Tab Count: " & (count of tabs) & return
            
            tell current tab
                set windowInfo to windowInfo & return & "Current Tab:" & return
                set windowInfo to windowInfo & "  Sessions: " & (count of sessions) & return
                
                set sessionIndex to 1
                repeat with aSession in sessions
                    tell aSession
                        set windowInfo to windowInfo & return & "  Session " & sessionIndex & ":" & return
                        set windowInfo to windowInfo & "    Name: " & name & return
                        set windowInfo to windowInfo & "    Rows: " & rows & return
                        set windowInfo to windowInfo & "    Columns: " & columns & return
                        set windowInfo to windowInfo & "    TTY: " & tty & return
                        set windowInfo to windowInfo & "    Is Processing: " & is processing & return
                        set windowInfo to windowInfo & "    Is At Shell Prompt: " & is at shell prompt & return
                    end tell
                    set sessionIndex to sessionIndex + 1
                end repeat
            end tell
        end tell
        
        return windowInfo
    else
        return "No iTerm2 windows found"
    end if
end tell