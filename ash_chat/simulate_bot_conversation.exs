# Direct bot conversation simulation
# This runs in the same process as the data to avoid ETS isolation

defmodule BotConversationSimulator do
  alias AshChat.AI.ChatAgent
  alias AshChat.Resources.{Room, User, Message, AgentMembership, AgentCard}
  
  def simulate do
    IO.puts("🤖 Bot Conversation Simulator")
    IO.puts("=============================\n")
    
    # Reset demo data first
    IO.puts("1️⃣ Resetting demo data...")
    AshChat.Setup.reset_demo_data()
    
    # Find conversation lounge and Alice
    {:ok, rooms} = Room.read()
    room = Enum.find(rooms, &(&1.title == "Conversation Lounge"))
    
    {:ok, users} = User.read()
    alice = Enum.find(users, &(&1.name == "Alice"))
    
    if room && alice do
      IO.puts("✅ Found Conversation Lounge and Alice\n")
      
      # Send initial message
      IO.puts("2️⃣ Alice sends a message...")
      ChatAgent.send_text_message(room.id, "Hey Sam and Maya! What's everyone up to today?", alice.id)
      
      # Get auto-responding agents
      {:ok, agent_memberships} = AgentMembership.auto_responders_for_room(%{room_id: room.id})
      IO.puts("📊 Found #{length(agent_memberships)} auto-responding agents\n")
      
      # Process each agent's response
      IO.puts("3️⃣ Generating agent responses...")
      for membership <- agent_memberships do
        {:ok, agent_card} = Ash.get(AgentCard, membership.agent_card_id)
        IO.puts("   🤖 #{agent_card.name} is thinking...")
        
        # Simulate the agent processing
        ChatAgent.process_message_with_agent_card(
          room,
          "Hey Sam and Maya! What's everyone up to today?",
          agent_card,
          [user_id: alice.id]
        )
      end
      
      # Wait a bit for processing
      IO.puts("\n⏳ Waiting for responses...")
      Process.sleep(3000)
      
      # Display all messages
      IO.puts("\n4️⃣ Conversation transcript:")
      IO.puts("="*50)
      
      {:ok, messages} = Message.for_room(%{room_id: room.id})
      
      for msg <- messages do
        author = cond do
          msg.user_id == alice.id -> "Alice"
          msg.role == :assistant -> 
            # Try to identify which agent by checking recent agent activity
            "AI Agent"
          true -> "Unknown"
        end
        
        timestamp = msg.created_at |> DateTime.to_string() |> String.slice(11..18)
        IO.puts("[#{timestamp}] #{author}: #{msg.content}")
      end
      
      IO.puts("="*50)
      IO.puts("\n✅ Simulation complete!")
      
      # Show message count
      IO.puts("📊 Total messages: #{length(messages)}")
      
    else
      IO.puts("❌ Could not find Conversation Lounge or Alice")
    end
  end
end

# Run the simulation
BotConversationSimulator.simulate()