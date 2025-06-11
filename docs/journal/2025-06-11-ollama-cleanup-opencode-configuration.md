# Ollama Model Cleanup and OpenCode Configuration

Date: 2025-06-11

## Summary
Performed a major cleanup of ollama models, removing 57 unused models and freeing up 1,165GB (over 1TB) of disk space. Also resolved OpenCode configuration issues with local ollama models.

## The Cleanup

### Before
- Total models: 123
- Total size: 1,561GB
- Many models hadn't been used in months

### After  
- Total models: 66
- Total size: 396GB
- Space saved: **1,165GB** 

### What Was Removed
Focused on removing:
1. Large models over 20GB that weren't actively used
2. Medium models (10-20GB) from months ago
3. Duplicate/alternative quantizations of the same base models
4. Experimental models that didn't pan out

Kept essential models:
- `deepseek-r1:32b-qwen-distill-q4_K_M` (main reasoning model)
- `llama3-groq-tool-use:8b` (for tool calling)
- `qwen2.5-coder:7b` (coding assistance)
- Other actively used models

## OpenCode Configuration Discovery

### The Problem
OpenCode couldn't connect to local ollama models. Key findings:

1. **Tool/Function Calling Required**: OpenCode requires models that support OpenAI's tool/function calling API
2. **DeepSeek models don't support tools**: None of the DeepSeek models (including the excellent deepseek-r1) support tool calling
3. **Configuration quirks**: The `.opencode.json` file gets auto-modified, removing custom endpoints

### The Solution
Found that `llama3-groq-tool-use:8b` specifically supports tool calling. Working configuration:

```json
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
    }
  }
}
```

Always set environment variable for reliability:
```bash
export LOCAL_ENDPOINT="http://llm:11434/v1"
opencode
```

### Alternative Approaches
For deepseek-r1 usage (which is superior for reasoning but lacks tool support):
- Use ollama directly: `ollama run deepseek-r1:32b-qwen-distill-q4_K_M`
- Consider alternative inference engines (vLLM, TGI) with better OpenAI compatibility
- Use OpenRouter for cloud-based access with tool support

## Tools Created

Created several utility scripts in `/dev-tools/`:
1. `ollama-status.sh` - Interactive status monitor with nice TUI
2. `ollama-quick-status.sh` - Quick non-interactive status check
3. `ollama-api-cleanup.sh` - The cleanup script that removed 1TB of models
4. `opencode-ollama-working-config.sh` - Documents the working configuration

## Lessons Learned

1. **Regular cleanup is essential** - Models accumulate quickly when experimenting
2. **Tool support varies widely** - Many models don't support OpenAI's function calling
3. **API beats CLI** - Using ollama's REST API for deletion was more reliable than CLI
4. **Documentation saves debugging** - Creating reference scripts helps future troubleshooting

## Next Steps

- Monitor disk usage more regularly
- Consider implementing automated cleanup policies
- Investigate alternative inference engines for better tool support
- Keep exploring models that balance capability with tool compatibility

The cleanup was overdue but successful - recovering over 1TB of space while preserving all actively used models.