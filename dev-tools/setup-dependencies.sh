#!/bin/bash
# External Dependency Manager for Athena Dev Tools
# 
# PURPOSE: Installs external tools to vendor/ instead of committing them to git
# USAGE: ./setup-dependencies.sh
# OUTPUT: vendor/ directory with built tools, updated mcp_settings.json paths
#
# AI CONTEXT: This keeps the repo clean while ensuring reproducible builds.
# The vendor/ directory is gitignored. Run this script in any fresh environment.

set -e

VENDOR_DIR="$(dirname "$0")/vendor"

# Status check mode
if [ "$1" = "status" ]; then
    echo "🔍 Dependency Status Check"
    echo ""
    if [ -d "$VENDOR_DIR/claude-code-mcp" ] && [ -f "$VENDOR_DIR/claude-code-mcp/dist/index.js" ]; then
        echo "✅ claude-code-mcp: INSTALLED and BUILT"
    else
        echo "❌ claude-code-mcp: MISSING or NOT BUILT"
    fi
    echo ""
    echo "🤖 AI TIP: Run './setup-dependencies.sh' to install missing dependencies"
    exit 0
fi

mkdir -p "$VENDOR_DIR"

echo "🔧 Setting up external dependencies..."

# Claude Code MCP Server
echo "📦 Installing claude-code-mcp..."
if [ ! -d "$VENDOR_DIR/claude-code-mcp" ]; then
    cd "$VENDOR_DIR"
    git clone https://github.com/auchenberg/claude-code-mcp.git
    cd claude-code-mcp
    npm install
    npm run build
    echo "✅ claude-code-mcp installed and built"
else
    echo "✅ claude-code-mcp already exists"
fi

# Update MCP settings to point to vendor directory
echo "🔧 Updating MCP settings..."
MCP_SETTINGS="../mcp_settings.json"
if [ -f "$MCP_SETTINGS" ]; then
    # Update the claude-code path to use vendor directory
    sed -i.bak 's|"args": \["/Users/j/Code/athena/dev-tools/claude-code-mcp/dist/index.js"\]|"args": ["'$(pwd)'/vendor/claude-code-mcp/dist/index.js"]|' "$MCP_SETTINGS"
    echo "✅ MCP settings updated"
fi

echo "🎉 All dependencies installed!"
echo ""
echo "📁 Dependencies installed in: $VENDOR_DIR"
echo "🔧 MCP settings updated: ../mcp_settings.json"
echo ""
echo "🤖 AI CONTEXT:"
echo "   - vendor/ is gitignored - run this script in fresh environments"
echo "   - claude-code-mcp provides enhanced file operations for Claude"
echo "   - Paths in mcp_settings.json now point to vendor/ directory"
echo ""
echo "To verify: ls -la $VENDOR_DIR"
echo "To reinstall: rm -rf $VENDOR_DIR && ./setup-dependencies.sh"