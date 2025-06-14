# Persistent Claude Sessions Design

*Status: Research Complete - Implementation Blocked*
*Date: 2025-06-13*

## Overview

This document captures the design for persistent Claude CLI sessions using Elixir OTP and tmux. While the implementation hit environment-specific blockers, the design patterns are sound and could be valuable in other contexts.

## Architecture

### Core Components

1. **ClaudeSession (GenServer)**
   - Manages individual tmux sessions
   - Handles command submission and response parsing
   - Maintains session state

2. **ClaudeSessionSupervisor**
   - OTP supervisor with one_for_one strategy
   - Manages multiple concurrent sessions
   - Provides fault tolerance

3. **tmux Integration**
   - Named sessions for persistence
   - Survives application restarts
   - Allows manual inspection/debugging

### API Design

```elixir
# Start a new session
{:ok, pid} = ClaudeSession.start_link("research")

# Submit a prompt
{:ok, response} = ClaudeSession.submit("research", "What is consciousness?")

# List active sessions
ClaudeSession.list_sessions()
# => ["research", "coding", "analysis"]

# Attach to tmux session manually
# $ tmux attach -t claude_research
```

## Implementation Challenges

### 1. Subprocess Execution in GenServer
- `System.cmd/3` hangs when called from GenServer
- Port.open also exhibits blocking behavior
- Appears to be process isolation issue

### 2. CLI Performance
- Claude CLI has 10-14 second overhead
- Even with --model sonnet (faster model)
- Makes real-time chat impractical

### 3. Headless Mode Limitations
- `--print --output-format stream-json` exists but still slow
- JSON parsing adds complexity
- No significant performance improvement

## Alternative Approaches

### 1. Direct API Integration
Instead of CLI, use Anthropic API directly:
- Sub-second response times
- Proper streaming support
- No subprocess complexity

### 2. Worker Pool Pattern
Pre-spawn Claude instances:
- Amortize startup cost
- Round-robin request distribution
- Still limited by CLI overhead

### 3. External Service
Run Claude sessions in separate OS process:
- Python/Node.js service
- Communicate via Phoenix Channels
- Sidestep Elixir subprocess issues

## Lessons Learned

1. **Process Context Matters**: GenServer process isolation can block subprocess execution in unexpected ways

2. **Benchmark Early**: The 10-second CLI overhead should have been discovered before architectural design

3. **OTP Patterns Are Reusable**: The supervision tree design can be applied to other external process management needs

4. **Know When to Pivot**: After 10 rounds of research, recognizing the fundamental blockers led to productive work elsewhere

## Future Considerations

If CLI performance improves or environment constraints change:

1. The tmux integration provides excellent debugging capability
2. The supervision tree ensures fault tolerance
3. The GenServer abstraction keeps implementation details hidden

The design is sound; the current tools just aren't ready for it.

---

*"Good architecture transcends implementation constraints."*