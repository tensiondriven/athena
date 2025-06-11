#!/bin/bash

# Quick non-interactive ollama status check

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-llm}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OLLAMA_URL="http://${OLLAMA_HOST}:${OLLAMA_PORT}"

echo -e "${CYAN}Ollama Server Status${NC}"
echo -e "${WHITE}───────────────────────────────────────────${NC}"

# Check server
if curl -s -f -o /dev/null "${OLLAMA_URL}"; then
    echo -e "${GREEN}✓ Server:${NC} Online at ${OLLAMA_URL}"
    
    # Get version
    version=$(curl -s "${OLLAMA_URL}/api/version" 2>/dev/null | jq -r '.version // "Unknown"' 2>/dev/null)
    echo -e "${GREEN}✓ Version:${NC} ${version}"
    
    # Get running models
    echo -e "\n${BLUE}Running Models:${NC}"
    response=$(curl -s "${OLLAMA_URL}/api/ps" 2>/dev/null)
    
    if [ -z "$response" ] || [ "$response" = "null" ] || [ "$(echo "$response" | jq -r '.models | length' 2>/dev/null)" = "0" ]; then
        echo -e "  ${YELLOW}No models currently loaded${NC}"
    else
        echo "$response" | jq -r '.models[]? | "  • \(.name) (\(.size | tonumber / 1073741824 | tostring | split(".")[0:2] | join("."))GB)"' 2>/dev/null
    fi
    
    # List available models count
    model_count=$(curl -s "${OLLAMA_URL}/api/tags" 2>/dev/null | jq -r '.models | length' 2>/dev/null)
    echo -e "\n${BLUE}Available Models:${NC} ${model_count} total"
    
    # Show first 5 models
    echo "$(curl -s "${OLLAMA_URL}/api/tags" 2>/dev/null | jq -r '.models[0:5][]? | "  • \(.name) (\(.size / 1073741824 | tostring | split(".")[0:2] | join("."))GB)"' 2>/dev/null)"
    
    if [ "$model_count" -gt 5 ]; then
        echo -e "  ${CYAN}... and $((model_count - 5)) more${NC}"
    fi
    
else
    echo -e "${RED}✗ Server:${NC} Offline or unreachable"
    echo -e "\n${YELLOW}Tips:${NC}"
    echo -e "  • Check if Ollama is running: ${WHITE}docker ps | grep ollama${NC}"
    echo -e "  • Start Ollama: ${WHITE}docker start ollama${NC}"
    echo -e "  • View logs: ${WHITE}docker logs ollama${NC}"
    exit 1
fi