# OpenRouter Setup for Athena Chat

OpenRouter provides access to multiple LLMs through a single API, and is now the preferred provider for Athena Chat over direct Ollama connections.

## Why OpenRouter?

- **Better Performance**: Access to larger, more capable models (70B+ parameters)
- **Multiple Models**: Switch between Qwen, Llama, Claude, Gemini, etc.
- **Reliability**: Cloud-hosted, no local GPU required
- **Cost Effective**: Pay per token, often cheaper than direct provider APIs

## Quick Setup

1. **Get an API Key**
   - Visit https://openrouter.ai/keys
   - Create a new key
   - Add credits ($5 minimum)

2. **Configure Athena**
   ```bash
   cd ash_chat
   cp .env.example .env
   # Edit .env and add your key:
   # OPENROUTER_API_KEY=REDACTED_OPENROUTER_KEY-key-here
   ```

3. **Verify Setup**
   ```elixir
   iex -S mix
   
   # Check configuration
   Application.get_env(:langchain, :openrouter_key)
   # Should return your API key
   
   # Reset demo data to create OpenRouter profile
   AshChat.Setup.reset_demo_data()
   ```

## Available Models

The following models are pre-configured:
- `qwen/qwen-2.5-72b-instruct` (default - excellent for chat)
- `meta-llama/llama-3.1-70b-instruct`
- `anthropic/claude-3.5-sonnet`
- `google/gemini-pro-1.5`
- `mistralai/mistral-large`
- `deepseek/deepseek-chat`

## Configuration Options

### Environment Variables
- `OPENROUTER_API_KEY` - Your OpenRouter API key (required)
- `USE_OPENROUTER` - Set to "false" to disable OpenRouter (default: "true")
- `OLLAMA_URL` - Fallback Ollama URL if OpenRouter unavailable

### Automatic Model Mapping
When OpenRouter is enabled, Ollama model requests are automatically mapped:
- `qwen2.5:latest` → `qwen/qwen-2.5-72b-instruct`
- `llama3.2:latest` → `meta-llama/llama-3.1-70b-instruct`
- `deepseek-coder:latest` → `deepseek/deepseek-chat`

## Fallback Behavior

If OpenRouter is unavailable (no API key or disabled):
1. System falls back to local Ollama
2. Profile defaults to "Local Ollama"
3. Models use Ollama naming convention

## Cost Tracking

OpenRouter shows usage at https://openrouter.ai/activity
- Qwen 2.5 72B: ~$0.35 per million tokens
- Most conversations cost < $0.01

## Troubleshooting

**No API Key Error**
```
** (RuntimeError) OPENROUTER_API_KEY environment variable is not set
```
Solution: Add key to .env file and restart

**Model Not Found**
- Check model name matches OpenRouter format
- Verify model is available in your region

**Rate Limits**
- Add credits to your account
- Check https://openrouter.ai/limits

## Development Notes

- OpenRouter uses OpenAI-compatible API format
- Streaming is supported for real-time responses
- Tools/function calling may have limited support
- Headers include referer and title for tracking