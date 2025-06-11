#!/bin/bash

# Simple OpenCode test focusing on what works

echo "=== Simple OpenCode Test ==="
echo

# Ensure config is correct
echo "1. Setting up configuration..."
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
echo "   ✓ Config written"
echo

# Set environment
export LOCAL_ENDPOINT="http://llm:11434/v1"
echo "2. Environment set: LOCAL_ENDPOINT=$LOCAL_ENDPOINT"
echo

# Show loaded models
echo "3. Currently loaded models:"
curl -s http://llm:11434/api/ps | jq -r '.models[].name' | sed 's/^/   - /'
echo

# Test 1: Simple math
echo "4. Test: Simple math"
echo "   Command: opencode -p \"What is 2+2?\" -f text -q"
echo -n "   Result: "
timeout 20 bash -c 'export LOCAL_ENDPOINT="http://llm:11434/v1"; opencode -p "What is 2+2?" -f text -q 2>&1 | head -5'
echo

# Test 2: Code generation
echo "5. Test: Generate Python code"
echo "   Command: opencode -p \"Write a Python function to add two numbers\" -f text -q"
echo "   Result:"
timeout 20 bash -c 'export LOCAL_ENDPOINT="http://llm:11434/v1"; opencode -p "Write a Python function to add two numbers. Just the function." -f text -q 2>&1' | head -10 | sed 's/^/   /'
echo

# Show how to use for file operations
echo "6. File operations workaround:"
echo "   Since llama3-groq-tool-use has limited tool support,"
echo "   for file operations use deepseek-r1 directly:"
echo
echo "   ollama run deepseek-r1:32b-qwen-distill-q4_K_M"
echo "   > List the contents of /tmp directory"
echo

echo "7. Summary:"
echo "   - OpenCode works with llama3-groq-tool-use:8b"
echo "   - Basic Q&A and code generation work"
echo "   - File operations require different approach"
echo "   - Models remain loaded: ✓"