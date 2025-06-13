#!/usr/bin/env elixir

# Direct test of LLM functionality without the UI
IO.puts("\n=== TESTING LLM DIRECTLY ===\n")

# Force use of Ollama
Application.put_env(:ash_chat, :use_openrouter, false)

try do
  # Test 1: Create a simple chat model
  IO.puts("1. Creating Ollama chat model...")
  
  config = %{
    provider: "ollama",
    model: "qwen2.5:latest",
    temperature: 0.7
  }
  
  chat_model = AshChat.AI.InferenceConfig.create_chat_model(config)
  IO.puts("   ✓ Chat model created")
  
  # Test 2: Create a simple chain
  IO.puts("\n2. Creating LangChain...")
  chain = LangChain.Chains.LLMChain.new!(%{
    llm: chat_model,
    verbose: true
  })
  IO.puts("   ✓ Chain created")
  
  # Test 3: Send a message
  IO.puts("\n3. Sending test message...")
  message = LangChain.Message.new_user!("Hello! Please respond with: 'I am working!'")
  
  # Add message to chain first
  chain_with_message = LangChain.Chains.LLMChain.add_message(chain, message)
  
  case LangChain.Chains.LLMChain.run(chain_with_message) do
    {:ok, %{last_message: %{content: content}}} ->
      IO.puts("   ✓ SUCCESS! LLM responded:")
      IO.puts("   \"#{content}\"")
      
    {:error, error} ->
      IO.puts("   ✗ ERROR: #{inspect(error)}")
      
    other ->
      IO.puts("   ✗ Unexpected response: #{inspect(other)}")
  end
  
  # Test 4: Check Ollama connection
  IO.puts("\n4. Checking Ollama status...")
  base_url = Application.get_env(:langchain, :ollama_url, "http://10.1.2.200:11434")
  
  case HTTPoison.get("#{base_url}/api/tags", [], timeout: 5000, recv_timeout: 5000) do
    {:ok, %{status_code: 200, body: body}} ->
      {:ok, data} = Jason.decode(body)
      models = Enum.map(data["models"] || [], & &1["name"])
      IO.puts("   ✓ Ollama is running with models: #{inspect(models)}")
      
    {:ok, %{status_code: code}} ->
      IO.puts("   ✗ Ollama returned status code: #{code}")
      
    {:error, reason} ->
      IO.puts("   ✗ Cannot connect to Ollama: #{inspect(reason)}")
  end
  
rescue
  error ->
    IO.puts("\n✗ Error during test: #{inspect(error)}")
    IO.puts("Stacktrace:")
    IO.inspect(__STACKTRACE__, limit: 5)
end

IO.puts("\n=== TEST COMPLETE ===\n")