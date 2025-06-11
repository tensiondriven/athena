# The Error Watchdog Revolution: When AI Debugging Meets AppleScript Magic

*June 9, 2025*

## TL;DR: We Built an AI That Debugs Itself

What happens when you combine Phoenix LiveView error logs, bash scripting wizardry, AppleScript automation, and Claude Code? You get an error watchdog that's so smart it literally messages itself when something breaks. No joke—we just achieved AI that auto-reports its own bugs in real-time.

## The Problem: Error Whack-a-Mole

Picture this: You're deep in Phoenix development, errors are flying faster than you can catch them, and your AI coding assistant has no clue what's breaking under the hood. Traditional debugging feels like playing whack-a-mole blindfolded while juggling flaming torches.

We encountered a classic Ash Framework parameter bug—`Protocol.UndefinedError` where the system expected a map but received a string. The kind of error that stops development dead in its tracks and forces you to context-switch between your AI session and error logs.

## The Breakthrough: Error Watchdog Script

Instead of manually checking logs like cavemen, we built an intelligent error monitoring system that:

### 🔍 **Smart Detection**
- Monitors `tmp/error.log` for new content only (no re-processing old errors)
- Extracts meaningful context: error type, file location, line numbers
- Filters out noise (ignores "Errors cleared" markers)

### 🛡️ **Anti-Spam Protection**
- **Rate limiting**: Max 5 notifications per minute
- **Duplicate detection**: 30-second window to block identical messages
- **Position tracking**: Only processes genuinely new errors

### 🤖 **AI Integration Magic**
- Uses AppleScript to find the Claude Code iTerm session
- Automatically types contextual error messages
- Presses Enter to actually send the notification
- Detects running Ollama models and syncs them with the app

## The Code That Changed Everything

```bash
#!/bin/bash
# The error_watchdog.sh that started a revolution

notify_claude() {
    local message="$1"
    
    # Check rate limits and duplicates first
    if clean_and_check_rate_limit; then
        echo "⏳ Rate limiting: too many notifications"
        return 1
    fi
    
    if is_duplicate_message "$message"; then
        echo "🔄 Skipping duplicate message"
        return 1
    fi
    
    # AppleScript magic to find and message Claude
    osascript <<EOF
tell application "iTerm"
    tell current window
        repeat with aSession in sessions of current tab
            if name of aSession contains "claude" then
                tell aSession
                    write text "$message"
                    delay 0.1
                    write text ""  # Press Enter
                end tell
                return
            end if
        end repeat
    end tell
end tell
EOF
}
```

## Real-World Magic in Action

Here's what happened during our live debugging session:

1. **Error occurs**: Phoenix throws `Protocol.UndefinedError` at line 37
2. **Watchdog detects**: New content in error log within 2 seconds
3. **Context extraction**: "Protocol.UndefinedError in pipeline.ex:42"
4. **Auto-notification**: Message appears in Claude session instantly
5. **AI responds**: Claude immediately analyzes and fixes the bug

The error watchdog literally sent us this message: *"Check errors: Protocol.UndefinedError in pipeline.ex:42"*

## Technical Deep Dive: How We Made It Bulletproof

### Position Tracking
```bash
CURRENT_SIZE=$(wc -c < "$ERROR_LOG")
if [ "$CURRENT_SIZE" -gt "$LAST_POSITION" ]; then
    NEW_CONTENT=$(tail -c +$((LAST_POSITION + 1)) "$ERROR_LOG")
    # Process only new content...
fi
```

### Intelligent Error Parsing
```bash
ERROR_TYPE=$(echo "$NEW_CONTENT" | grep -E "\*\* \(" | tail -1 | sed -E 's/.*\*\* \(([^)]+)\).*/\1/')
ERROR_LINE=$(echo "$NEW_CONTENT" | grep -E "\.ex:[0-9]+" | tail -1 | grep -oE "[^/]+\.ex:[0-9]+")
```

### Duplicate Detection That Actually Works
```bash
while IFS='|' read -r timestamp msg; do
    if [ "$msg" = "$message" ] && [ "$timestamp" -gt "$cutoff_time" ]; then
        return 0  # Duplicate found within window
    fi
done < "$RECENT_MESSAGES_FILE"
```

## The Ollama Integration Bonus

But wait, there's more! The watchdog also:
- Detects which Ollama model is currently loaded
- Updates the Phoenix app's model settings automatically
- Ensures UI always reflects actual AI model in use

```bash
get_current_ollama_model() {
    if curl -s "http://localhost:11434/api/ps" >/dev/null 2>&1; then
        local model=$(curl -s "http://localhost:11434/api/ps" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "$model"
    fi
}
```

## Why This Matters: The Future of AI Development

This isn't just a clever hack—it's a glimpse into the future of AI-assisted development:

### 🚀 **Self-Healing Systems**
AI that can detect, report, and fix its own issues in real-time.

### ⚡ **Zero-Latency Debugging**
No more switching between terminals, checking logs, or losing context.

### 🧠 **Contextual Awareness**
The AI gets precise error information with file locations and stack traces.

### 🎯 **Smart Filtering**
Only actionable errors bubble up—no noise, no spam, just signal.

## The Technical Philosophy

We followed the **Physics of Work** principle: *minimum viable automation that provides maximum leverage*. The error watchdog is:
- **Simple**: 300 lines of bash script
- **Robust**: Rate limiting, duplicate detection, graceful failures
- **Focused**: Does one thing exceptionally well
- **Extensible**: Easy to add new error patterns or notification methods

## Impact: From Reactive to Proactive

Before the watchdog:
```
🔥 Error occurs → 😴 Developer unaware → 🐌 Manual log checking → 😤 Context switching → 🔧 Fix applied
```

After the watchdog:
```
🔥 Error occurs → ⚡ Instant notification → 🤖 AI analyzes → 🎯 Targeted fix → ✅ Problem solved
```

## What's Next: The Roadmap

- **Error Pattern Learning**: Train the watchdog to recognize error categories
- **Auto-Fix Suggestions**: Generate fix candidates based on error patterns
- **Integration Hub**: Connect to GitHub issues, Slack, monitoring systems
- **Multi-Project Support**: Monitor multiple codebases simultaneously

## Try It Yourself

The error watchdog is live in our [Athena repository](https://github.com/tensiondriven/athena). Key components:
- [`error_watchdog.sh`](https://github.com/tensiondriven/athena/blob/master/error_watchdog.sh) - The main monitoring script
- Rate limiting and duplicate detection built-in
- AppleScript integration for seamless iTerm automation
- Ollama model detection and automatic synchronization
- Works with any Phoenix/Elixir project out of the box

## Conclusion: When Code Writes Itself

We've entered an era where AI doesn't just help us code—it actively participates in maintaining, monitoring, and improving itself. The error watchdog represents a fundamental shift from reactive debugging to proactive AI collaboration.

The future isn't just AI-assisted development. It's AI-driven development where the boundary between human and artificial intelligence becomes beautifully blurred.

*Want to see the error watchdog in action? The source code is available in our [Athena project repository](https://github.com/tensiondriven/athena) where we're pioneering AI-driven development workflows.*

---

**Tags:** #AI #Debugging #Phoenix #Elixir #Automation #DevOps #Claude #AppleScript #Bash #Innovation

**Share this:** Because someone needs to tell the world that AI is now debugging itself! 🤖✨