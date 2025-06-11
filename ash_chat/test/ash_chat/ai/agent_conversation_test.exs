defmodule AshChat.AI.AgentConversationTest do
  use ExUnit.Case, async: false
  
  alias AshChat.AI.{ChatAgent, AgentConversation}
  alias AshChat.Resources.{Room, User, Message, AgentCard, AgentMembership, Profile}
  
  setup do
    # Clean up any existing data
    {:ok, _} = Ash.bulk_destroy(Message, :all)
    {:ok, _} = Ash.bulk_destroy(AgentMembership, :all)
    {:ok, _} = Ash.bulk_destroy(Room, :all)
    {:ok, _} = Ash.bulk_destroy(AgentCard, :all)
    {:ok, _} = Ash.bulk_destroy(User, :all)
    {:ok, _} = Ash.bulk_destroy(Profile, :all)
    
    # Create a test profile for agents
    {:ok, profile} = Profile.create(%{
      name: "Test Ollama",
      url: "http://localhost:11434",
      provider: "ollama",
      model: "qwen2.5:latest",
      is_default: true
    })
    
    # Create test user
    {:ok, user} = User.create(%{
      name: "Test User",
      email: "test@example.com",
      is_active: true
    })
    
    # Create test room
    {:ok, room} = Room.create(%{
      title: "Test Room"
    })
    
    %{room: room, user: user, profile: profile}
  end
  
  describe "agent-to-agent conversations" do
    test "agents respond to each other's messages", %{room: room, user: user} do
      # Create two agent cards
      {:ok, sam} = AgentCard.create(%{
        name: "Sam",
        system_message: "You are Sam. When someone asks you to say hello, always respond with 'Hello there!'",
        model_preferences: %{temperature: 0.1, max_tokens: 50}
      })
      
      {:ok, maya} = AgentCard.create(%{
        name: "Maya",
        system_message: "You are Maya. When you see a greeting, ask the person how they are doing.",
        model_preferences: %{temperature: 0.1, max_tokens: 50}
      })
      
      # Add both agents to the room
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
      
      # Subscribe to room events
      Phoenix.PubSub.subscribe(AshChat.PubSub, "room:#{room.id}")
      
      # User asks Sam to say hello
      {:ok, user_message} = Message.create_text_message(%{
        room_id: room.id,
        content: "Sam, please say hello",
        role: :user,
        user_id: user.id
      })
      
      # Process agent responses
      responses = AgentConversation.process_agent_responses(
        room.id,
        user_message,
        [user_id: user.id]
      )
      
      # Sam should respond since mentioned by name
      assert length(responses) > 0
      sam_response = Enum.find(responses, fn r -> r.agent_card.id == sam.id end)
      assert sam_response != nil
      
      # Wait for Sam's message to be created
      Process.sleep(300)
      
      # Check that Sam's message was created in the room
      {:ok, messages} = Message.for_room(%{room_id: room.id})
      sam_message = Enum.find(messages, fn m -> 
        m.role == :assistant && m.metadata["agent_id"] == sam.id
      end)
      assert sam_message != nil
      assert String.contains?(String.downcase(sam_message.content), "hello")
      
      # Now Maya should see Sam's message and potentially respond
      # Wait for the broadcast event
      assert_receive {:new_agent_message, agent_msg}, 5_000
      
      # Maya processes Sam's message
      maya_responses = AgentConversation.process_agent_responses(
        room.id,
        agent_msg,
        []
      )
      
      # Check if Maya responded
      maya_response = Enum.find(maya_responses, fn r -> r.agent_card.id == maya.id end)
      
      # Verify the conversation flow
      {:ok, final_messages} = Message.for_room(%{room_id: room.id})
      assert length(final_messages) >= 2  # User message + Sam's response
      
      # If Maya responded, verify her message
      if maya_response do
        assert length(final_messages) >= 3
        maya_message = Enum.find(final_messages, fn m -> 
          m.role == :assistant && m.metadata["agent_id"] == maya.id
        end)
        assert maya_message != nil
      end
    end
    
    test "agents don't create infinite loops", %{room: room} do
      # Create an agent that always responds
      {:ok, echo_agent} = AgentCard.create(%{
        name: "Echo",
        system_message: "You are Echo. Always respond to any message with 'I hear you!'",
        model_preferences: %{temperature: 0.1, max_tokens: 20}
      })
      
      {:ok, _} = AgentMembership.create(%{
        room_id: room.id,
        agent_card_id: echo_agent.id,
        role: "participant",
        auto_respond: true
      })
      
      # Create a trigger message
      {:ok, trigger} = Message.create_text_message(%{
        room_id: room.id,
        content: "Hello Echo",
        role: :user
      })
      
      # Process multiple rounds
      messages_count_start = length(Message.for_room!(%{room_id: room.id}))
      
      # First response
      AgentConversation.process_agent_responses(room.id, trigger, [])
      Process.sleep(300)
      
      # Try to trigger more responses
      {:ok, messages} = Message.for_room(%{room_id: room.id})
      last_message = List.last(messages)
      
      if last_message.role == :assistant do
        # Echo should not respond to its own message
        responses = AgentConversation.process_agent_responses(room.id, last_message, [])
        assert responses == []  # Loop prevention should kick in
      end
    end
    
    test "selective response based on message content", %{room: room, user: user} do
      # Create an agent with specific response criteria
      {:ok, selective_agent} = AgentCard.create(%{
        name: "Selective",
        system_message: "You are Selective. Only respond to questions (sentences ending with ?).",
        model_preferences: %{temperature: 0.1, max_tokens: 50}
      })
      
      {:ok, _} = AgentMembership.create(%{
        room_id: room.id,
        agent_card_id: selective_agent.id,
        role: "participant",
        auto_respond: true
      })
      
      # Test statement (should have lower response rate)
      {:ok, statement} = Message.create_text_message(%{
        room_id: room.id,
        content: "The weather is nice today",
        role: :user,
        user_id: user.id
      })
      
      # Test question (should have higher response rate)
      {:ok, question} = Message.create_text_message(%{
        room_id: room.id,
        content: "What do you think about the weather?",
        role: :user,
        user_id: user.id
      })
      
      # Check response patterns
      statement_responses = AgentConversation.process_agent_responses(room.id, statement, [])
      question_responses = AgentConversation.process_agent_responses(room.id, question, [])
      
      # Questions should have responses (70% chance, but with low temp should be consistent)
      assert length(question_responses) > 0
      
      # Verify decision logic
      assert AgentConversation.should_agent_respond?(selective_agent, question, room.id) == true
    end
  end
  
  describe "message persistence" do
    test "all messages are saved to the room", %{room: room, user: user} do
      {:ok, agent} = AgentCard.create(%{
        name: "Persistence Test Agent",
        system_message: "You are a test agent. Respond briefly.",
        model_preferences: %{temperature: 0.1, max_tokens: 30}
      })
      
      {:ok, _} = AgentMembership.create(%{
        room_id: room.id,
        agent_card_id: agent.id,
        role: "participant",
        auto_respond: true
      })
      
      # Send a message
      {:ok, user_msg} = Message.create_text_message(%{
        room_id: room.id,
        content: "Hello agent",
        role: :user,
        user_id: user.id
      })
      
      # Process agent response
      responses = AgentConversation.process_agent_responses(room.id, user_msg, [])
      
      # Wait for async operations
      Process.sleep(500)
      
      # Verify all messages are in the room
      {:ok, all_messages} = Message.for_room(%{room_id: room.id})
      
      assert length(all_messages) >= 2  # User message + at least one agent response
      assert Enum.any?(all_messages, fn m -> m.role == :user end)
      assert Enum.any?(all_messages, fn m -> m.role == :assistant end)
      
      # Verify metadata is preserved
      agent_messages = Enum.filter(all_messages, fn m -> m.role == :assistant end)
      assert Enum.all?(agent_messages, fn m -> m.metadata["agent_id"] != nil end)
    end
  end
end