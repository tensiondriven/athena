# Mock bot conversation simulation
# This simulates a conversation without requiring actual AI

defmodule MockBotConversation do
  alias AshChat.Resources.{Room, User, Message, AgentMembership, AgentCard}
  
  def simulate do
    IO.puts("🤖 Mock Bot Conversation Simulator")
    IO.puts("==================================\n")
    
    # Reset demo data
    IO.puts("1️⃣ Resetting demo data...")
    AshChat.Setup.reset_demo_data()
    
    # Find conversation lounge and participants
    {:ok, rooms} = Room.read()
    room = Enum.find(rooms, &(&1.title == "Conversation Lounge"))
    
    {:ok, users} = User.read()
    alice = Enum.find(users, &(&1.name == "Alice"))
    
    if room && alice do
      IO.puts("✅ Found Conversation Lounge and Alice\n")
      
      # Get the agent cards for Sam and Maya
      {:ok, agent_cards} = AgentCard.read()
      sam = Enum.find(agent_cards, &(&1.name == "Sam"))
      maya = Enum.find(agent_cards, &(&1.name == "Maya"))
      
      IO.puts("2️⃣ Starting conversation...\n")
      
      # Conversation flow
      messages = [
        {alice.id, :user, "Hey Sam and Maya! What's everyone up to today?"},
        {nil, :assistant, "Hey there! Just enjoying this nice day. Been working on some projects and trying to stay productive. How about you?", sam},
        {nil, :assistant, "Hi! I've been reading this fascinating article about urban planning. Did you know that some cities are designing neighborhoods specifically to encourage more social interaction? What have you been working on lately, Alice?", maya},
        {alice.id, :user, "That sounds really interesting, Maya! I've been setting up this new chat system. Sam, what kind of projects are you working on?"},
        {nil, :assistant, "Oh cool! I've been tinkering with some photography stuff - trying to learn more about composition. Maya, that urban planning thing sounds neat. Like what kind of designs encourage interaction?", sam},
        {nil, :assistant, "Well, they're creating more shared spaces like community gardens and pedestrian-only streets with cafes. The idea is that when people have reasons to linger and interact, communities become stronger. Sam, photography is such a great hobby! Are you focusing on any particular style?", maya},
        {nil, :assistant, "Mostly street photography right now! I love capturing candid moments. Those community spaces sound perfect for that actually - lots of natural interactions to photograph. Alice, how's the chat system coming along?", sam}
      ]
      
      # Create messages with timestamps
      created_messages = []
      base_time = DateTime.utc_now()
      
      for {{user_id, role, content, agent}, idx} <- Enum.with_index(messages) do
        timestamp = DateTime.add(base_time, idx * 30, :second)
        
        msg_params = %{
          room_id: room.id,
          content: content,
          role: role,
          user_id: user_id,
          created_at: timestamp,
          updated_at: timestamp
        }
        
        # Create the message
        {:ok, msg} = Message.create(msg_params)
        created_messages = created_messages ++ [msg]
        
        # Display as we create
        author = cond do
          user_id == alice.id -> "👤 Alice"
          agent && agent.name == "Sam" -> "🤖 Sam"
          agent && agent.name == "Maya" -> "🤖 Maya"
          true -> "❓ Unknown"
        end
        
        time_str = timestamp |> DateTime.to_string() |> String.slice(11..18)
        IO.puts("[#{time_str}] #{author}:")
        IO.puts("  #{content}")
        IO.puts("")
      end
      
      IO.puts(String.duplicate("=", 60))
      IO.puts("\n✅ Mock conversation complete!")
      IO.puts("📊 Created #{length(created_messages)} messages")
      IO.puts("🎯 Demonstrated multi-agent conversation between Sam and Maya")
      
      # Summary
      IO.puts("\n📝 Key observations:")
      IO.puts("  • Sam: Casual, asks follow-up questions, shares personal interests")
      IO.puts("  • Maya: Thoughtful, shares interesting facts, connects topics")
      IO.puts("  • Both agents maintain distinct personalities and conversation styles")
      IO.puts("  • Natural flow with agents responding to each other")
      
    else
      IO.puts("❌ Could not find Conversation Lounge or Alice")
    end
  end
end

# Run the simulation
MockBotConversation.simulate()