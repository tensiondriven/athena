#!/bin/bash

# Ollama Model Cleanup Script
# Removes old and large unused models to free disk space

echo "=== Ollama Model Cleanup ==="
echo "Current date: $(date)"
echo

# Get currently running models
RUNNING_MODELS=$(curl -s http://llm:11434/api/ps 2>/dev/null | jq -r '.models[].name' 2>/dev/null | sort)
echo "Currently running models:"
echo "$RUNNING_MODELS" | sed 's/^/  - /'
echo

# Calculate total size before cleanup
TOTAL_BEFORE=$(curl -s http://llm:11434/api/tags | jq -r '.models[].size' | awk '{sum+=$1} END {printf "%.2f", sum/1073741824}')
echo "Total size before cleanup: ${TOTAL_BEFORE}GB"
echo

# Models to keep (add your important models here)
KEEP_MODELS=(
    "deepseek-r1:32b-qwen-distill-q4_K_M"
    "llama3-groq-tool-use:8b"
    "qwen2.5-coder:7b"
    "deepseek-r1:8b"
    "deepseek-r1:7b"
)

# Get all models with details
echo "Analyzing models for cleanup..."
echo

# Models to remove
TO_REMOVE=()

# Check each model
while IFS=$'\t' read -r size name modified; do
    # Convert modified date to seconds since epoch
    modified_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${modified%%.*}" "+%s" 2>/dev/null || date -d "${modified%%.*}" "+%s" 2>/dev/null)
    current_epoch=$(date "+%s")
    days_old=$(( (current_epoch - modified_epoch) / 86400 ))
    
    # Check if model should be kept
    keep=false
    for keeper in "${KEEP_MODELS[@]}"; do
        if [[ "$name" == "$keeper" ]]; then
            keep=true
            break
        fi
    done
    
    # Check if currently running
    if echo "$RUNNING_MODELS" | grep -q "^$name$"; then
        keep=true
    fi
    
    # Decision logic
    if [[ "$keep" == false ]]; then
        size_gb=$(echo "$size" | cut -d'G' -f1)
        
        # Remove if: older than 60 days OR larger than 20GB and older than 30 days
        if [[ $days_old -gt 60 ]] || ([[ $(echo "$size_gb > 20" | bc -l) -eq 1 ]] && [[ $days_old -gt 30 ]]); then
            TO_REMOVE+=("$name|$size|$days_old days old")
        fi
    fi
done < <(curl -s http://llm:11434/api/tags | jq -r '.models[] | "\(.size / 1073741824 | tostring | split(".")[0:2] | join("."))GB\t\(.name)\t\(.modified_at)"')

# Show models to be removed
if [[ ${#TO_REMOVE[@]} -eq 0 ]]; then
    echo "No models identified for removal."
else
    echo "Models to be removed:"
    printf '%s\n' "${TO_REMOVE[@]}" | column -t -s'|' | sed 's/^/  /'
    echo
    
    # Ask for confirmation
    read -p "Do you want to remove these models? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo
        echo "Removing models..."
        for entry in "${TO_REMOVE[@]}"; do
            model_name=$(echo "$entry" | cut -d'|' -f1)
            echo -n "Removing $model_name... "
            if ollama rm "$model_name" 2>/dev/null; then
                echo "✓"
            else
                echo "✗ (failed)"
            fi
        done
        
        echo
        # Calculate total size after cleanup
        TOTAL_AFTER=$(curl -s http://llm:11434/api/tags | jq -r '.models[].size' | awk '{sum+=$1} END {printf "%.2f", sum/1073741824}')
        SAVED=$(echo "$TOTAL_BEFORE - $TOTAL_AFTER" | bc)
        echo "Total size after cleanup: ${TOTAL_AFTER}GB"
        echo "Space saved: ${SAVED}GB"
    else
        echo "Cleanup cancelled."
    fi
fi