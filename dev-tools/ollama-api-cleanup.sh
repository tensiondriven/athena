#!/bin/bash

# Ollama cleanup using API

echo "=== Ollama Model Cleanup via API ==="
echo

# Get total before
BEFORE_GB=$(curl -s http://llm:11434/api/tags | jq '[.models[].size] | add / 1073741824')
echo "Total size before: ${BEFORE_GB}GB"
echo

# Large models to remove (over 20GB)
LARGE_MODELS=(
    "hf.co/bartowski/Athene-V2-Chat-GGUF:Q4_K_S"
    "hf.co/bartowski/QVQ-72B-Preview-GGUF:IQ4_XS"
    "hf.co/mradermacher/L3.3-MS-Evayale-70B-i1-GGUF:Q4_K_S"
    "hf.co/bartowski/L3.3-MS-Nevoria-70b-GGUF:Q3_K_M"
    "hf.co/bartowski/QwQ-32B-Preview-abliterated-GGUF:Q8_0"
    "hf.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF:q8_0"
    "hf.co/bartowski/QVQ-72B-Preview-GGUF:Q2_K"
    "hf.co/bartowski/TheDrummer_Valkyrie-49B-v1-GGUF:Q4_K_M"
    "krith/mistral-large-instruct-2407:IQ1_M"
    "hf.co/bartowski/TheDrummer_Valkyrie-49B-v1-GGUF:Q4_0"
    "hf.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-abliterated-GGUF:Q6_K"
    "hf.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF:Q6_K"
    "hf.co/mradermacher/FuseO1-DeepSeekR1-Qwen2.5-Instruct-32B-Preview-i1-GGUF:Q6_K"
    "hf.co/mradermacher/QwQ-R1-abliterated-TIES-Qwen2.5-32B-GGUF:Q6_K"
    "hf.co/lmstudio-community/Llama-3_3-Nemotron-Super-49B-v1-GGUF:Q3_K_L"
    "hf.co/bartowski/mistralai_Devstral-Small-2505-GGUF:Q8_0"
    "hf.co/DavidAU/Mistral-MOE-4X7B-Dark-MultiVerse-Uncensored-Enhanced32-24B-gguf:Q8_0"
    "hf.co/Epiculous/Violet_Twilight-v0.2-GGUF:F16"
    "hf.co/bartowski/FuseO1-DeekSeekR1-QwQ-SkyT1-32B-Preview-GGUF:Q5_K_L"
    "hf.co/roleplaiapp/Pantheon-RP-Pure-1.6.2-22b-Small-Q8_0-GGUF:Q8_0"
    "hf.co/bartowski/Dumpling-Qwen2.5-32B-GGUF:Q5_K_L"
    "hf.co/bartowski/deepseek-r1-qwen-2.5-32B-ablated-GGUF:Q5_K_L"
    "hf.co/bartowski/Sky-T1-32B-Flash-GGUF:Q5_K_S"
    "hf.co/DevQuasar/trashpanda-org.QwQ-32B-Snowdrop-v0-GGUF:Q5_K_S"
    "hf.co/mradermacher/QwQ-32B-ArliAI-RpR-v3-i1-GGUF:Q5_K_S"
    "hf.co/bartowski/TheDrummer_Gemmasutra-Pro-27B-v1.1-GGUF:Q6_K"
    "hf.co/bartowski/TheDrummer_Fallen-Gemma3-27B-v1-GGUF:Q6_K"
)

# Medium models to remove (10-20GB) 
MEDIUM_MODELS=(
    "hf.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF:Q4_K_M"
    "deepseek-r1:32b"
    "hf.co/mradermacher/uwu-qwen-32b-i1-GGUF:Q4_K_M"
    "mattapperson/FuseO1-DeepSeekR1-QwQ-SkyT1-32B-Preview-Q4_K_M:latest"
    "hf.co/DavidAU/Llama-3.2-8X3B-MOE-Dark-Champion-Instruct-uncensored-abliterated-18.4B-GGUF:q8_0"
    "hf.co/mradermacher/Dolphin3.0-R1-Mistral-24B-abliterated-GGUF:Q6_K"
    "hf.co/BeaverAI/Cydonia-24B-v2c-GGUF:Q6_K"
    "hf.co/bartowski/TheDrummer_Cydonia-24B-v2-GGUF:Q6_K"
    "hf.co/mradermacher/CardProjector-24B-v1-i1-GGUF:Q6_K"
    "hf.co/mradermacher/Omega-Darker_The-Final-Directive-24B-i1-GGUF:Q6_K"
    "hf.co/BeaverAI/Fallen-Mistral-Small-3.1-24B-v1e-GGUF:Q6_K"
    "hf.co/bartowski/Gryphe_Pantheon-RP-1.8-24b-Small-3.1-GGUF:Q6_K_L"
    "hf.co/mradermacher/Broken-Tutu-24B-i1-GGUF:Q6_K"
    "hf.co/TheDrummer/Big-Tiger-Gemma-27B-v1-GGUF:Q5_K_M"
    "hf.co/mradermacher/EVA-Rombos1-Qwen2.5-32B-i1-GGUF:Q4_K_S"
    "hf.co/DavidAU/L3-DARKEST-PLANET-16.5B-GGUF:Q8_0"
    "hf.co/mradermacher/FuseO1-DeepSeekR1-QwQ-SkyT1-32B-Preview-i1-GGUF:IQ4_XS"
    "gemma3:27b"
    "hf.co/bartowski/Mistral-Small-24B-Instruct-2501-GGUF:Q5_K_L"
    "hf.co/FiditeNemini/Llama-3.1-Unhinged-Vision-8B-GGUF:F16"
    "hf.co/openbmb/MiniCPM-o-2_6-gguf:F16"
    "hf.co/Lewdiculous/Visual-LaylelemonMaidRP-7B-GGUF-IQ-Imatrix:F16"
    "vnd3200/QwQ-LCoT-Instruct:7b"
    "hf.co/lmstudio-community/Qwen2.5-14B-Instruct-1M-GGUF:Q8_0"
    "hf.co/oxyapi/oxy-1-small-GGUF:Q8_0"
    "hf.co/mradermacher/EVA-Qwen2.5-14B-v0.1-GGUF:Q8_0"
    "phi4:14b-q8_0"
    "hf.co/theprint/ReWiz-Phi-4-14B-GGUF:Q8_0"
    "Drews54/llama3.2-vision-abliterated:11b"
    "hf.co/bartowski/MN-12b-RP-Ink-GGUF:Q8_0"
    "hf.co/mradermacher/Dolphin3.0-R1-Mistral-24B-abliterated-GGUF:IQ4_XS"
    "technobyte/arliai-rpmax-12b-v1.1:q8_0"
    "codestral:22b-v0.1-q4_0"
    "hf.co/bartowski/uncensoredai_UncensoredLM-DeepSeek-R1-Distill-Qwen-14B-GGUF:Q6_K_L"
)

echo "Removing large models (>20GB)..."
for model in "${LARGE_MODELS[@]}"; do
    echo -n "  Deleting $model... "
    if curl -s -X DELETE http://llm:11434/api/delete -d "{\"name\": \"$model\"}" >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
    fi
done

echo
echo "Removing medium models (10-20GB)..."
for model in "${MEDIUM_MODELS[@]}"; do
    echo -n "  Deleting $model... "
    if curl -s -X DELETE http://llm:11434/api/delete -d "{\"name\": \"$model\"}" >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
    fi
done

echo
echo "Waiting for cleanup to complete..."
sleep 5

# Get total after
AFTER_GB=$(curl -s http://llm:11434/api/tags | jq '[.models[].size] | add / 1073741824')
SAVED=$(echo "$BEFORE_GB - $AFTER_GB" | bc)

echo
echo "Total size after: ${AFTER_GB}GB"
echo "Space saved: ${SAVED}GB"
echo
echo "Remaining models: $(curl -s http://llm:11434/api/tags | jq '.models | length')"