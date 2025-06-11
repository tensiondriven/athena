#!/bin/bash

# Aggressive Ollama cleanup - removes old and large models

echo "=== Aggressive Ollama Model Cleanup ==="
echo "Starting at: $(date)"
echo

# Models to definitely keep
KEEP_MODELS=(
    "deepseek-r1:32b-qwen-distill-q4_K_M"
    "llama3-groq-tool-use:8b"
    "qwen2.5-coder:7b"
    "deepseek-r1:8b"
)

# Get currently running models
RUNNING=$(curl -s http://llm:11434/api/ps 2>/dev/null | jq -r '.models[].name' 2>/dev/null)

# Calculate before size
BEFORE=$(curl -s http://llm:11434/api/tags | jq '[.models[].size] | add / 1073741824')
echo "Total size before: ${BEFORE}GB"
echo

# Remove old models
echo "Removing models older than 60 days or large models older than 30 days..."
echo

REMOVED_COUNT=0
FAILED_COUNT=0

while IFS=$'\t' read -r size name modified; do
    # Skip if in keep list
    skip=false
    for keeper in "${KEEP_MODELS[@]}"; do
        [[ "$name" == "$keeper" ]] && skip=true && break
    done
    
    # Skip if running
    echo "$RUNNING" | grep -q "^$name$" && skip=true
    
    if [[ "$skip" == false ]]; then
        # Calculate age
        modified_epoch=$(date -d "${modified%%.*}" "+%s" 2>/dev/null || echo "0")
        current_epoch=$(date "+%s")
        days_old=$(( (current_epoch - modified_epoch) / 86400 ))
        
        size_gb=${size%GB*}
        
        # Remove if old or large and somewhat old
        if [[ $days_old -gt 60 ]] || ([[ $(echo "$size_gb > 20" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && [[ $days_old -gt 30 ]]); then
            echo -n "Removing $name (${size}, ${days_old} days old)... "
            if ollama rm "$name" 2>/dev/null; then
                echo "✓"
                ((REMOVED_COUNT++))
            else
                echo "✗"
                ((FAILED_COUNT++))
            fi
        fi
    fi
done < <(curl -s http://llm:11434/api/tags | jq -r '.models[] | "\(.size / 1073741824 | tostring | split(".")[0:2] | join("."))GB\t\(.name)\t\(.modified_at)"')

echo
echo "Cleanup complete!"
echo "Models removed: $REMOVED_COUNT"
echo "Failed removals: $FAILED_COUNT"

# Calculate after size
sleep 2
AFTER=$(curl -s http://llm:11434/api/tags | jq '[.models[].size] | add / 1073741824')
SAVED=$(echo "$BEFORE - $AFTER" | bc)

echo
echo "Total size after: ${AFTER}GB"
echo "Space saved: ${SAVED}GB"
echo "Completed at: $(date)"