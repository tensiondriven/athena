tell application "iTerm2"
    set foundSession to false
    set sessionContent to ""
    
    -- Look for athena session
    repeat with win in windows
        repeat with tab in tabs of win
            repeat with theSession in sessions of tab
                set sessionName to name of theSession
                if sessionName contains "athena" then
                    set foundSession to true
                    tell theSession
                        set sessionContent to contents
                    end tell
                    exit repeat
                end if
            end repeat
            if foundSession then exit repeat
        end repeat
        if foundSession then exit repeat
    end repeat
    
    if foundSession then
        return sessionContent
    else
        return "Error: No 'athena' session found"
    end if
end tell