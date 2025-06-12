#!/bin/bash
# Check GitHub Pages deployment status

echo "=== GitHub Pages Status Check ==="
echo "Time: $(date)"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Install with: brew install gh"
    exit 1
fi

# Check Pages configuration
echo "📋 Pages Configuration:"
gh api repos/tensiondriven/athena/pages --jq '"  Branch: " + .source.branch + "\n  Path: " + .source.path + "\n  Status: " + .status' 2>/dev/null || echo "  ❌ Failed to get Pages config"
echo ""

# Check recent builds
echo "🔨 Recent Builds:"
gh api repos/tensiondriven/athena/pages/builds --jq '.[0:5] | .[] | "  " + .created_at + " - " + .status + if .error.message then " (" + .error.message + ")" else "" end' 2>/dev/null || echo "  ❌ Failed to get build history"
echo ""

# Check site availability
echo "🌐 Site Status:"
response=$(curl -s -o /dev/null -w "%{http_code}" https://tensiondriven.github.io/athena/)
if [[ "$response" == "200" ]]; then
    echo "  ✅ Site is live (HTTP $response)"
elif [[ "$response" == "404" ]]; then
    echo "  ⚠️  Site returns 404 - may be building or failed"
else
    echo "  ❌ Unexpected response: HTTP $response"
fi
echo ""

# Save status to log file (without full history to avoid conflicts)
LOG_FILE="docs/github-pages-status.log"
{
    echo "Last checked: $(date)"
    echo -n "Status: "
    gh api repos/tensiondriven/athena/pages --jq '.status' 2>/dev/null || echo "unknown"
    echo -n "Site response: "
    echo "$response"
} > "$LOG_FILE"

echo "📝 Status saved to $LOG_FILE"

# Exit with appropriate code
if [[ "$response" == "200" ]]; then
    exit 0
else
    exit 1
fi