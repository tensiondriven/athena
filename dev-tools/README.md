# Dev Tools

Development and testing utilities for the Athena project.

## Quick Start

```bash
# Install external dependencies
./setup-dependencies-simple.sh
```

## External Dependencies

External dependencies are installed to `vendor/` (gitignored).

### Current Dependencies:

- **claude-code-mcp** - Enhanced file operations, search, and code review capabilities
  - Source: https://github.com/auchenberg/claude-code-mcp
  - Installed to: `vendor/claude-code-mcp/`

## MCP Servers

Model Context Protocol servers for extending Claude capabilities:

### Built-in Servers:
- `claude-spawner-mcp.py` - Multi-agent orchestration with safety controls
- `agent-templates/` - YAML templates for agent directives and work packets

### External Servers:
- `claude-code` - Enhanced file operations (installed via setup script)
- `neo4j-cypher` - Knowledge graph queries
- `neo4j-memory` - Persistent memory storage

## Configuration

MCP server configuration is in `mcp_settings.json`. External dependencies use paths relative to the `vendor/` directory.

## Tools

### OpenCode Integration
- **`opencode-tool.sh`** - Comprehensive tool for OpenCode + Ollama integration
  ```bash
  ./opencode-tool.sh status      # Check status
  ./opencode-tool.sh test        # Run tests
  ./opencode-tool.sh run [args]  # Run opencode with fixed config
  ./opencode-tool.sh interactive # Interactive mode
  ```
  Works with llama3-groq-tool-use model for tool support. For complex tasks, use deepseek-r1 directly.

### Ollama Management
- **`ollama-status.sh`** - Interactive server status monitor with TUI
- **`ollama-quick-status.sh`** - Quick status check (non-interactive)
- **`ollama-api-cleanup.sh`** - Model cleanup utility (freed 1TB in last run!)

### `test-event-sender`
Single-file executable to verify Athena event collection pipeline functionality.

```bash
./test-event-sender
```

Sends a test event to the database and provides verification steps. See [README_TEST_EVENT_SENDER.md](README_TEST_EVENT_SENDER.md) for details.

### `work-pulse`
Visual indicator of recent development activity showing files changed in the last hour.

```bash
./work-pulse
```

### Terminal MCP
Cross-platform command execution server for MCP protocol.

```bash
cd terminal-mcp
python3 terminal_mcp_server.py
```

See [terminal-mcp/README.md](terminal-mcp/README.md) for details.

## Project Structure

```
dev-tools/
├── test-event-sender              # Event pipeline verification tool
├── work-pulse                     # Development activity monitor
├── terminal-mcp/                  # MCP command execution server
├── projects/                      # Third-party project workspace
└── third-party/                   # External dependencies
```