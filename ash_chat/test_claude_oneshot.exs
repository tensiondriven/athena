#!/usr/bin/env elixir

# Test script for Claude one-shot functionality
# Tests the basic AI conversation flow without UI

Mix.install([
  {:ash_chat, path: "."},
  {:jason, "~> 1.4"}
])

IO.puts("\n=== TESTING CLAUDE ONE-SHOT ===\n")

Application.ensure_all_started(:ash_chat)

try do
  # Test 1: Create minimal test data
  IO.puts("1. Setting up test data...")
  
  # Clean and create fresh data  
  AshChat.Setup.create_demo_data()
  
  # Get the created entities
  {:ok, [user]} = AshChat.Resources.User.read()
  {:ok, [room]} = AshChat.Resources.Room.read()
  {:ok, [agent_card]} = AshChat.Resources.AgentCard.read()
  
  IO.puts("   ✓ Created user: #{user.name}")
  IO.puts("   ✓ Created room: #{room.title}")
  IO.puts("   ✓ Created agent: #{agent_card.name}")
  
  # Test 2: Send a simple message and get AI response
  IO.puts("\n2. Testing one-shot AI conversation...")
  
  test_message = "Hello! Please respond with exactly: 'One-shot test successful'"
  
  case AshChat.AI.ChatAgent.send_message_and_get_ai_response(
    room.id, 
    test_message, 
    user.id
  ) do
    {:ok, ai_message} ->
      IO.puts("   ✓ SUCCESS! AI responded:")
      IO.puts("   User: #{test_message}")
      IO.puts("   AI: #{ai_message.content}")
      
      # Test 3: Verify message persistence
      IO.puts("\n3. Verifying message persistence...")
      {:ok, messages} = AshChat.AI.ChatAgent.get_room_messages(room.id)
      
      if length(messages) >= 2 do
        user_msg = Enum.find(messages, & &1.role == :user)
        ai_msg = Enum.find(messages, & &1.role == :assistant)
        
        IO.puts("   ✓ User message stored: #{user_msg.content}")
        IO.puts("   ✓ AI message stored: #{ai_msg.content}")
        IO.puts("   ✓ Total messages in room: #{length(messages)}")
      else
        IO.puts("   ✗ Expected at least 2 messages, got #{length(messages)}")
      end
      
    {:error, error} ->
      IO.puts("   ✗ ERROR: #{inspect(error)}")
      
      # Test 4: Check if it's a connection issue
      IO.puts("\n4. Checking inference backend status...")
      case AshChat.Setup.get_default_profile() do
        {:ok, profile} ->
          IO.puts("   Using profile: #{profile.name}")
          IO.puts("   Provider: #{profile.provider}")
          IO.puts("   Model: #{profile.model}")
          
          if profile.provider == "ollama" do
            base_url = profile.url || "http://10.1.2.200:11434"
            case HTTPoison.get("#{base_url}/api/tags", [], timeout: 5000) do
              {:ok, %{status_code: 200}} ->
                IO.puts("   ✓ Ollama is accessible")
              {:ok, %{status_code: code}} ->
                IO.puts("   ✗ Ollama returned status: #{code}")
              {:error, reason} ->
                IO.puts("   ✗ Cannot reach Ollama: #{inspect(reason)}")
            end
          else
            IO.puts("   ✓ Using OpenRouter (external)")
          end
          
        {:error, profile_error} ->
          IO.puts("   ✗ No default profile: #{inspect(profile_error)}")
      end
  end
  
  # Test 5: Test agent conversation system  
  IO.puts("\n5. Testing agent conversation flow...")
  
  case AshChat.AI.AgentConversation.trigger_agent_response(agent_card.id, room.id, "Test manual trigger") do
    {:ok, message} ->
      IO.puts("   ✓ Manual agent trigger successful")
      IO.puts("   Agent message: #{message.content}")
      
    {:error, error} ->
      IO.puts("   ✗ Manual agent trigger failed: #{inspect(error)}")
  end
  
  # Test 6: Check system prompt integration
  IO.puts("\n6. Checking SystemPrompt integration...")
  
  {:ok, system_prompts} = AshChat.Resources.SystemPrompt.read()
  
  if length(system_prompts) > 0 do
    system_prompt = List.first(system_prompts)
    IO.puts("   ✓ Found SystemPrompt: #{system_prompt.name}")
    IO.puts("   Content preview: #{String.slice(system_prompt.content, 0, 50)}...")
    
    # Check if agent card references it
    if agent_card.system_prompt_id == system_prompt.id do
      IO.puts("   ✓ Agent card properly references SystemPrompt")
    else
      IO.puts("   ✗ Agent card not linked to SystemPrompt")
    end
  else
    IO.puts("   ✗ No SystemPrompts found")
  end
  
rescue
  error ->
    IO.puts("\n✗ Error during test: #{inspect(error)}")
    IO.puts("Stacktrace:")
    IO.inspect(__STACKTRACE__, limit: 10)
end

IO.puts("\n=== TEST COMPLETE ===\n")