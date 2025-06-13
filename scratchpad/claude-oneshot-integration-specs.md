# Claude OneShot Integration Specs - Scratchpad

## Current State Investigation

**Found:**
- `test_claude_oneshot.exs` - test script but no actual implementation
- Profile validation only allows: "ollama", "openai", "anthropic" 
- No OneShot provider option in current code

**Missing:**
- Claude OneShot provider in Profile validation
- CLI invocation logic
- Integration with existing AI flow

## Specs for Implementation

### 1. Profile Changes
- Add "claude_oneshot" to allowed providers in `profile.ex` line 25
- For Claude OneShot profiles:
  - No `api_key` field needed
  - No `url` field needed  
  - Just `provider` = "claude_oneshot" and `model` field

### 2. CLI Integration Pattern
**Questions to resolve:**
- Where does CLI execution happen? In `ChatAgent`? New module?
- Process spawning: one-shot per request or persistent?
- CLI path: hardcoded or configurable?

**Based on test file structure, likely integration point:**
- `AshChat.AI.ChatAgent.send_message_and_get_ai_response/3` needs Claude OneShot path

### 3. Mini Events for Tool Failures
**Event Types to Define:**
- `tool.claude_oneshot.success` - CLI completed successfully
- `tool.claude_oneshot.failure` - CLI process failed/exited
- `tool.claude_oneshot.timeout` - CLI didn't respond in time

**Event Structure:**
```elixir
%{
  event_type: "tool.claude_oneshot.failure",
  source_id: "claude_oneshot_cli",
  content: "CLI process exited with code 1",
  metadata: %{
    exit_code: 1,
    stderr: "error message",
    agent_card_id: agent_id,
    room_id: room_id
  }
}
```

**Display Integration:**
- Show mini events as status indicators on agent cards
- Maybe a small colored dot or status text
- Click to see event details

## Implementation Priority
1. Add "claude_oneshot" to Profile validation ✓ (trivial)
2. Find CLI integration point and implement basic execution
3. Add mini event generation for failures  
4. Wire up UI status display

## Discovery from Git Archaeology 
**Key Finding**: Claude OneShot work was done as CLI/TUI interface design but NOT implementation.

The commit `1a0ffaa` added:
- `test_claude_oneshot.exs` (test script for AI conversation flow)
- CLI/TUI interface concept documentation

**But NO actual Claude OneShot backend code was implemented.**

## The Real State
- Test script exists but tests existing Ollama/OpenRouter backends
- Profile validation still only allows: "ollama", "openai", "anthropic" 
- **Claude OneShot provider doesn't exist in code yet**

## Implementation Strategy  
Since this is NEW work (not just exposing existing functionality):
1. Add "claude_oneshot" provider to Profile validation ✓
2. **Build CLI integration module from scratch**
3. Design stdin/stdout communication pattern
4. Add mini event system for tool status

## Questions Still Needed
- CLI binary name: `claude-code` with oneshot flag?
- Input format: plain text prompt or JSON envelope? 
- Working directory: inherit from parent process?
- Timeout handling: what's reasonable for CLI response?