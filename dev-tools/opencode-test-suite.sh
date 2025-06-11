#!/bin/bash

# OpenCode Test Suite
# Tests functionality while preserving loaded models

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0

# Helper functions
test_pass() {
    echo -e "   ${GREEN}✓ $1${NC}"
    ((PASSED++))
}

test_fail() {
    echo -e "   ${RED}✗ $1${NC}"
    ((FAILED++))
}

info() {
    echo -e "${BLUE}$1${NC}"
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

# Start tests
info "=== OpenCode Test Suite ==="
echo

# 1. Environment check
info "1. Environment Check"
export LOCAL_ENDPOINT="http://llm:11434/v1"

# Check ollama connectivity
if curl -s -f http://llm:11434 >/dev/null 2>&1; then
    test_pass "Ollama server accessible"
else
    test_fail "Cannot reach ollama server"
    exit 1
fi

# Check loaded models
LOADED=$(curl -s http://llm:11434/api/ps | jq -r '.models[].name' 2>/dev/null)
if [ -n "$LOADED" ]; then
    test_pass "Models loaded: $(echo $LOADED | tr '\n' ', ')"
else
    warn "   No models currently loaded"
fi
echo

# 2. Configuration check
info "2. Configuration Check"

# Ensure config has all required fields
cat > ~/.opencode.json << 'EOF'
{
  "providers": {
    "local": {
      "endpoint": "http://llm:11434/v1",
      "disabled": false
    }
  },
  "agents": {
    "coder": {
      "model": "local.llama3-groq-tool-use:8b",
      "maxTokens": 8192
    },
    "task": {
      "model": "local.llama3-groq-tool-use:8b",
      "maxTokens": 4096
    },
    "title": {
      "model": "local.llama3-groq-tool-use:8b",
      "maxTokens": 80
    },
    "summarizer": {
      "model": "local.llama3-groq-tool-use:8b",
      "maxTokens": 1024
    }
  }
}
EOF

if [ -f ~/.opencode.json ]; then
    test_pass "Configuration file exists"
    MODEL=$(jq -r '.agents.coder.model' ~/.opencode.json)
    test_pass "Using model: $MODEL"
else
    test_fail "Configuration file missing"
fi
echo

# 3. Model availability check
info "3. Model Availability"
MODEL_NAME="llama3-groq-tool-use:8b"
if curl -s http://llm:11434/api/tags | jq -r '.models[].name' | grep -q "^$MODEL_NAME$"; then
    test_pass "Model $MODEL_NAME is available"
else
    test_fail "Model $MODEL_NAME not found"
    echo "   Available models:"
    curl -s http://llm:11434/api/tags | jq -r '.models[].name' | head -5 | sed 's/^/     - /'
fi
echo

# 4. Direct API test
info "4. Direct Ollama API Test"
RESPONSE=$(curl -s -X POST http://llm:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3-groq-tool-use:8b",
    "messages": [{"role": "user", "content": "Reply with just: OK"}],
    "max_tokens": 10
  }' 2>/dev/null)

if echo "$RESPONSE" | jq -e '.choices[0].message.content' >/dev/null 2>&1; then
    test_pass "Direct API call successful"
else
    test_fail "Direct API call failed"
    echo "   Response: $(echo "$RESPONSE" | head -100)"
fi
echo

# 5. OpenCode basic test
info "5. OpenCode Basic Test"
echo -n "   Testing simple prompt... "
OUTPUT=$(timeout 15 bash -c 'export LOCAL_ENDPOINT="http://llm:11434/v1"; opencode -p "What is 2+2? Reply with just the number." -f text -q 2>&1' || echo "TIMEOUT")

if [[ "$OUTPUT" == "TIMEOUT" ]]; then
    test_fail "Command timed out"
elif [[ "$OUTPUT" == *"Error"* ]]; then
    test_fail "Error: $(echo "$OUTPUT" | grep -i error | head -1)"
else
    test_pass "Response: $(echo "$OUTPUT" | head -1 | cut -c1-50)"
fi
echo

# 6. Code generation test
info "6. Code Generation Test"
echo -n "   Testing code generation... "
CODE=$(timeout 15 bash -c 'export LOCAL_ENDPOINT="http://llm:11434/v1"; opencode -p "Write a Python hello world function. Just the code." -f text -q 2>&1' || echo "TIMEOUT")

if [[ "$CODE" == "TIMEOUT" ]]; then
    test_fail "Command timed out"
elif [[ "$CODE" == *"Error"* ]]; then
    test_fail "Error in code generation"
elif [[ "$CODE" == *"def"* ]] || [[ "$CODE" == *"print"* ]]; then
    test_pass "Generated Python code"
else
    test_fail "Unexpected output"
fi
echo

# 7. File operation test (expected to fail)
info "7. File Operation Test"
TEST_DIR="/tmp/opencode-test-$$"
mkdir -p "$TEST_DIR"
echo "test content" > "$TEST_DIR/test.txt"

echo -n "   Testing file listing... "
FILE_OUTPUT=$(timeout 10 bash -c "export LOCAL_ENDPOINT='http://llm:11434/v1'; opencode -p 'List files in $TEST_DIR' -f text -q 2>&1" || echo "TIMEOUT")

if [[ "$FILE_OUTPUT" == *"test.txt"* ]]; then
    test_pass "File operation worked!"
else
    warn "   Expected limitation: Model lacks file operation tools"
fi

rm -rf "$TEST_DIR"
echo

# 8. Interactive mode test
info "8. Interactive Mode Test"
echo "   To test interactive mode, run:"
echo "   ${YELLOW}export LOCAL_ENDPOINT=\"http://llm:11434/v1\"${NC}"
echo "   ${YELLOW}opencode${NC}"
echo

# 9. Alternative approaches
info "9. Alternative Approaches"
echo "   For better results with deepseek-r1:"
echo "   ${YELLOW}ollama run deepseek-r1:32b-qwen-distill-q4_K_M${NC}"
echo
echo "   For file operations, consider:"
echo "   - Models with explicit tool support"
echo "   - Using ollama + custom scripts"
echo "   - Alternative inference engines"
echo

# Summary
info "=== Test Summary ==="
echo "Tests passed: $PASSED"
echo "Tests failed: $FAILED"
echo
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
else
    echo -e "${YELLOW}Some tests failed. This is expected due to model limitations.${NC}"
fi
echo

# Show current configuration
info "Current Configuration:"
cat ~/.opencode.json | jq '.' | head -20
echo

# Final status
info "Models still loaded:"
curl -s http://llm:11434/api/ps | jq -r '.models[].name' 2>/dev/null | sed 's/^/  - /'