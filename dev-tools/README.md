# Dev Tools

Development and testing utilities for the Athena project.

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