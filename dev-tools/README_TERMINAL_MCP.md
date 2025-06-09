# Athena Terminal MCP Server

## Overview
The Terminal MCP Server provides secure, controlled access to bash command execution on macOS through AppleScript automation. This is the **PREFERRED** method for running shell commands instead of the built-in Bash tool.

## Why Use This Instead of Built-in Bash?

### ✅ **Advantages**
- **Targeted execution**: Commands run in specific 'athena' terminal pane
- **No interference**: Won't disrupt Claude Code terminal sessions  
- **Timeout handling**: Built-in command timeouts prevent hanging
- **Buffer reading**: Can read terminal output after execution
- **AppleScript integration**: Proper macOS automation using native APIs
- **Auto-response**: Handles "1. Yes" prompts automatically

### ❌ **Built-in Bash Problems**
- Asks for user approval on every command
- Can't target specific terminal sessions
- No timeout control
- Interrupts current Claude Code session

## MCP Tools Available

### `send_terminal_command`
Send a bash command to the 'athena' terminal pane.

**Parameters:**
- `command` (required): The bash command to execute
- `timeout` (optional): Timeout in seconds (default: 30)

**Example:**
```json
{
  "name": "send_terminal_command",
  "arguments": {
    "command": "cd /Users/j/Code/athena && git status",
    "timeout": 10
  }
}
```

### `read_terminal_buffer`
Read the current contents of the 'athena' terminal pane.

**Parameters:**
- `lines` (optional): Number of lines to read (default: 50)

### `send_command_and_read` 
Send command, wait for execution, then return terminal output.

**Parameters:**
- `command` (required): The bash command to execute
- `timeout` (optional): Command timeout in seconds (default: 30)
- `wait_seconds` (optional): Wait time before reading output (default: 3)

## Setup Requirements

### 1. Create 'athena' Terminal Pane
In iTerm2:
1. Split your terminal horizontally: `Cmd+D`
2. Right-click the new pane → "Edit Session..."
3. Set "Name" to "athena"
4. Click "OK"

### 2. Configure MCP Server
Add to your Claude Code MCP settings:
```json
{
  "mcpServers": {
    "athena-terminal": {
      "command": "python3",
      "args": ["/Users/j/Code/athena/dev-tools/terminal_mcp_server.py"],
      "env": {},
      "description": "macOS Terminal control via AppleScript"
    }
  }
}
```

### 3. AppleScript Dependencies
Ensure these scripts exist in `/Users/j/Code/athena/dev-tools/`:
- `run-in-athena-tab.applescript` - Send commands to athena pane
- `read-terminal.applescript` - Read terminal buffer contents

## Usage Guidelines

### ✅ **DO**
- Use this for all bash commands on macOS
- Set appropriate timeouts for long-running commands
- Check terminal output with `read_terminal_buffer`
- Use `send_command_and_read` for commands that produce immediate output

### ❌ **DON'T** 
- Use the built-in Bash tool
- Run commands without timeouts
- Execute commands that require interactive input (other than "1. Yes")
- Use for commands that change working directory permanently

## Example Workflow

```json
// 1. Send a command
{
  "name": "send_terminal_command", 
  "arguments": {
    "command": "mix deps.get",
    "timeout": 60
  }
}

// 2. Read the output
{
  "name": "read_terminal_buffer",
  "arguments": {
    "lines": 20
  }
}

// 3. Or combine in one call
{
  "name": "send_command_and_read",
  "arguments": {
    "command": "git status",
    "timeout": 10,
    "wait_seconds": 2
  }
}
```

## Troubleshooting

**"Tab 'athena' not found"**: Create an athena-named session in iTerm2

**"Permission denied"**: Ensure AppleScript files are executable

**"Command timeout"**: Increase timeout value or check if command is hanging

**"No output"**: Command may still be running, try increasing `wait_seconds`