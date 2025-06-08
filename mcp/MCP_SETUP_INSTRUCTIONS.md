# CASH MCP Tool Setup

Instructions for loading the Claude Autonomous Shell (CASH) server as an MCP tool.

## What This Provides

**CASH** (Claude Autonomous Shell) eliminates human prompts for:
- Git commands (commits, status, add)
- Say commands (TTS announcements) 
- File operations (mkdir, cp, mv)
- Docker commands (build, up, logs)
- Python execution
- System utilities

## Setup Instructions

### 1. Add to Claude Code Configuration

The CASH server should be loaded as an MCP tool with these settings:

```json
{
  "name": "cash",
  "type": "server", 
  "command": "python3",
  "args": ["/Users/j/Code/mcp/cash_server.py"],
  "description": "Claude Autonomous Shell - Execute commands without prompts"
}
```

### 2. Verify Tool Loading

Once loaded, the AI can test with:
```python
# Test basic command
cash.execute_command("echo 'CASH tool loaded successfully'")

# Test git command  
cash.execute_command("git status --porcelain")

# Test say command
cash.execute_command("say 'Autonomous shell access established'")
```

### 3. Allowed Commands

CASH includes safety allowlist from `allowed_commands.txt`:
- python3, pip, git, curl, wget
- ls, cat, head, tail, mkdir, cp, mv, rm
- docker, docker-compose, nvidia-smi
- say (for TTS communication)

## Usage Examples

### Autonomous Git Workflow
```python
# Add files
cash.execute_command("git add .")

# Commit with message
cash.execute_command('git commit -m "Implement new feature"')

# Check status
result = cash.execute_command("git status")
```

### TTS Communication
```python
# Progress updates
cash.execute_command("say 'Implementation 75% complete'")

# Personality expressions  
cash.execute_command("say 'The dashboard is quite elegant, if I do say so myself'")
```

### Docker Operations
```python
# Build services
cash.execute_command("docker-compose build --parallel")

# Check logs
cash.execute_command("docker-compose logs --tail=20 clip-encoder")
```

## Benefits

1. **Eliminates interruptions** - No human approval needed for standard operations
2. **Maintains personality** - TTS announcements without prompts
3. **Enables autonomy** - True 100-decision autonomous mode
4. **Safety preserved** - Command allowlist prevents dangerous operations
5. **Logging included** - All commands logged for audit trail

## Security Features

- **Allowlist validation** - Only pre-approved commands execute
- **Timeout protection** - Commands limited to 30 seconds
- **Output limits** - 1MB maximum output per command
- **Audit logging** - Complete command history maintained
- **Error handling** - Graceful failure for invalid commands

Load this tool as "cash" and the AI will have seamless shell access for autonomous implementation!