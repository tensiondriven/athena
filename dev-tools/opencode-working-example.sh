#!/bin/bash

# OpenCode Working Example
# Shows what actually works with current limitations

echo "=== OpenCode Working Example ==="
echo

# Function to fix config before each call
fix_config() {
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
}

# Always set environment
export LOCAL_ENDPOINT="http://llm:11434/v1"

echo "Current setup:"
echo "- Model: llama3-groq-tool-use:8b (supports tools but limited capability)"
echo "- Endpoint: $LOCAL_ENDPOINT"
echo

echo "1. Checking loaded models:"
curl -s http://llm:11434/api/ps | jq -r '.models[].name' | sed 's/^/   ✓ /'
echo

echo "2. Working example - Code explanation:"
fix_config
echo "   Question: Explain what a Python list comprehension is"
echo "   Response:"
timeout 20 bash -c 'export LOCAL_ENDPOINT="http://llm:11434/v1"; opencode -p "Explain what a Python list comprehension is in one sentence" -f text -q 2>&1' | sed 's/^/   /'
echo

echo "3. Working example - Simple code generation:"
fix_config
echo "   Question: Write a Python hello world"
echo "   Response:"
timeout 20 bash -c 'export LOCAL_ENDPOINT="http://llm:11434/v1"; opencode -p "Write print hello world in Python" -f text -q 2>&1' | sed 's/^/   /'
echo

echo "4. Alternative for complex tasks - Use deepseek-r1 directly:"
echo "   For arithmetic, reasoning, file operations:"
echo "   $ ollama run deepseek-r1:32b-qwen-distill-q4_K_M"
echo
echo "   Example:"
echo "   > What is 25 * 4?"
echo "   > List common files in /etc directory"
echo "   > Write a complex Python function"
echo

echo "5. Key findings:"
echo "   ✓ OpenCode works but llama3-groq-tool-use has limitations"
echo "   ✓ Config gets auto-modified (drops endpoint)"
echo "   ✓ Models stay loaded throughout testing"
echo "   ✓ For serious work, use deepseek-r1 directly"
echo

echo "6. Practical usage:"
echo "   # For OpenCode (limited):"
echo "   export LOCAL_ENDPOINT=\"http://llm:11434/v1\""
echo "   opencode"
echo
echo "   # For full capability:"
echo "   ollama run deepseek-r1:32b-qwen-distill-q4_K_M"
echo

# Final check - models still loaded?
echo "7. Models still loaded:"
curl -s http://llm:11434/api/ps | jq -r '.models[] | "   ✓ \(.name) (expires: \(.expires_at | split("T")[0]))"'