#!/usr/bin/osascript -l JavaScript
// Get iTerm2 window configuration as JSON

function run() {
    const iTerm = Application("iTerm2");
    
    if (iTerm.windows.length === 0) {
        return JSON.stringify({error: "No iTerm2 windows found"});
    }
    
    const currentWindow = iTerm.currentWindow();
    const currentTab = currentWindow.currentTab();
    
    const windowInfo = {
        windowId: currentWindow.id(),
        windowName: currentWindow.name(),
        tabCount: currentWindow.tabs.length,
        currentTab: {
            sessionCount: currentTab.sessions.length,
            sessions: []
        }
    };
    
    // Get session info
    for (let i = 0; i < currentTab.sessions.length; i++) {
        const session = currentTab.sessions[i];
        windowInfo.currentTab.sessions.push({
            index: i + 1,
            name: session.name(),
            rows: session.rows(),
            columns: session.columns(),
            tty: session.tty(),
            isProcessing: session.isProcessing(),
            isAtShellPrompt: session.isAtShellPrompt()
        });
    }
    
    return JSON.stringify(windowInfo, null, 2);
}