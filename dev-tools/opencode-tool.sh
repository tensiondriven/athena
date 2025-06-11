#!/bin/bash

# OpenCode Tool - Test and use OpenCode with local ollama
# Part of the Athena project dev-tools collection

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-llm}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OLLAMA_URL="http://${OLLAMA_HOST}:${OLLAMA_PORT}"
LOCAL_ENDPOINT="${OLLAMA_URL}/v1"

# OpenCode configuration
OPENCODE_CONFIG="$HOME/.opencode.json"
OPENCODE_MODEL="llama3-groq-tool-use:8b"

# Functions
info() { echo -e "${BLUE}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }
error() { echo -e "${RED}$1${NC}"; }

# Fix OpenCode config (it gets auto-modified)
fix_config() {
    cat > "$OPENCODE_CONFIG" << EOF
{
  "providers": {
    "local": {
      "endpoint": "${LOCAL_ENDPOINT}",
      "disabled": false
    }
  },
  "agents": {
    "coder": {
      "model": "local.${OPENCODE_MODEL}",
      "maxTokens": 8192
    },
    "task": {
      "model": "local.${OPENCODE_MODEL}",
      "maxTokens": 4096
    },
    "title": {
      "model": "local.${OPENCODE_MODEL}",
      "maxTokens": 80
    },
    "summarizer": {
      "model": "local.${OPENCODE_MODEL}",
      "maxTokens": 1024
    }
  }
}
EOF
}

# Check ollama status
check_ollama() {
    if curl -s -f "${OLLAMA_URL}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Show loaded models
show_models() {
    curl -s "${OLLAMA_URL}/api/ps" 2>/dev/null | jq -r '.models[].name' 2>/dev/null
}

# Run OpenCode with proper environment
run_opencode() {
    fix_config
    export LOCAL_ENDPOINT="${LOCAL_ENDPOINT}"
    opencode "$@"
}

# Test OpenCode
test_opencode() {
    info "Testing OpenCode..."
    fix_config
    export LOCAL_ENDPOINT="${LOCAL_ENDPOINT}"
    
    echo "Test 1: Code explanation"
    timeout 20 opencode -p "What is a Python decorator? One sentence." -f text -q 2>&1 || echo "Test failed"
    
    echo
    echo "Test 2: Code generation"
    timeout 20 opencode -p "Write a Python function to reverse a string. Just the code." -f text -q 2>&1 || echo "Test failed"
}

# Main menu
case "${1:-help}" in
    status)
        info "=== OpenCode Tool Status ==="
        echo
        if check_ollama; then
            success "✓ Ollama server: Online at ${OLLAMA_URL}"
        else
            error "✗ Ollama server: Offline"
            exit 1
        fi
        
        echo
        info "Loaded models:"
        show_models | sed 's/^/  /'
        
        echo
        info "OpenCode configuration:"
        echo "  Model: ${OPENCODE_MODEL}"
        echo "  Config: ${OPENCODE_CONFIG}"
        echo "  Endpoint: ${LOCAL_ENDPOINT}"
        
        echo
        if command -v opencode >/dev/null 2>&1; then
            success "✓ OpenCode: Installed"
        else
            error "✗ OpenCode: Not found"
        fi
        ;;
        
    test)
        test_opencode
        ;;
        
    run)
        shift
        run_opencode "$@"
        ;;
        
    interactive)
        info "Starting OpenCode in interactive mode..."
        info "Note: Use deepseek-r1 directly for complex tasks"
        echo
        run_opencode
        ;;
        
    fix-config)
        info "Fixing OpenCode configuration..."
        fix_config
        success "✓ Configuration updated"
        ;;
        
    models)
        info "=== Available Models ==="
        echo
        info "Currently loaded:"
        show_models | sed 's/^/  ✓ /'
        
        echo
        info "Models with tool support:"
        echo "  • llama3-groq-tool-use:8b (configured)"
        echo "  • Check ollama library for others"
        
        echo
        info "For complex tasks use:"
        echo "  ollama run deepseek-r1:32b-qwen-distill-q4_K_M"
        ;;
        
    help|*)
        info "=== OpenCode Tool ==="
        echo "Manage and test OpenCode with local ollama models"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  status       Show ollama and OpenCode status"
        echo "  test         Run basic OpenCode tests"
        echo "  run [args]   Run opencode with fixed config"
        echo "  interactive  Start OpenCode interactive mode"
        echo "  fix-config   Fix OpenCode configuration"
        echo "  models       Show available models"
        echo "  help         Show this help"
        echo
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 test"
        echo "  $0 run -p \"Write hello world in Python\" -f text -q"
        echo "  $0 interactive"
        echo
        echo "Note: OpenCode requires models with tool/function support."
        echo "      For full capabilities, use deepseek-r1 directly."
        ;;
esac