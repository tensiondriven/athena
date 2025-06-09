on run argv
    set maxWaitTime to 30
    if (count of argv) > 0 then
        set maxWaitTime to item 1 of argv as integer
    end if
    
    tell application "iTerm2"
        set foundSession to false
        
        -- Find athena session
        repeat with win in windows
            repeat with tab in tabs of win
                repeat with theSession in sessions of tab
                    set sessionName to name of theSession
                    if sessionName contains "athena" then
                        set foundSession to true
                        
                        -- Wait for command to complete (look for prompt)
                        set waitCounter to 0
                        repeat while waitCounter < maxWaitTime
                            tell theSession
                                set sessionContent to contents
                                set lastLine to last paragraph of sessionContent
                                
                                -- Look for common prompt indicators
                                if lastLine contains "$" or lastLine contains ">" or lastLine contains "#" or lastLine contains "%" then
                                    -- Check if cursor is at end of line (command completed)
                                    if lastLine does not end with " " then
                                        return "ready"
                                    end if
                                end if
                            end tell
                            
                            delay 1
                            set waitCounter to waitCounter + 1
                        end repeat
                        
                        return "timeout"
                    end if
                end repeat
                if foundSession then exit repeat
            end repeat
            if foundSession then exit repeat
        end repeat
        
        return "session_not_found"
    end tell
end run