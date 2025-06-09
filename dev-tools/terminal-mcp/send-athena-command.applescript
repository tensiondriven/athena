on run argv
    set command to item 1 of argv
    set workingDir to ""
    
    -- Check if working directory was provided
    if (count of argv) > 1 then
        set workingDir to item 2 of argv
    end if
    
    tell application "iTerm2"
        set foundSession to false
        
        -- Look for existing athena session
        repeat with win in windows
            repeat with tab in tabs of win
                repeat with theSession in sessions of tab
                    set sessionName to name of theSession
                    if sessionName contains "athena" then
                        set foundSession to true
                        tell theSession
                            -- Change directory if specified
                            if workingDir is not "" then
                                write text "cd " & quoted form of workingDir
                                delay 0.5
                            end if
                            
                            -- Execute the command
                            write text command
                        end tell
                        exit repeat
                    end if
                end repeat
                if foundSession then exit repeat
            end repeat
            if foundSession then exit repeat
        end repeat
        
        -- If no athena session found, create one
        if not foundSession then
            tell current session of current tab of current window
                split horizontally with default profile
                delay 1
            end tell
            tell current session of current tab of current window
                set name to "athena"
                
                -- Change directory if specified
                if workingDir is not "" then
                    write text "cd " & quoted form of workingDir
                    delay 0.5
                end if
                
                -- Execute the command
                write text command
            end tell
        end if
    end tell
end run