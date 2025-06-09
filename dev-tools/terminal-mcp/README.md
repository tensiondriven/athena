# Terminal MCP Server

Cross-platform command execution via subprocess.

## Features

- **Direct execution**: Uses subprocess for reliable command execution
- **Working directory support**: Execute commands in any directory
- **Timeout handling**: Configurable command timeouts
- **Output capture**: Returns both stdout and stderr
- **Cross-platform**: Works on any OS with Python

## Tool

### `execute_command`
Execute a bash command and return output.

**Parameters:**
- `command` (required): Bash command to execute
- `working_directory` (optional): Directory to execute command in
- `timeout` (optional): Timeout in seconds (default: 30)
- `shell` (optional): Execute via shell (default: true)

## Usage

```json
{
  "method": "tools/call",
  "params": {
    "name": "execute_command", 
    "arguments": {
      "command": "ls -la",
      "working_directory": "/Users/j/Code/athena"
    }
  }
}
```

## Implementation

- Uses Python subprocess module
- Captures stdout and stderr separately
- Provides clear status indicators
- Handles timeouts and errors gracefully