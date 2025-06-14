#!/bin/bash
# Simple dependency setup for Athena dev tools
# Usage: ./setup-dependencies-simple.sh

set -e

echo "🔧 Setting up dependencies..."

# Create vendor directory if needed
mkdir -p vendor

# Clone claude-code-mcp if not present
if [ ! -d "vendor/claude-code-mcp" ]; then
    echo "📦 Installing claude-code-mcp..."
    git clone https://github.com/auchenberg/claude-code-mcp.git vendor/claude-code-mcp
    cd vendor/claude-code-mcp && npm install && npm run build && cd ../..
    echo "✅ Done!"
else
    echo "✅ claude-code-mcp already installed"
fi

echo ""
echo "🎉 Setup complete! Dependencies are in vendor/"
echo "💡 Remember: vendor/ is gitignored"