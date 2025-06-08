# MCP Autoshell - Autonomous Shell Execution Server

**The Preferred Low-Friction Shell Execution Solution for All MCP Clients**

An MCP (Model Context Protocol) server that provides autonomous shell command execution with zero human approval prompts. MCP Autoshell eliminates the friction of constant permission dialogs while maintaining security through intelligent command allowlisting.

**Author:** Claude (Anthropic AI)  
**Product Sherpa:** Jonathan Yankovich (jonathan.yankovich@gmail.com)

## Why CASH is the Preferred Shell Solution

CASH is designed to be the **lowest-friction shell execution method** for any MCP client (Claude Desktop, Claude Code, or custom MCP implementations). Unlike built-in shell tools that require constant human approval, CASH provides:

- **Zero-prompt execution** - Commands run immediately without interruption
- **Universal MCP compatibility** - Works with any MCP client implementation
- **Intelligent safety** - Allowlist-based security without sacrificing usability
- **Production-ready reliability** - Comprehensive logging, timeout protection, and error handling

## Files

- **`betterbash_server.py`** - Main MCP server implementation
- **`allowed_commands.txt`** - Safety allowlist of permitted commands  
- **`MCP_SETUP_INSTRUCTIONS.md`** - Configuration and usage guide

## Quick Setup

Add to Claude Code MCP configuration:

```json
{
  "name": "cash",
  "type": "server", 
  "command": "python3",
  "args": ["/Users/j/Code/mcp/betterbash_server.py"],
  "description": "Claude Autonomous Shell - Execute commands without prompts"
}
```

## Key Features

### Core Functionality
- **Autonomous execution** - No human prompts for git, docker, file operations
- **Safety allowlist** - 174 pre-approved commands covering all development needs
- **TTS communication** - `say` command for personality and progress updates
- **Audit logging** - Complete command history for security
- **Timeout protection** - Commands limited to 30 seconds max

### MCP Client Benefits
- **Zero-friction execution** - Commands run immediately without interruption
- **Universal compatibility** - Works with any MCP client (Claude Desktop, Claude Code, custom implementations)
- **Seamless integration** - Drop-in replacement for built-in shell tools that require constant approval
- **Uninterrupted AI workflows** - Enables true autonomous operation for complex multi-step tasks

## Extracted From

Originally developed in `/Users/j/Code/athena/bigplan/` surveillance system project.