# Claude Sessions Research Microblog

*Date: 2025-06-13*
*Research Budget: 50 rounds*
*Actual Usage: 10 rounds*

## The Journey to Persistent Claude Sessions

### Round 1: Initial Exploration 🔍
Starting with a simple question: Can we make Claude sessions persistent? User wants tmux/OTP supervision trees. Let's see what's possible.

### Round 2: GenServer + tmux Design 🏗️
Created `ClaudeSession` GenServer that spawns tmux sessions and pipes commands. Clean abstraction:
```elixir
ClaudeSession.start_link("research")
ClaudeSession.submit("research", "What is consciousness?")
```

### Round 3: First Reality Check 💥
`System.cmd` hangs when called from GenServer. Trying ports, spawning, everything. Why does it work in IEx but not in GenServer?

### Round 4: The Hunt Begins 🔍
- Tried `Port.open`
- Tried `:os.cmd`  
- Tried `System.shell`
- All hang the same way. Something about GenServer process context...

### Round 5: Shell Script Wrapper 🐚
Maybe if we wrap everything in a shell script? Created `claude_headless_runner.sh`. Still hangs. The problem is deeper.

### Round 6: Discovering Headless Mode 🤖
Found `--print --output-format stream-json`! Claude has a headless mode that streams JSON. This could be the key.

### Round 7: Direct Binary Spawn 🚀
Created `ClaudeHeadlessSession` using Erlang ports directly:
```elixir
Port.open({:spawn_executable, claude_path}, 
  [:binary, :exit_status, args: full_args])
```
Still hangs. But learned about process isolation.

### Round 8: The Supervision Tree 🌳
Built full OTP supervision tree:
- `ClaudeSessionSupervisor` (one_for_one)
- Multiple `ClaudeSession` children
- Proper fault tolerance

But the core problem remains: subprocess execution fails.

### Round 9: Performance Testing ⚡
Discovered Claude CLI is SLOW:
- Simple prompt: 10-14 seconds
- With streaming: Still 10+ seconds
- Even with `--model sonnet`

This might not be viable for real-time chat.

### Round 10: Final Analysis 📊
**Conclusions:**
1. GenServer subprocess spawning has fundamental issues in our environment
2. Claude CLI overhead is prohibitive (10+ seconds minimum)
3. tmux integration works in theory but blocked by subprocess issues
4. Need different approach - maybe direct API or different process model

**Key Learning**: Sometimes the most elegant architecture hits practical walls. The GenServer + tmux design is clean, but the 10-second overhead makes it unusable for interactive chat.

## Preserved Code Artifacts

All three implementations preserved:
- `claude_session.ex` - The tmux-based approach
- `claude_headless_session.ex` - Direct binary streaming
- `claude_session_supervisor.ex` - OTP supervision tree

Even though they don't work due to environment constraints, they demonstrate proper Elixir/OTP patterns and might work in a different context.

## The Pop

After 10 rounds, we had learned what we needed. Rather than fight the environment further, we "popped the stack" and returned to productive work. Sometimes knowing when to stop is the best decision.

---

*"The best code is the code that teaches us something, even if we don't ship it."*