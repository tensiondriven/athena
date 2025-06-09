# Testing AshChat with curl/wget/lynx

## Quick Test Loop (No VLM needed!)

### 1. Test the Home Page
```bash
curl -s http://127.0.0.1:4000/ | grep -i "Ash AI Chat"
# Should return: match if working
```

### 2. Test Chat Interface (HTML)
```bash
curl -s http://127.0.0.1:4000/chat | grep -i "chat"
# Should return HTML with chat interface
```

### 3. Test with lynx (Best for interactive testing)
```bash
lynx http://127.0.0.1:4000/chat
# Navigate with arrow keys, enter text in forms
```

### 4. Test Chat POST (Simulate message sending)
```bash
curl -X POST http://127.0.0.1:4000/chat \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_csrf_token=CSRF_TOKEN&message[content]=Hello AI"
```

### 5. Test Image Processing Endpoints
```bash
# Test image upload simulation
curl -X POST http://127.0.0.1:4000/chat \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "message[content]=Test image&message[image_url]=https://via.placeholder.com/300.png"
```

## Mock Testing (No External AI calls)

The system is built to work without actual AI:

### 1. **Mock Mode**: Disable AI calls
```bash
export OPENAI_API_KEY=""  # Disable real AI
mix phx.server
```

### 2. **Test Image Sources**: Add local files
```elixir
# In iex -S mix phx.server
AshChat.Image.Processor.add_file_system_source("/tmp", "*.png")
# Place test images in /tmp/ and watch them get processed
```

### 3. **Test Tools**: Manual tool calls
```elixir
# In iex console
AshChat.Tools.create_chat("Test Chat")
AshChat.Tools.search_messages("test query")
```

## Full Testing Flow

1. **Start server**: `mix phx.server`
2. **Test home**: `curl -I http://127.0.0.1:4000/`
3. **Test chat UI**: `lynx http://127.0.0.1:4000/chat`
4. **Add test images**: Place images in monitored directory
5. **Verify processing**: Check logs for image processing
6. **Test tools**: Use iex console for tool testing

## Test Data Generation

```bash
# Create test images
mkdir -p /tmp/test_images
wget -O /tmp/test_images/test1.png https://via.placeholder.com/300.png
wget -O /tmp/test_images/test2.jpg https://via.placeholder.com/400.jpg

# Configure image processor to watch this directory
# Then watch the logs as it processes them automatically
```

## Closing the Loop

- **UI Testing**: lynx for interactive testing
- **API Testing**: curl for HTTP endpoints  
- **Image Testing**: File system monitoring
- **AI Testing**: Mock responses when no API key
- **Tool Testing**: iex console for direct function calls

No VLM required - everything can be tested with standard CLI tools! 🎯