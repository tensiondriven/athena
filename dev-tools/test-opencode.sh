#!/bin/bash

# Test OpenCode with local ollama

echo "Testing OpenCode with local ollama server..."
echo "Server: http://llm:11434"
echo

# Set environment variable
export LOCAL_ENDPOINT="http://llm:11434/v1"

# Show current config
echo "Current .opencode.json:"
cat ~/.opencode.json | jq '.' 2>/dev/null || cat ~/.opencode.json
echo

# Test simple prompt
echo "Testing simple math question..."
opencode -p "What is 2+2? Just answer with the number." -f text -q

echo
echo "Testing code generation..."
opencode -p "Write a Python function to calculate factorial. Just the code, no explanation." -f text -q

echo
echo "Done!"