#!/usr/bin/env elixir

# Ensure the application is started
Application.ensure_all_started(:ash_chat)

require Logger

Logger.info("Testing agent conversation...")

# Give the app a moment to fully initialize
Process.sleep(1000)

# Find the Conversation Lounge
rooms = AshChat.Resources.Room.read!()
Logger.info("Found #{length(rooms)} rooms")

conversation_room = Enum.find(rooms, fn r -> r.title == "Conversation Lounge" end)

if conversation_room do
  Logger.info("Found Conversation Lounge: #{conversation_room.id}")
  
  # Check agent memberships
  {:ok, memberships} = AshChat.Resources.AgentMembership.for_room(%{room_id: conversation_room.id})
  Logger.info("Agents in room: #{length(memberships)}")
  
  for membership <- memberships do
    {:ok, agent} = Ash.get(AshChat.Resources.AgentCard, membership.agent_card_id)
    Logger.info("  - #{agent.name} (auto_respond: #{membership.auto_respond})")
  end
  
  # Find Jonathan
  users = AshChat.Resources.User.read!()
  jonathan = Enum.find(users, fn u -> u.name == "Jonathan" end)
  
  if jonathan do
    Logger.info("\nSending message as #{jonathan.name}...")
    
    # Create a test message
    {:ok, message} = AshChat.Resources.Message.create_text_message(%{
      room_id: conversation_room.id,
      content: "Hey Sam and Maya! I've been thinking about AI in education. What are your thoughts on how AI could help personalize learning for different students?",
      role: :user,
      user_id: jonathan.id
    })
    
    Logger.info("Message created: #{message.id}")
    
    # Process agent responses
    Logger.info("Processing agent responses...")
    
    try do
      responses = AshChat.AI.AgentConversation.process_agent_responses(
        conversation_room.id,
        message,
        [user_id: jonathan.id]
      )
      
      Logger.info("Got #{length(responses)} agent responses")
      
      # Wait for processing
      Process.sleep(3000)
      
      # Get recent messages
      {:ok, messages} = AshChat.Resources.Message.for_room(%{room_id: conversation_room.id})
      recent = messages |> Enum.take(-10)
      
      Logger.info("\nRecent messages in room:")
      for msg <- recent do
        author = case msg.role do
          :user -> 
            case Ash.get(AshChat.Resources.User, msg.user_id) do
              {:ok, user} -> user.name
              _ -> "Unknown User"
            end
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
        
        content = String.slice(msg.content || "", 0, 100)
        Logger.info("[#{author}] #{content}#{if String.length(msg.content || "") > 100, do: "...", else: ""}")
      end
      
    rescue
      e ->
        Logger.error("Error processing agent responses: #{inspect(e)}")
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
    end
    
  else
    Logger.error("Could not find Jonathan user")
    Logger.info("Available users:")
    for u <- users, do: Logger.info("  - #{u.name}")
  end
else
  Logger.error("Could not find Conversation Lounge room")
  Logger.info("Available rooms:")
  for r <- rooms, do: Logger.info("  - #{r.title}")
end