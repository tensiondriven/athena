#!/bin/bash

# Athena macOS Collector Installation Script
# Simple native installation for macOS

set -e

echo "🏠 Installing Athena macOS Collector..."

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not found"
    echo "Install Python 3 from https://python.org or via Homebrew: brew install python"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTOR_PATH="$SCRIPT_DIR/athena-collector-macos.py"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
python3 -m pip install --user -r "$SCRIPT_DIR/requirements.txt"

# Make collector script executable
chmod +x "$COLLECTOR_PATH"

# Test the installation
echo "🧪 Testing installation..."
if python3 "$COLLECTOR_PATH" --test; then
    echo "✅ Installation successful!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Run manually: python3 $COLLECTOR_PATH"
    echo "2. Set CLAUDE_COLLECTOR_URL environment variable if needed"
    echo "3. Use Ctrl+C to stop the collector"
    echo ""
    echo "💡 The collector will:"
    echo "   - Monitor Claude Code logs, Chrome bookmarks, Desktop, Downloads"
    echo "   - Store events locally in ~/.athena-collector/"
    echo "   - Send events to claude_collector server every 30 seconds"
    echo "   - Continue working offline if server is unavailable"
else
    echo "❌ Installation test failed"
    exit 1
fi