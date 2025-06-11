#!/bin/bash

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-llm}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OLLAMA_URL="http://${OLLAMA_HOST}:${OLLAMA_PORT}"

# Function to display header
display_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                  ${BOLD}${WHITE}Ollama Server Status Monitor${NC}                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Function to check if server is reachable
check_server() {
    echo -ne "${YELLOW}🔍 Checking server at ${OLLAMA_URL}...${NC}"
    if curl -s -f -o /dev/null "${OLLAMA_URL}"; then
        echo -e "\r${GREEN}✓ Server is online at ${OLLAMA_URL}    ${NC}"
        return 0
    else
        echo -e "\r${RED}✗ Server is offline or unreachable${NC}"
        return 1
    fi
}

# Function to get running models
get_running_models() {
    echo -e "\n${BLUE}📊 Running Models:${NC}"
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────${NC}"
    
    local response=$(curl -s "${OLLAMA_URL}/api/ps" 2>/dev/null)
    
    if [ -z "$response" ] || [ "$response" = "null" ]; then
        echo -e "${YELLOW}  No models currently loaded${NC}"
    else
        echo "$response" | jq -r '.models[]? | "\(.name) | Size: \(.size | tonumber / 1073741824 | tostring | split(".")[0:2] | join("."))GB | Expires: \(.expires_at)"' 2>/dev/null | while IFS='|' read -r name size expires; do
            echo -e "  ${GREEN}●${NC} ${WHITE}${name}${NC}"
            echo -e "    ${PURPLE}${size}${NC} | ${CYAN}${expires}${NC}"
        done
    fi
}

# Function to list available models
list_models() {
    echo -e "\n${BLUE}📦 Available Models:${NC}"
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────${NC}"
    
    local response=$(curl -s "${OLLAMA_URL}/api/tags" 2>/dev/null)
    
    if [ -z "$response" ]; then
        echo -e "${RED}  Failed to fetch model list${NC}"
    else
        echo "$response" | jq -r '.models[]? | "\(.name)|\(.size / 1073741824)|\(.modified_at)"' | while IFS='|' read -r name size modified; do
            size_gb=$(printf "%.1f" "$size")
            echo -e "  ${GREEN}●${NC} ${WHITE}${name}${NC}"
            echo -e "    Size: ${PURPLE}${size_gb}GB${NC} | Modified: ${CYAN}${modified:0:10}${NC}"
        done
    fi
}

# Function to test a model
test_model() {
    local model=$1
    echo -e "\n${BLUE}🧪 Testing model: ${WHITE}${model}${NC}"
    echo -ne "${YELLOW}  Loading model...${NC}"
    
    local start_time=$(date +%s)
    local response=$(curl -s -X POST "${OLLAMA_URL}/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"${model}\", \"prompt\": \"Hi\", \"stream\": false}" 2>/dev/null)
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ -n "$response" ] && echo "$response" | jq -e '.response' >/dev/null 2>&1; then
        echo -e "\r  ${GREEN}✓ Model loaded successfully${NC} (${duration}s)"
        local response_text=$(echo "$response" | jq -r '.response' | head -1)
        echo -e "  ${WHITE}Response:${NC} ${response_text}"
    else
        echo -e "\r  ${RED}✗ Failed to load model${NC}"
        if [ -n "$response" ]; then
            local error=$(echo "$response" | jq -r '.error // "Unknown error"' 2>/dev/null)
            echo -e "  ${RED}Error:${NC} ${error}"
        fi
    fi
}

# Function to show system info
show_system_info() {
    echo -e "\n${BLUE}💻 System Information:${NC}"
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────${NC}"
    
    # Try to get version
    local version=$(curl -s "${OLLAMA_URL}/api/version" 2>/dev/null | jq -r '.version // "Unknown"' 2>/dev/null)
    echo -e "  ${WHITE}Ollama Version:${NC} ${version}"
    echo -e "  ${WHITE}API Endpoint:${NC} ${OLLAMA_URL}"
    
    # Check if GPU is available (this is a simplified check)
    if command -v nvidia-smi &> /dev/null; then
        echo -e "  ${WHITE}GPU:${NC} ${GREEN}NVIDIA GPU detected${NC}"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "  ${WHITE}GPU:${NC} ${GREEN}Apple Silicon${NC}"
    else
        echo -e "  ${WHITE}GPU:${NC} ${YELLOW}CPU only${NC}"
    fi
}

# Function to monitor in real-time
monitor_mode() {
    while true; do
        display_header
        if check_server; then
            get_running_models
            echo -e "\n${WHITE}Press Ctrl+C to exit monitor mode${NC}"
        fi
        sleep 5
    done
}

# Main menu
main_menu() {
    while true; do
        display_header
        
        if ! check_server; then
            echo -e "\n${RED}Cannot connect to Ollama server at ${OLLAMA_URL}${NC}"
            echo -e "\n${YELLOW}Tips:${NC}"
            echo -e "  - Check if Ollama is running: ${WHITE}docker ps | grep ollama${NC}"
            echo -e "  - Start Ollama: ${WHITE}docker start ollama${NC}"
            echo -e "  - Check logs: ${WHITE}docker logs ollama${NC}"
            exit 1
        fi
        
        get_running_models
        show_system_info
        
        echo -e "\n${BLUE}📋 Options:${NC}"
        echo -e "${WHITE}─────────────────────────────────────────────────────────────────${NC}"
        echo -e "  ${WHITE}1)${NC} List all available models"
        echo -e "  ${WHITE}2)${NC} Test a specific model"
        echo -e "  ${WHITE}3)${NC} Monitor mode (auto-refresh)"
        echo -e "  ${WHITE}4)${NC} Refresh"
        echo -e "  ${WHITE}5)${NC} Exit"
        
        echo -ne "\n${CYAN}Select option:${NC} "
        read -r choice
        
        case $choice in
            1)
                list_models
                echo -ne "\n${WHITE}Press Enter to continue...${NC}"
                read -r
                ;;
            2)
                list_models
                echo -ne "\n${CYAN}Enter model name to test:${NC} "
                read -r model_name
                if [ -n "$model_name" ]; then
                    test_model "$model_name"
                    echo -ne "\n${WHITE}Press Enter to continue...${NC}"
                    read -r
                fi
                ;;
            3)
                monitor_mode
                ;;
            4)
                continue
                ;;
            5)
                echo -e "\n${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Run main menu
main_menu