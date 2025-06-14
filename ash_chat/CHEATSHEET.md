# Ash AI Cheatsheet

## Quick Start - Server Management

**Always use server.sh script:**
```bash
./server.sh start     # Start Phoenix server
./server.sh stop      # Stop server
./server.sh restart   # Restart server
./server.sh status    # Check status
./server.sh logs      # View logs
./server.sh errors    # Check errors
./server.sh demo      # Setup demo data
```

## Core Ash AI Concepts

### Resources & Actions
```elixir
# Ash Resource with AI capabilities
defmodule MyApp.Message do
  use Ash.Resource,
    domain: MyApp.Domain,
    extensions: [AshAi]

  ash_ai do
    # Enable vectorization for semantic search
    vectorize text: :content,
             on: [:create, :update],
             store: MyApp.VectorStore
    
    # AI-powered actions
    action :summarize do
      model ChatOpenAI.new!(%{model: "gpt-4o"})
      prompt "Summarize this message: {{content}}"
      returns :string
    end
  end
end
```

### Embedding Strategies
- `after_action` - Immediate embedding after create/update
- `ash_oban` - Background job processing (recommended for production)
- `manual` - Explicit control over when to embed

### Tool Calling
```elixir
# Define tools that AI can call
defmodule MyApp.Tools do
  use AshAi.Tools
  
  tool :search_messages do
    argument :query, :string
    action MyApp.Message.search
  end
  
  tool :create_task do
    argument :title, :string
    argument :description, :string
    action MyApp.Task.create
  end
end
```

### MCP Integration
```elixir
# MCP Server for external tool access
defmodule MyApp.McpServer do
  use AshAi.Mcp.Server
  
  tools [MyApp.Tools]
  resources [MyApp.Message, MyApp.Task]
end
```

## LangChain Integration

### Chat Models
```elixir
# OpenAI GPT models
model = ChatOpenAI.new!(%{
  model: "gpt-4o",          # or "gpt-4o-mini"
  temperature: 0.7,
  stream: true,
  max_tokens: 1000
})

# Anthropic Claude
model = ChatAnthropic.new!(%{
  model: "claude-3-5-sonnet-20241022",
  temperature: 0.7
})
```

### Message Formats
```elixir
# Text message
%Message{role: :user, content: "Hello"}

# Multi-modal message with image
%Message{
  role: :user,
  content: [
    %{type: "text", text: "What's in this image?"},
    %{type: "image_url", image_url: %{url: "data:image/jpeg;base64,..."}}
  ]
}
```

### Chain Execution
```elixir
# Simple chain
{:ok, response} = LLMChain.new!(%{llm: model})
|> LLMChain.add_message(Message.new_user!("Hello"))
|> LLMChain.run()

# With tools
{:ok, response} = LLMChain.new!(%{
  llm: model,
  tools: [MyApp.Tools.list()]
})
|> LLMChain.run([Message.new_user!("Search for messages about AI")])
```

## Vector Search

### Setup Vector Store
```elixir
# In config/config.exs
config :ash_ai, :vector_store, 
  module: AshAi.VectorStores.Ecto,
  table: "embeddings"
```

### Similarity Search
```elixir
# Search similar content
results = MyApp.Message.semantic_search!(%{
  query: "machine learning",
  limit: 5,
  threshold: 0.8
})
```

## Production Deployment

### Required Environment Variables
```bash
# OpenAI
export OPENAI_API_KEY="sk-..."

# Anthropic
export ANTHROPIC_API_KEY="sk-ant-..."

# Database (for vector storage)
export DATABASE_URL="postgresql://..."
```

### Background Jobs with Oban
```elixir
# In config/config.exs
config :my_app, Oban,
  repo: MyApp.Repo,
  queues: [
    embeddings: 10,
    ai_processing: 5
  ]
```

### Memory Management
- Use streaming for long conversations
- Implement conversation summarization
- Limit context window size
- Use semantic search for relevant context retrieval

## Common Patterns

### Agentic Chat with Memory
```elixir
defmodule MyApp.Agent do
  def chat(conversation_id, message) do
    # Get conversation history
    history = get_conversation_history(conversation_id)
    
    # Get relevant context via semantic search
    context = get_relevant_context(message)
    
    # Build chain with tools and memory
    chain = LLMChain.new!(%{
      llm: ChatOpenAI.new!(%{model: "gpt-4o"}),
      tools: MyApp.Tools.list(),
      memory: build_memory(history, context)
    })
    
    # Process with streaming
    LLMChain.run(chain, [Message.new_user!(message)],
      stream: true,
      callback: &handle_stream/1
    )
  end
end
```

### Multi-Modal Processing
```elixir
def process_image_message(image_url, text) do
  message = Message.new_user!([
    %{type: "text", text: text},
    %{type: "image_url", image_url: %{url: image_url}}
  ])
  
  LLMChain.new!(%{llm: ChatOpenAI.new!(%{model: "gpt-4o"})})
  |> LLMChain.run([message])
end
```

### Error Handling
```elixir
case LLMChain.run(chain, messages) do
  {:ok, response} -> 
    handle_success(response)
    
  {:error, %LangChain.LLMError{type: :rate_limit}} ->
    schedule_retry()
    
  {:error, %LangChain.LLMError{type: :context_length}} ->
    truncate_and_retry()
    
  {:error, error} ->
    log_error(error)
end
```

## Debugging & Monitoring

### Enable Verbose Logging
```elixir
chain = LLMChain.new!(%{
  llm: model,
  verbose: true,  # Logs all messages and responses
  callbacks: [MyApp.LLMCallback]
})
```

### Custom Callbacks
```elixir
defmodule MyApp.LLMCallback do
  def on_message_new(message) do
    Logger.info("New message: #{message.content}")
  end
  
  def on_tool_call_start(tool_call) do
    Logger.info("Calling tool: #{tool_call.name}")
  end
end
```