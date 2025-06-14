#!/usr/bin/env elixir

require Logger

# Find the Conversation Lounge room
room = AshChat.Resources.Room.read!() 
  |> Enum.find(&(&1.title == "Conversation Lounge"))

if room do
  Logger.info("Found room: #{room.title}")
  
  # Find Jonathan user
  jonathan = AshChat.Resources.User.read!() 
    |> Enum.find(&(&1.name == "Jonathan"))
  
  if jonathan do
    Logger.info("Found user: #{jonathan.name}")
    
    # Check agent memberships
    {:ok, memberships} = AshChat.Resources.AgentMembership.for_room(%{room_id: room.id})
    Logger.info("Agents in room: #{length(memberships)}")
    
    for membership <- memberships do
      {:ok, agent} = Ash.get(AshChat.Resources.AgentCard, membership.agent_card_id)
      Logger.info("  - #{agent.name} (auto_respond: #{membership.auto_respond})")
    end
    
    # Send a test message
    Logger.info("\nSending test message...")
    {:ok, message} = AshChat.Resources.Message.create_text_message(%{
      room_id: room.id,
      content: "Hello Sam and Maya! What do you think about the potential of AI in education?",
      role: :user,
      user_id: jonathan.id
    })
    
    Logger.info("Message sent: #{message.id}")
    
    # Process agent responses
    Logger.info("Processing agent responses...")
    responses = AshChat.AI.AgentConversation.process_agent_responses(
      room.id,
      message,
      [user_id: jonathan.id]
    )
    
    Logger.info("Got #{length(responses)} agent responses")
    
    # Wait for processing
    Process.sleep(2000)
    
    # Get recent messages
    {:ok, messages} = AshChat.Resources.Message.for_room(%{room_id: room.id})
    recent = messages |> Enum.take(-5)
    
    Logger.info("\nRecent messages:")
    for msg <- recent do
      author = case msg.role do
        :user -> 
          {:ok, user} = Ash.get(AshChat.Resources.User, msg.user_id)
          user.name
        :assistant ->
          metadata = msg.metadata || %{}
          agent_id = Map.get(metadata, "agent_id")
          if agent_id do
            case Ash.get(AshChat.Resources.AgentCard, agent_id) do
              {:ok, agent} -> agent.name
              _ -> "Unknown Agent"
            end
          else
            "Assistant"
          end
      end
      
      Logger.info("[#{author}] #{String.slice(msg.content || "", 0, 80)}...")
    end
  else
    Logger.error("Could not find Jonathan user")
  end
else
  Logger.error("Could not find Conversation Lounge room")
end