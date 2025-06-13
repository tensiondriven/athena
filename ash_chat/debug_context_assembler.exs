# Debug ContextAssembler to find why messages aren't building

defmodule DebugContextAssembler do
  def run do
    IO.puts("🔍 Debug ContextAssembler")
    IO.puts("========================")
    
    # Set up data
    result = AshChat.Setup.reset_demo_data()
    {:ok, rooms} = AshChat.Resources.Room.read()
    conversation_room = Enum.find(rooms, &(&1.title == "Conversation Lounge"))
    
    if conversation_room do
      # Get Sam agent
      {:ok, agent_memberships} = AshChat.Resources.AgentMembership.read()
      sam_membership = Enum.find(agent_memberships, fn membership ->
        {:ok, agent} = Ash.get(AshChat.Resources.AgentCard, membership.agent_card_id)
        agent.name == "Sam" && membership.room_id == conversation_room.id
      end)
      
      if sam_membership do
        {:ok, sam_agent} = Ash.get(AshChat.Resources.AgentCard, sam_membership.agent_card_id)
        
        # Get messages in room
        messages = AshChat.AI.ChatAgent.get_room_messages(conversation_room.id)
        IO.puts("📧 Room messages count: #{length(messages)}")
        
        for message <- messages do
          IO.puts("  - #{message.role}: #{String.slice(message.content, 0, 50)}...")
        end
        
        # Test ContextAssembler
        IO.puts("\n🔧 Testing ContextAssembler...")
        user_message = "How are you?"
        
        context_assembler = AshChat.AI.ContextAssembler.build_for_room(
          conversation_room, 
          sam_agent, 
          user_message,
          [user_id: hd(result.users).id]
        )
        
        # Inspect components
        components = AshChat.AI.ContextAssembler.inspect_components(context_assembler)
        IO.puts("📊 Context components: #{length(components)}")
        
        for component <- components do
          IO.puts("  #{component.order}. #{component.type} (priority: #{component.priority})")
          IO.puts("     Preview: #{component.content_preview}")
        end
        
        # Try to assemble
        assembled_messages = AshChat.AI.ContextAssembler.assemble(context_assembler)
        IO.puts("\n📨 Assembled messages count: #{length(assembled_messages)}")
        
        for {message, index} <- Enum.with_index(assembled_messages) do
          IO.puts("  #{index + 1}. #{message.role}: #{String.slice(message.content, 0, 80)}...")
        end
        
        if Enum.empty?(assembled_messages) do
          IO.puts("❌ PROBLEM: No messages assembled!")
        else
          IO.puts("✅ Messages assembled successfully")
        end
        
      else
        IO.puts("❌ Sam agent membership not found")
      end
    else
      IO.puts("❌ Conversation Lounge not found")
    end
  end
end

DebugContextAssembler.run()