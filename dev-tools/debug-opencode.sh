#!/bin/bash

# Simple OpenCode debugging script

echo "=== OpenCode Debug Test ==="
echo

# 1. Show configuration
echo "1. Current configuration:"
cat ~/.opencode.json | jq '.' 2>/dev/null || echo "No config file"
echo

# 2. Test environment
echo "2. Environment setup:"
export LOCAL_ENDPOINT="http://llm:11434/v1"
echo "   LOCAL_ENDPOINT=$LOCAL_ENDPOINT"
echo

# 3. Check if model is available
echo "3. Checking if configured model exists:"
MODEL=$(jq -r '.agents.coder.model' ~/.opencode.json 2>/dev/null | sed 's/^[^.]*\.//')
echo "   Looking for: $MODEL"
curl -s http://llm:11434/api/tags | jq -r '.models[].name' | grep -E "(llama3-groq-tool-use|$MODEL)" || echo "   Model not found!"
echo

# 4. Test direct API call
echo "4. Testing direct API call to ollama:"
curl -s -X POST http://llm:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3-groq-tool-use:8b",
    "messages": [{"role": "user", "content": "Say hello"}],
    "max_tokens": 50
  }' | jq -r '.choices[0].message.content' 2>/dev/null || echo "API call failed"
echo

# 5. Try OpenCode with timeout and error capture
echo "5. Testing OpenCode (10s timeout):"
echo "   Command: opencode -p \"Say hello\" -f text -q"
timeout 10 bash -c 'export LOCAL_ENDPOINT="http://llm:11434/v1"; opencode -p "Say hello" -f text -q 2>&1' || echo "Command timed out or failed"
echo

# 6. Try with debug mode
echo "6. Testing OpenCode with debug mode:"
echo "   Command: opencode -d -p \"Say hello\" -f text -q"
timeout 10 bash -c 'export LOCAL_ENDPOINT="http://llm:11434/v1"; opencode -d -p "Say hello" -f text -q 2>&1 | head -20' || echo "Debug mode failed"
echo

echo "=== Debug Summary ==="
echo "If OpenCode hangs, it might be:"
echo "- Waiting for model to load (check ollama logs)"
echo "- Having issues with tool calling"
echo "- Configuration mismatch"
echo
echo "Try running: ollama logs -f"
echo "In another terminal to see what's happening"