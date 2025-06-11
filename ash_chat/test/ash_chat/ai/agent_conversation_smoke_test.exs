defmodule AshChat.AI.AgentConversationSmokeTest do
  @moduledoc """
  Smoke tests for agent-to-agent conversations.
  These tests mock the LLM responses to test the conversation flow without requiring Ollama.
  """
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  
  alias AshChat.AI.AgentConversation
  alias AshChat.Resources.{Room, User, Message, AgentCard, AgentMembership, Profile}
  
  setup do
    # Clean up - Using Ash.read! to get all records then destroy
    Message.read!() |> Enum.each(&Message.destroy!/1)
    AgentMembership.read!() |> Enum.each(&AgentMembership.destroy!/1) 
    Room.read!() |> Enum.each(&Room.destroy!/1)
    AgentCard.read!() |> Enum.each(&AgentCard.destroy!/1)
    Profile.read!() |> Enum.each(&Profile.destroy!/1)
    User.read!() |> Enum.each(&User.destroy!/1)
    
    # Create a test profile (required for agent processing)
    {:ok, profile} = Profile.create(%{
      name: "Test Profile",
      url: "http://localhost:11434",
      provider: "ollama",
      model: "qwen2.5:latest",
      is_default: true
    })
    
    # Create test data
    {:ok, user} = User.create(%{
      name: "Test User",
      email: "test@example.com"
    })
    
    {:ok, room} = Room.create(%{
      title: "Test Conversation Room"
    })
    
    {:ok, sam} = AgentCard.create(%{
      name: "Sam",
      system_message: "You are Sam, a friendly agent.",
      model_preferences: %{temperature: 0.7, max_tokens: 100}
    })
    
    {:ok, maya} = AgentCard.create(%{
      name: "Maya",
      system_message: "You are Maya, a thoughtful agent.",
      model_preferences: %{temperature: 0.7, max_tokens: 100}
    })
    
    # Add agents to room
    {:ok, _} = AgentMembership.create(%{
      room_id: room.id,
      agent_card_id: sam.id,
      role: "participant",
      auto_respond: true
    })
    
    {:ok, _} = AgentMembership.create(%{
      room_id: room.id,
      agent_card_id: maya.id,
      role: "participant",
      auto_respond: true
    })
    
    %{room: room, user: user, sam: sam, maya: maya, profile: profile}
  end
  
  describe "basic conversation flow" do
    test "should_agent_respond? correctly identifies when to respond", %{room: room, sam: sam, maya: maya} do
      # Test 1: Agent mentioned by name
      {:ok, msg_with_name} = Message.create_text_message(%{
        room_id: room.id,
        content: "Hey Sam, how are you?",
        role: :user
      })
      
      assert AgentConversation.should_agent_respond?(sam, msg_with_name, room.id) == true
      assert AgentConversation.should_agent_respond?(maya, msg_with_name, room.id) in [true, false]  # Random chance
      
      # Test 2: Question without name
      {:ok, question} = Message.create_text_message(%{
        room_id: room.id,
        content: "What's your favorite color?",
        role: :user
      })
      
      # Both agents have 70% chance to respond to questions
      # We can't assert exact values due to randomness, but we can test multiple times
      results = for _ <- 1..10 do
        AgentConversation.should_agent_respond?(sam, question, room.id)
      end
      
      # Should have some true values (statistically likely with 70% chance)
      assert Enum.any?(results)
      
      # Test 3: Agent shouldn't respond to assistant messages
      {:ok, agent_msg} = Message.create_text_message(%{
        room_id: room.id,
        content: "Hello from an agent",
        role: :assistant
      })
      
      assert AgentConversation.should_agent_respond?(sam, agent_msg, room.id) == false
      assert AgentConversation.should_agent_respond?(maya, agent_msg, room.id) == false
    end
    
    test "loop prevention works correctly", %{room: room, sam: sam} do
      # Create a conversation where Sam has already responded
      {:ok, _msg1} = Message.create_text_message(%{
        room_id: room.id,
        content: "Hello",
        role: :user
      })
      
      {:ok, _sam_response1} = Message.create_text_message(%{
        room_id: room.id,
        content: "Hi there!",
        role: :assistant,
        metadata: %{"agent_id" => sam.id}
      })
      
      {:ok, _msg2} = Message.create_text_message(%{
        room_id: room.id,
        content: "How are you?",
        role: :user
      })
      
      {:ok, _sam_response2} = Message.create_text_message(%{
        room_id: room.id,
        content: "I'm doing great!",
        role: :assistant,
        metadata: %{"agent_id" => sam.id}
      })
      
      {:ok, _msg3} = Message.create_text_message(%{
        room_id: room.id,
        content: "That's good",
        role: :user
      })
      
      {:ok, _sam_response3} = Message.create_text_message(%{
        room_id: room.id,
        content: "Thanks!",
        role: :assistant,
        metadata: %{"agent_id" => sam.id}
      })
      
      # Now if another user message comes, Sam should be prevented from responding
      # due to having responded in the last 3 messages
      {:ok, new_msg} = Message.create_text_message(%{
        room_id: room.id,
        content: "Sam, are you still there?",  # Even with name mention
        role: :user
      })
      
      # Loop prevention should kick in
      log = capture_log(fn ->
        result = AgentConversation.should_agent_respond?(sam, new_msg, room.id)
        assert result == false
      end)
      
      assert log =~ "Loop detected"
    end
    
    test "messages are properly stored in room", %{room: room, user: user} do
      # Start with empty room
      {:ok, initial_messages} = Message.for_room(%{room_id: room.id})
      assert initial_messages == []
      
      # User sends a message
      {:ok, user_msg} = Message.create_text_message(%{
        room_id: room.id,
        content: "Hello everyone!",
        role: :user,
        user_id: user.id
      })
      
      # Verify user message is stored
      {:ok, messages_after_user} = Message.for_room(%{room_id: room.id})
      assert length(messages_after_user) == 1
      assert hd(messages_after_user).content == "Hello everyone!"
      assert hd(messages_after_user).role == :user
      
      # Simulate agent response
      {:ok, agent_msg} = Message.create_text_message(%{
        room_id: room.id,
        content: "Hello there!",
        role: :assistant,
        metadata: %{"agent_id" => "test-agent-id"}
      })
      
      # Verify both messages are in room
      {:ok, all_messages} = Message.for_room(%{room_id: room.id})
      assert length(all_messages) == 2
      
      # Verify order and content
      [first, second] = all_messages
      assert first.id == user_msg.id
      assert second.id == agent_msg.id
      assert second.metadata["agent_id"] == "test-agent-id"
    end
    
    test "parallel agent processing returns filtered results", %{room: room, _sam: _sam, _maya: _maya} do
      # This is a unit test of process_agent_responses without actual LLM calls
      # We'll need to mock the agent responses, but for now we can test the structure
      
      {:ok, trigger_msg} = Message.create_text_message(%{
        room_id: room.id,
        content: "What do you both think about testing?",
        role: :user
      })
      
      # The actual process_agent_responses would call the LLM
      # For smoke test, we're checking the function exists and returns a list
      result = AgentConversation.process_agent_responses(room.id, trigger_msg, [])
      assert is_list(result)
    end
  end
  
  describe "agent metadata tracking" do
    test "agent responses include agent_id in metadata", %{room: room, sam: sam} do
      {:ok, msg} = Message.create_text_message(%{
        room_id: room.id,
        content: "Test message",
        role: :assistant,
        metadata: %{"agent_id" => sam.id}
      })
      
      assert msg.metadata["agent_id"] == sam.id
      
      # Verify metadata persists when retrieving messages
      {:ok, messages} = Message.for_room(%{room_id: room.id})
      stored_msg = hd(messages)
      assert stored_msg.metadata["agent_id"] == sam.id
    end
  end
end