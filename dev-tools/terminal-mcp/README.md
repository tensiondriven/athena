# Terminal MCP Server

**Preferred** bash execution for macOS via AppleScript + iTerm integration.

## Features

- **Isolated execution**: Targets dedicated "athena" terminal pane
- **Working directory support**: Change directory before command execution  
- **Command completion detection**: Waits for prompt return before reading output
- **Auto-setup**: Creates athena pane if it doesn't exist
- **Clean output**: No hardcoded directory changes or magic interactions

## Tools

### `send_terminal_command`
Send a bash command to the athena terminal pane.

**Parameters:**
- `command` (required): Bash command to execute
- `working_directory` (optional): Directory to cd to before execution
- `timeout` (optional): Timeout in seconds (default: 30)

### `read_terminal_buffer`  
Read current contents of the athena terminal pane.

**Parameters:**
- `lines` (optional): Number of lines to read (default: 50)

### `send_command_and_read`
Send command, wait for completion, then return output.

**Parameters:**
- `command` (required): Bash command to execute
- `working_directory` (optional): Directory to cd to before execution  
- `wait_for_completion` (optional): Wait for command completion (default: true)
- `max_wait_seconds` (optional): Max wait time for completion (default: 10)
- `timeout` (optional): Timeout in seconds (default: 30)

## Usage

Prefer `send_command_and_read` for most AI interactions as it provides immediate feedback.

```json
{
  "method": "tools/call",
  "params": {
    "name": "send_command_and_read", 
    "arguments": {
      "command": "ls -la",
      "working_directory": "/Users/j/Code/athena"
    }
  }
}
```

## Implementation

- Uses dedicated AppleScript files for each operation
- Targets iTerm2 sessions named "athena"
- Provides rich status feedback with emoji indicators
- Handles edge cases (missing session, timeouts, errors)