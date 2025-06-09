on run argv
    set command to item 1 of argv
    tell application "iTerm2"
        -- Get the tab that was active when this script was called
        set targetTab to current tab of current window
        tell current session of targetTab
            -- First navigate to claude_collector directory
            write text "cd /Users/j/Code/athena/system/athena-ingest/claude_collector"
            delay 1
            
            -- Then run the command
            write text command
            
            -- Give command time to run and show any prompts
            delay 3
            set terminalContent to contents
            
            -- If we see "1. Yes" in the output, automatically press enter
            if terminalContent contains "1. Yes" then
                write text ""
                delay 1
            end if
        end tell
    end tell
end run