#!/bin/bash

# Setup script for OpenCode with Ollama

echo "=== OpenCode + Ollama Configuration Helper ==="
echo

# Check if ollama is accessible
echo "1. Checking Ollama server..."
if curl -s -f -o /dev/null "http://llm:11434"; then
    echo "   ✓ Ollama server is accessible at http://llm:11434"
else
    echo "   ✗ Cannot reach Ollama server at http://llm:11434"
    echo "   Please ensure Ollama is running: docker ps | grep ollama"
    exit 1
fi

# Create proper config
echo
echo "2. Creating OpenCode configuration..."
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
      "model": "local.qwen2.5-coder:7b",
      "maxTokens": 8192
    },
    "task": {
      "model": "local.qwen2.5-coder:7b",
      "maxTokens": 4096
    },
    "title": {
      "model": "local.qwen2.5-coder:7b",
      "maxTokens": 80
    }
  }
}
EOF
echo "   ✓ Configuration written to ~/.opencode.json"

# Set environment variable
echo
echo "3. Setting environment variable..."
echo "   export LOCAL_ENDPOINT=\"http://llm:11434/v1\""
export LOCAL_ENDPOINT="http://llm:11434/v1"

# Show available models that might work
echo
echo "4. Models that might support tools/functions:"
echo "   - qwen2.5-coder:7b (currently configured)"
echo "   - mistral-based models"
echo "   - llama-based models with tool support"

echo
echo "5. Known issues:"
echo "   - deepseek-r1 models don't support tools/function calling"
echo "   - OpenCode requires models with tool/function support"
echo "   - Config may be auto-modified by OpenCode"

echo
echo "6. To use OpenCode:"
echo "   export LOCAL_ENDPOINT=\"http://llm:11434/v1\""
echo "   opencode  # for interactive mode"
echo "   opencode -p \"Your prompt\" -f text -q  # for one-shot"

echo
echo "7. Alternative: Use deepseek-r1 directly via ollama:"
echo "   ollama run deepseek-r1:32b-qwen-distill-q4_K_M"

echo
echo "Configuration complete!"