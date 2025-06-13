#!/bin/bash

# Test script for Ollama API model loading status detection
# Based on Ollama API documentation research

echo "=== Ollama Model Loading Status Testing ==="
echo "This script tests various Ollama API endpoints to detect model loading states"
echo

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
TEST_MODEL="${TEST_MODEL:-llama3.2:1b}"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to make API calls and display results
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -e "${YELLOW}Testing: $description${NC}"
    echo "Endpoint: $OLLAMA_HOST$endpoint"
    if [ -n "$data" ]; then
        echo "Data: $data"
    fi
    echo
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s "$OLLAMA_HOST$endpoint")
    else
        response=$(curl -s -X "$method" "$OLLAMA_HOST$endpoint" -d "$data")
    fi
    
    if [ -n "$response" ]; then
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        echo -e "${RED}No response${NC}"
    fi
    echo "---"
    echo
}

# Test 1: Check if Ollama is running
echo -e "${GREEN}1. Testing Ollama availability${NC}"
api_call GET "/" "" "Check if Ollama server is responding"

# Test 2: List available models
echo -e "${GREEN}2. Listing available models${NC}"
api_call GET "/api/tags" "" "List all available models with details"

# Test 3: Show model details
echo -e "${GREEN}3. Getting model details${NC}"
api_call POST "/api/show" "{\"name\": \"$TEST_MODEL\"}" "Get detailed information about a specific model"

# Test 4: Check model with streaming disabled (to see all metadata)
echo -e "${GREEN}4. Testing generate endpoint with metadata${NC}"
api_call POST "/api/generate" "{\"model\": \"$TEST_MODEL\", \"prompt\": \"test\", \"stream\": false}" "Generate with streaming disabled to see all timing metadata"

# Test 5: Pull model status (simulates downloading)
echo -e "${GREEN}5. Testing pull endpoint for download status${NC}"
echo "Note: This will show download progress if model is not already downloaded"
# Using a small model for testing
curl -s -X POST "$OLLAMA_HOST/api/pull" -d '{"name": "llama3.2:1b", "stream": true}' | while IFS= read -r line; do
    if [ -n "$line" ]; then
        echo "$line" | jq -r '.status // empty' 2>/dev/null
        # Show download progress if available
        echo "$line" | jq -r 'if .completed and .total then "\(.completed) / \(.total) bytes" else empty end' 2>/dev/null
    fi
done | head -20
echo

# Test 6: Monitor model loading with ps endpoint (if available)
echo -e "${GREEN}6. Testing ps endpoint (running models)${NC}"
api_call GET "/api/ps" "" "List running models (may not be available in all versions)"

# Test 7: Create a monitoring function for model loading
echo -e "${GREEN}7. Model Loading Monitor Function${NC}"
cat << 'EOF'
# Function to monitor model loading status
monitor_model_loading() {
    local model=$1
    local prompt="test"
    
    echo "Monitoring model loading for: $model"
    
    # Start time
    start_time=$(date +%s)
    
    # Make a generate request and capture the response
    response=$(curl -s -X POST "$OLLAMA_HOST/api/generate" \
        -d "{\"model\": \"$model\", \"prompt\": \"$prompt\", \"stream\": false}")
    
    # End time
    end_time=$(date +%s)
    
    # Extract timing information
    if [ -n "$response" ]; then
        echo "$response" | jq '{
            model_loaded: (.load_duration > 0),
            load_duration_ms: (.load_duration / 1000000),
            total_duration_ms: (.total_duration / 1000000),
            prompt_eval_duration_ms: (.prompt_eval_duration / 1000000),
            eval_duration_ms: (.eval_duration / 1000000),
            response_time_seconds: '"$((end_time - start_time))"'
        }'
    fi
}

# Example usage:
# monitor_model_loading "llama3.2:1b"
EOF

echo
echo -e "${GREEN}Summary of findings:${NC}"
echo "1. Use /api/generate with stream=false to get load_duration metadata"
echo "2. Use /api/pull with stream=true to monitor download progress"
echo "3. Use /api/tags to list available models"
echo "4. Use /api/show to get model details"
echo "5. Monitor load_duration in response to detect if model was loaded"
echo "6. A load_duration > 0 indicates the model was loaded into memory"
echo "7. keep_alive parameter controls how long model stays in memory"
echo
echo "Key indicators of model loading:"
echo "- load_duration: Time spent loading the model (nanoseconds)"
echo "- If load_duration is 0 or missing, model was already loaded"
echo "- If load_duration > 0, model was loaded for this request"