# Task Management MCP Project

## Overview
Lightweight task management system via MCP with disk-based storage → **so that** AI maintains work context across sessions and humans can see what's in progress

## Core Features
- Create/read/update task lists
- Start/stop tasks with automatic timing
- Current task appears in every tool response header
- Hierarchical tasks (parent/child relationships)
- Crash-safe disk persistence
- Quick task switching
- Elapsed time tracking

## API Design
```typescript
// Core functions
createTask(name: string, parent?: string): Task
listTasks(filter?: {status?: string, parent?: string}): Task[]
startTask(id: string): void
stopTask(id: string): void
getCurrentTask(): Task | null
deleteTask(id: string): void

// Data structure
interface Task {
  id: string
  name: string
  status: 'pending' | 'active' | 'completed' | 'paused'
  created: datetime
  started?: datetime
  stopped?: datetime
  parent?: string
  children?: string[]
}
```

## Storage Strategy
- Individual JSON files per task: `~/.athena/tasks/{timestamp}-{slug}.json`
- Active task marker: `~/.athena/tasks/.current` (contains task ID)
- Completed tasks archive: `~/.athena/tasks/archive/`
- No single index file → **so that** corruption risk is minimized

## File Format
```json
{
  "id": "20250611-193022-fix-login",
  "name": "Fix login bug", 
  "status": "active",
  "created": "2025-06-11T19:30:22Z",
  "started": "2025-06-11T19:30:22Z",
  "parent": "20250611-190000-sprint-23",
  "context": {"file": "auth.ts", "line": 42}
}
```

## Tool Response Integration
Since MCP cannot modify system messages, we prepend context to every tool response:
```
[Current Task: "Fix login bug" - 5m elapsed]
---
<actual tool response>
```

### Alternative Approaches Considered
1. **System message injection**: Not possible with MCP protocol
2. **Conversation proxy**: Would require custom LLM client
3. **Tool response headers**: ✓ Our chosen approach

## Similar Examples
- Todo.txt format (plain text)
- Taskwarrior (CLI task management)
- Org-mode (hierarchical tasks)

## Implementation Notes
- Use filesystem atomicity (write temp → rename)
- Each task in separate file prevents total data loss
- Use file locks for concurrent access
- Archive completed tasks after 30 days

## Usage Examples
```bash
# Start working on a task
mcp://task/start "fix-login-bug"

# Check current
mcp://task/current
> "Fix login bug" - started 5m ago

# List all active
mcp://task/list --status=active

# Complete current
mcp://task/stop --complete
```