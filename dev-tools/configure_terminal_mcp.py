#!/usr/bin/env python3
"""
Script to add Terminal MCP Server to Claude Code configuration
Safely updates the /Users/j/.claude.json file
"""

import json
import shutil
from pathlib import Path

def main():
    claude_config_path = Path("/Users/j/.claude.json")
    backup_path = Path("/Users/j/.claude.json.backup")
    
    # Create backup
    shutil.copy2(claude_config_path, backup_path)
    print(f"✅ Created backup: {backup_path}")
    
    # Load current configuration
    with open(claude_config_path, 'r') as f:
        config = json.load(f)
    
    # Find the athena project configuration
    athena_project_key = "/Users/j/Code/athena"
    
    if athena_project_key not in config:
        config[athena_project_key] = {
            "allowedTools": [],
            "history": [],
            "dontCrawlDirectory": False,
            "mcpContextUris": [],
            "mcpServers": {},
            "enabledMcpjsonServers": [],
            "disabledMcpjsonServers": [],
            "hasTrustDialogAccepted": True,
            "projectOnboardingSeenCount": 1
        }
        print(f"✅ Created new project config for {athena_project_key}")
    
    # Add our Terminal MCP Server
    terminal_mcp_config = {
        "athena-terminal": {
            "type": "stdio",
            "command": "python3",
            "args": ["/Users/j/Code/athena/dev-tools/terminal_mcp_server.py"],
            "env": {}
        }
    }
    
    # Update the mcpServers section
    config[athena_project_key]["mcpServers"].update(terminal_mcp_config)
    
    # Save updated configuration
    with open(claude_config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print("✅ Added Terminal MCP Server to Claude Code configuration:")
    print("   - Server name: athena-terminal")
    print("   - Command: python3")
    print("   - Script: /Users/j/Code/athena/dev-tools/terminal_mcp_server.py")
    print()
    print("🔄 Please restart Claude Code to activate the new MCP server")
    print("📝 Test with: send_terminal_command tool")

if __name__ == "__main__":
    main()