#!/bin/bash

# Ollama Integration Test Runner
# Tests the LiveView chat integration with Ollama

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Ollama Chat Integration Test ===${NC}"
echo ""

# Check if Ollama is accessible
echo -n "Checking Ollama connection at http://10.1.2.200:11434... "
if curl -s -f http://10.1.2.200:11434/api/tags >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
    echo -e "${RED}Error: Cannot connect to Ollama at http://10.1.2.200:11434${NC}"
    echo "Please ensure Ollama is running and accessible."
    exit 1
fi

# Check if server is running
echo -n "Checking Phoenix server... "
if lsof -i :4000 -t >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${YELLOW}⚠ Not running${NC}"
    echo "Starting Phoenix server..."
    ./server.sh start
    sleep 3
fi

echo ""
echo -e "${BLUE}Running integration test...${NC}"
echo "This will:"
echo "  1. Open the chat interface"
echo "  2. Send a test message to Ollama"
echo "  3. Verify we get a response"
echo ""

# Run only the integration tests
MIX_ENV=test mix test test/ash_chat_web/integration/ollama_chat_test.exs --only integration --trace

# Capture exit code
TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo -e "${GREEN}The LiveView chat successfully communicated with Ollama.${NC}"
else
    echo -e "${RED}❌ Tests failed!${NC}"
    echo -e "${RED}Check the output above for details.${NC}"
fi

exit $TEST_EXIT_CODE