# Claude Spawner MCP Server

A Model Context Protocol (MCP) server that enables spawning Claude instances for multi-agent problem solving with built-in safety limits.

## Overview

The Claude Spawner MCP allows Claude to spawn additional Claude instances to work on subtasks in parallel. This enables sophisticated multi-agent workflows while preventing runaway spawning through configurable safety limits.

## Features

- **Spawn Claude instances** with custom prompts and directives
- **Safety limits** to prevent runaway spawning:
  - Maximum spawn depth (default: 2 levels)
  - Maximum concurrent spawns (default: 3)
  - Time-to-live for spawned instances (default: 5 minutes)
- **Spawn tracking** with unique IDs and status monitoring
- **JSON-RPC protocol** compliance for MCP integration

## Installation

1. Ensure Node.js is installed (no external dependencies required)
2. The server is located at: `dev-tools/claude-spawner.js`
3. Make it executable: `chmod +x dev-tools/claude-spawner.js`

## Usage

### Starting the Server

```bash
node dev-tools/claude-spawner.js
```

### Environment Variables

Configure safety limits via environment variables:

```bash
export CLAUDE_MAX_SPAWN_DEPTH=2      # Maximum nesting depth
export CLAUDE_MAX_CONCURRENT=3       # Maximum concurrent spawns
export CLAUDE_MAX_TTL_MINUTES=5      # Time-to-live in minutes
```

### Available Tools

#### 1. `spawn_claude`

Spawns a new Claude instance with the given prompt.

**Parameters:**
- `prompt` (string, required): The task/prompt for the spawned Claude
- `model` (string, optional): Model to use (default: "sonnet")
- `directive` (string, optional): Execution directive (analyze, plan, execute, etc.)
- `max_rounds` (number, optional): Maximum thinking rounds
- `timeout` (number, optional): Timeout in seconds (default: 120)

**Example:**
```json
{
  "prompt": "Analyze the performance of our database queries",
  "model": "sonnet",
  "directive": "analyze",
  "max_rounds": 5
}
```

**Response:**
```json
{
  "content": [{
    "type": "text",
    "text": "SPAWNED claude_1234567890\n\n[Claude's response here]"
  }]
}
```

#### 2. `spawn_status`

Check the status of the spawning system and active spawns.

**Parameters:** None

**Response:**
```json
{
  "content": [{
    "type": "text",
    "text": "Spawning System Status:\n- Active spawns: 1\n- Max concurrent: 3\n- Max depth: 2\n- Max TTL: 5 minutes\n- Current depth: 0\n\nActive spawn IDs: claude_1234567890"
  }]
}
```

## Safety Mechanisms

### Spawn Depth Tracking

The system tracks spawn depth through the `CLAUDE_SPAWN_DEPTH` environment variable. Each spawned instance increments this value, preventing infinite recursion.

### Concurrent Spawn Limits

Only a limited number of Claude instances can run simultaneously. Once the limit is reached, new spawn requests are blocked until existing spawns complete or expire.

### Time-to-Live (TTL)

Each spawn has a maximum lifetime. After the TTL expires, the spawn is considered dead and removed from tracking, freeing up a slot for new spawns.

## Testing

A comprehensive test suite is provided:

```bash
node test_mcp_spawner_improved.js
```

The test verifies:
- Server initialization
- Tool discovery
- Status reporting
- Spawn execution
- Safety limit enforcement

## Integration with Claude

To use with Claude Code, add to your MCP settings:

```json
{
  "mcpServers": {
    "claude-spawner": {
      "command": "node",
      "args": ["/path/to/dev-tools/claude-spawner.js"],
      "env": {
        "CLAUDE_MAX_SPAWN_DEPTH": "2",
        "CLAUDE_MAX_CONCURRENT": "3"
      }
    }
  }
}
```

## Architecture

```
┌─────────────┐     JSON-RPC      ┌──────────────┐
│   Claude    │ ←───────────────→ │ MCP Server   │
│   (Host)    │                   │              │
└─────────────┘                   └──────┬───────┘
                                         │
                                         │ spawn()
                                         ↓
                                  ┌──────────────┐
                                  │ Claude Child │
                                  │  (depth: 1)  │
                                  └──────────────┘
```

## Best Practices

1. **Use specific directives** to guide spawned instances
2. **Set appropriate timeouts** based on task complexity
3. **Monitor spawn status** before creating new spawns
4. **Handle spawn failures** gracefully in your workflows
5. **Clean up completed spawns** by tracking their output

## Troubleshooting

### "Maximum concurrent spawns reached"
- Check active spawns with `spawn_status`
- Wait for spawns to complete or expire
- Increase `CLAUDE_MAX_CONCURRENT` if needed

### "Maximum spawn depth reached"
- Spawned Claude is trying to spawn another level
- Review your prompt to avoid recursive spawning
- Increase `CLAUDE_MAX_SPAWN_DEPTH` carefully

### Spawns timing out
- Increase the `timeout` parameter
- Simplify the prompt for faster execution
- Check if Claude CLI is responsive

## Future Enhancements

- Spawn result caching
- Inter-spawn communication
- Resource usage monitoring
- Spawn templates for common patterns
- Web dashboard for spawn monitoring