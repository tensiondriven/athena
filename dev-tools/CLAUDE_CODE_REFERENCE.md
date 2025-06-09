# Claude Code Reference Guide

## Configuration Files & Settings

### Main Configuration
```bash
# Claude Code installation directory
/Users/j/.asdf/installs/nodejs/23.10.0/lib/node_modules/@anthropic-ai/claude-code/

# Core config files (need to find these)
~/.claude-code/settings.json
~/.claude-code/config.json
~/.claude-code/whitelist.json  # For git command allowlisting
```

### MCP Server Settings
```bash
# Per-project MCP settings (found in projects)
/Users/j/Code/athena/system/athena-capture/.claude/settings.local.json
/Users/j/Code/athena/system/ash-ai/.claude/settings.local.json
/Users/j/Code/athena/domains/events/storage/athena-capture/.claude/settings.local.json

# Our MCP configuration for dev tools
/Users/j/Code/athena/dev-tools/mcp_settings.json
```

### Logs & Debugging
```bash
# Claude Code logs
/Users/j/.claude-code/logs/

# Related settings
/Users/j/Library/Application Support/Claude/claude_desktop_config.json  # Claude Desktop (not Code)
```

## Key Directories Structure

```
Claude Code Installation:
├── /Users/j/.asdf/installs/nodejs/23.10.0/lib/node_modules/@anthropic-ai/claude-code/
│   ├── package.json
│   ├── bin/
│   ├── lib/
│   └── config/  # (hypothetical - need to explore)

User Configuration:
├── /Users/j/.claude-code/
│   ├── logs/
│   ├── settings.json  # (need to find/create)
│   ├── config.json    # (need to find/create)
│   └── whitelist.json # (need to find/create - for git commands)

Project-Specific:
├── <project>/.claude/
│   └── settings.local.json  # MCP server configs
```

## Common Tasks

### Enable Git Commands (Need to Research)
- Find whitelist/allowlist configuration
- Add git commands to approved list
- Alternative: Use Terminal MCP Server (implemented ✅)

### MCP Server Configuration
- Edit `<project>/.claude/settings.local.json`
- Or use our consolidated `/Users/j/Code/athena/dev-tools/mcp_settings.json`

### Debugging Connection Issues
- Check logs in `/Users/j/.claude-code/logs/`
- Verify MCP server paths and executability
- Test server manually with `python3 server.py`

## Our Custom Solutions

### Terminal MCP Server ✅
```bash
# Our bypass for command execution
/Users/j/Code/athena/dev-tools/terminal_mcp_server.py

# Configuration
/Users/j/Code/athena/dev-tools/mcp_settings.json
```

### Available MCP Servers
```bash
# Terminal control (our creation)
/Users/j/Code/athena/dev-tools/terminal-mcp/terminal_mcp_server.py

# GitHub integration
/Users/j/Code/athena/dev-tools/third-party/github-mcp-server/

# Neo4j integration
/Users/j/Code/athena/dev-tools/third-party/mcp-neo4j/servers/mcp-neo4j-cypher/
```

## Research Needed

### Configuration Files to Find
- [ ] Main Claude Code settings file location
- [ ] Git command allowlist/whitelist configuration
- [ ] Global MCP server registration
- [ ] Timeout and security settings

### Commands to Explore
```bash
# Find Claude Code settings
find /Users/j -name "*claude*code*" -type f 2>/dev/null

# Find git-related configurations
find /Users/j -name "*.json" -exec grep -l "git\|whitelist\|allowlist" {} \; 2>/dev/null

# Check Claude Code installation
ls -la /Users/j/.asdf/installs/nodejs/23.10.0/lib/node_modules/@anthropic-ai/claude-code/

# Look for hidden config directories
find /Users/j -name ".*claude*" -type d 2>/dev/null
```

## Troubleshooting

### Tool Approval Prompts
- **Problem**: Every bash command requires approval
- **Solutions**: 
  1. ✅ Use Terminal MCP Server (implemented)
  2. ⏳ Find git allowlist configuration
  3. ⏳ Configure command whitelist

### MCP Server Not Found
- Check file paths in configuration
- Verify Python/Node executable paths
- Test server startup manually
- Check logs for connection errors

### Permission Issues
- Verify file executability: `chmod +x server.py`
- Check AppleScript automation permissions
- Validate terminal access for AppleScript

---
*Reference compiled: 2025-06-08*
*Update this as we discover more configuration locations!*