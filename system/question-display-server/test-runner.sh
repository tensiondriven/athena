#!/bin/bash

# Comprehensive Manual Test Runner for Question Display Server
# This script provides a guided manual testing experience

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_PORT=2900
SERVER_PID_FILE=".server.pid"

echo -e "${BLUE}🚀 Question Display Server - Comprehensive Manual Test${NC}"
echo "====================================================="

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    if [ -f "$SERVER_PID_FILE" ]; then
        SERVER_PID=$(cat "$SERVER_PID_FILE")
        if kill -0 "$SERVER_PID" 2>/dev/null; then
            echo -e "${YELLOW}   Stopping server (PID: $SERVER_PID)${NC}"
            kill "$SERVER_PID"
            wait "$SERVER_PID" 2>/dev/null || true
        fi
        rm -f "$SERVER_PID_FILE"
    fi
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

# Function to check if port is available
check_port() {
    if lsof -i :$SERVER_PORT >/dev/null 2>&1; then
        echo -e "${RED}❌ Port $SERVER_PORT is already in use${NC}"
        echo -e "${YELLOW}   Please stop any existing servers and try again${NC}"
        exit 1
    fi
}

# Function to wait for server to be ready
wait_for_server() {
    echo -e "${YELLOW}⏳ Waiting for server to be ready...${NC}"
    local retries=0
    local max_retries=10
    
    while [ $retries -lt $max_retries ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVER_PORT/ | grep -q "404"; then
            echo -e "${GREEN}✅ Server is ready!${NC}"
            return 0
        fi
        sleep 1
        retries=$((retries + 1))
        echo -e "${YELLOW}   Attempt $retries/$max_retries...${NC}"
    done
    
    echo -e "${RED}❌ Server failed to start within $max_retries seconds${NC}"
    return 1
}

# Function to run automated tests
run_automated_tests() {
    echo -e "\n${BLUE}🤖 Running Automated Server Tests${NC}"
    echo "=================================="
    
    # Test 404 endpoint
    echo -e "${YELLOW}   Testing 404 response...${NC}"
    local response=$(curl -s -w "%{http_code}" http://localhost:$SERVER_PORT/nonexistent)
    if echo "$response" | grep -q "404"; then
        echo -e "${GREEN}   ✅ 404 endpoint working${NC}"
    else
        echo -e "${RED}   ❌ 404 endpoint failed${NC}"
        return 1
    fi
    
    # Test POST endpoint structure
    echo -e "${YELLOW}   Testing POST endpoint response...${NC}"
    local post_response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" \
        -d '{"question":"Test","options":["A","B"]}' \
        http://localhost:$SERVER_PORT/display-question)
    if echo "$post_response" | grep -q "200"; then
        echo -e "${GREEN}   ✅ POST endpoint responding correctly${NC}"
    else
        echo -e "${RED}   ❌ POST endpoint failed${NC}"
        return 1
    fi
}

# Function to display manual test instructions
show_manual_tests() {
    echo -e "\n${BLUE}🧪 Manual Testing Instructions${NC}"
    echo "=============================="
    echo ""
    echo -e "${YELLOW}📋 Test Case 1: True/False Question${NC}"
    echo "   Copy and paste this command in a new terminal:"
    echo ""
    echo -e "${GREEN}   curl -X POST -H \"Content-Type: application/json\" \\${NC}"
    echo -e "${GREEN}        -d '{\"question\":\"Is the sky blue?\",\"options\":[\"True\",\"False\"]}' \\${NC}"
    echo -e "${GREEN}        http://localhost:$SERVER_PORT/display-question${NC}"
    echo ""
    echo -e "${BLUE}   Expected result:${NC}"
    echo -e "${BLUE}   - Response: 'Question displayed'${NC}"
    echo -e "${BLUE}   - Dialog appears with question and True/False options${NC}"
    echo -e "${BLUE}   - Your selection is logged in this terminal${NC}"
    echo ""
    
    echo -e "${YELLOW}📋 Test Case 2: Multiple Choice Question${NC}"
    echo "   Copy and paste this command in a new terminal:"
    echo ""
    echo -e "${GREEN}   curl -X POST -H \"Content-Type: application/json\" \\${NC}"
    echo -e "${GREEN}        -d '{\"question\":\"What is 2 + 2?\",\"options\":[\"3\",\"4\",\"5\",\"6\"]}' \\${NC}"
    echo -e "${GREEN}        http://localhost:$SERVER_PORT/display-question${NC}"
    echo ""
    echo -e "${BLUE}   Expected result:${NC}"
    echo -e "${BLUE}   - Response: 'Question displayed'${NC}"
    echo -e "${BLUE}   - Dialog appears with question and A/B/C/D options${NC}"
    echo -e "${BLUE}   - Your selection is logged in this terminal${NC}"
    echo ""
    
    echo -e "${YELLOW}📋 Test Case 3: Edge Cases${NC}"
    echo "   Test with special characters:"
    echo ""
    echo -e "${GREEN}   curl -X POST -H \"Content-Type: application/json\" \\${NC}"
    echo -e "${GREEN}        -d '{\"question\":\"Test @#\$%^&*()?\",\"options\":[\"Option 1\",\"Option 2\"]}' \\${NC}"
    echo -e "${GREEN}        http://localhost:$SERVER_PORT/display-question${NC}"
    echo ""
    
    echo -e "${YELLOW}📋 Test Case 4: Error Handling${NC}"
    echo "   Test invalid endpoint:"
    echo ""
    echo -e "${GREEN}   curl http://localhost:$SERVER_PORT/invalid${NC}"
    echo ""
    echo -e "${BLUE}   Expected result: 'Not Found'${NC}"
    echo ""
    
    echo -e "${YELLOW}📋 Test Case 5: Invalid JSON${NC}"
    echo "   Test malformed JSON:"
    echo ""
    echo -e "${GREEN}   curl -X POST -H \"Content-Type: application/json\" \\${NC}"
    echo -e "${GREEN}        -d 'invalid json' \\${NC}"
    echo -e "${GREEN}        http://localhost:$SERVER_PORT/display-question${NC}"
    echo ""
    echo -e "${BLUE}   Expected result: Error handled gracefully${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}📋 Pre-flight checks...${NC}"
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${YELLOW}⚠️  Warning: This application is designed for macOS${NC}"
        echo -e "${YELLOW}   AppleScript dialogs may not work on other systems${NC}"
    fi
    
    # Check dependencies
    if ! command -v node >/dev/null 2>&1; then
        echo -e "${RED}❌ Node.js is not installed${NC}"
        exit 1
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}❌ curl is not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Pre-flight checks passed${NC}"
    
    # Check if port is available
    check_port
    
    # Start the server
    echo -e "\n${BLUE}🚀 Starting server...${NC}"
    node index.js &
    SERVER_PID=$!
    echo $SERVER_PID > "$SERVER_PID_FILE"
    echo -e "${GREEN}   Server started with PID: $SERVER_PID${NC}"
    
    # Wait for server to be ready
    if ! wait_for_server; then
        exit 1
    fi
    
    # Run automated tests
    run_automated_tests
    
    # Show manual test instructions
    show_manual_tests
    
    echo -e "${YELLOW}💡 The server is now running and ready for testing!${NC}"
    echo -e "${YELLOW}💡 Watch this terminal for user selection logs${NC}"
    echo -e "${YELLOW}💡 Press Ctrl+C to stop the server when done${NC}"
    echo ""
    
    # Keep server running
    wait $SERVER_PID 2>/dev/null || echo -e "\n${GREEN}✅ Server stopped${NC}"
}

# Run main function
main "$@"