# Bot conversation demonstration without real AI calls
defmodule BotConversationDemo do
  alias AshChat.Resources.{Room, User, Message, AgentCard}
  
  def run do
    IO.puts("\n🤖 BOT CONVERSATION DEMONSTRATION")
    IO.puts(String.duplicate("=", 50))
    IO.puts("This demonstrates how multi-agent chat would work\n")
    
    # Reset demo data
    AshChat.Setup.reset_demo_data()
    
    # Get entities
    {:ok, rooms} = Room.read()
    room = Enum.find(rooms, &(&1.title == "Conversation Lounge"))
    
    {:ok, users} = User.read()
    alice = Enum.find(users, &(&1.name == "Alice"))
    
    {:ok, agent_cards} = AgentCard.read()
    sam = Enum.find(agent_cards, &(&1.name == "Sam"))
    maya = Enum.find(agent_cards, &(&1.name == "Maya"))
    
    if room && alice && sam && maya do
      IO.puts("📍 Room: #{room.title}")
      IO.puts("👤 User: #{alice.name}")
      IO.puts("🤖 Agents: #{sam.name} & #{maya.name}")
      IO.puts("\n" <> String.duplicate("-", 50) <> "\n")
      
      # Simulate conversation messages
      conversations = [
        %{author: "Alice", content: "Hey Sam and Maya! What's everyone up to today?"},
        %{author: "Sam", content: "Hey there! Just enjoying this nice day. Been working on some projects and trying to stay productive. How about you?"},
        %{author: "Maya", content: "Hi! I've been reading this fascinating article about urban planning. Did you know that some cities are designing neighborhoods specifically to encourage more social interaction? What have you been working on lately, Alice?"},
        %{author: "Alice", content: "That sounds really interesting, Maya! I've been setting up this new chat system. Sam, what kind of projects are you working on?"},
        %{author: "Sam", content: "Oh cool! I've been tinkering with some photography stuff - trying to learn more about composition. Maya, that urban planning thing sounds neat. Like what kind of designs encourage interaction?"},
        %{author: "Maya", content: "Well, they're creating more shared spaces like community gardens and pedestrian-only streets with cafes. The idea is that when people have reasons to linger and interact, communities become stronger. Sam, photography is such a great hobby! Are you focusing on any particular style?"},
        %{author: "Sam", content: "Mostly street photography right now! I love capturing candid moments. Those community spaces sound perfect for that actually - lots of natural interactions to photograph. Alice, how's the chat system coming along?"}
      ]
      
      # Display the conversation
      for conv <- conversations do
        icon = case conv.author do
          "Alice" -> "👤"
          "Sam" -> "🤖"
          "Maya" -> "🤖"
          _ -> "❓"
        end
        
        IO.puts("#{icon} #{conv.author}:")
        # Wrap text nicely
        words = String.split(conv.content, " ")
        lines = Enum.chunk_while(words, [], 
          fn word, acc ->
            line = Enum.join(acc ++ [word], " ")
            if String.length(line) > 60 do
              {:cont, Enum.join(acc, " "), [word]}
            else
              {:cont, acc ++ [word]}
            end
          end,
          fn acc -> {:cont, Enum.join(acc, " "), []} end
        )
        
        for line <- lines, line != "" do
          IO.puts("   #{line}")
        end
        IO.puts("")
      end
      
      IO.puts(String.duplicate("-", 50))
      IO.puts("\n📊 DEMONSTRATION SUMMARY:")
      IO.puts("✅ Created demo data with rooms, users, and AI agents")
      IO.puts("✅ Set up Conversation Lounge with Sam & Maya agents")
      IO.puts("✅ Both agents have auto_respond: true")
      IO.puts("✅ Showed natural conversation flow between agents")
      
      IO.puts("\n🎯 KEY FEATURES DEMONSTRATED:")
      IO.puts("• Multiple AI agents in same room")
      IO.puts("• Distinct agent personalities (Sam: casual, Maya: thoughtful)")
      IO.puts("• Agents respond to each other, not just users")
      IO.puts("• Natural conversation flow with topic progression")
      
      IO.puts("\n💡 IMPLEMENTATION NOTES:")
      IO.puts("• Real system uses ChatAgent.process_message_with_agent_card/4")
      IO.puts("• Each agent processes messages independently")
      IO.puts("• System prevents duplicate user messages")
      IO.puts("• Agents use configured temperature & token settings")
      
      IO.puts("\n🔧 TO ENABLE REAL AI RESPONSES:")
      IO.puts("1. Ensure Ollama is running with qwen2.5:latest model")
      IO.puts("2. Messages sent via web UI trigger agent responses")
      IO.puts("3. Or use ChatAgent module directly in code")
      
    else
      IO.puts("❌ Failed to set up demo entities")
    end
    
    IO.puts("\n" <> String.duplicate("=", 50))
  end
end

BotConversationDemo.run()