#!/bin/bash

# Working OpenCode + Ollama Configuration

echo "=== OpenCode + Ollama Working Configuration ==="
echo
echo "✅ CONFIRMED WORKING SETUP:"
echo

echo "1. Required: llama3-groq-tool-use:8b model"
echo "   This model supports tool/function calling which OpenCode requires"
echo

echo "2. Configuration file (~/.opencode.json):"
cat << 'EOF'
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
    }
  }
}
EOF

echo
echo "3. Environment variable:"
echo "   export LOCAL_ENDPOINT=\"http://llm:11434/v1\""
echo

echo "4. Usage examples:"
echo "   # Interactive mode"
echo "   LOCAL_ENDPOINT=\"http://llm:11434/v1\" opencode"
echo
echo "   # One-shot mode"
echo "   LOCAL_ENDPOINT=\"http://llm:11434/v1\" opencode -p \"Your prompt\" -f text -q"
echo

echo "5. Alternative models for tool calling:"
echo "   - hf.co/Nekuromento/llama3-empower-functions-small-v1.1-Q8_0-GGUF:latest"
echo "   - mistral-based models (check tool support)"
echo "   - qwen models (some support tools)"
echo

echo "6. For deepseek-r1 (no tool support), use ollama directly:"
echo "   ollama run deepseek-r1:32b-qwen-distill-q4_K_M"
echo

echo "Note: Config file may be auto-modified by OpenCode, removing the endpoint."
echo "Always set LOCAL_ENDPOINT environment variable for reliability."