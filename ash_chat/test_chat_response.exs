#!/usr/bin/env elixir

# Simple test to check chat responses
require Logger

# Get available rooms
{:ok, rooms} = AshChat.Resources.Room.read()
IO.puts("Available rooms: #{length(rooms)}")
for room <- rooms do
  IO.puts("  - #{room.title} (#{room.id})")
end

# Find the Conversation Lounge
conversation_lounge = Enum.find(rooms, fn r -> r.title == "Conversation Lounge" end)

if conversation_lounge do
  # Get Bob user
  {:ok, users} = AshChat.Resources.User.read()
  bob = Enum.find(users, fn u -> u.name == "Bob" end)
  
  if bob do
    Logger.info("Testing chat in room: #{conversation_lounge.title}")
    Logger.info("User: #{bob.display_name}")
    
    # Create a user message
    {:ok, user_message} = AshChat.Resources.Message.create_text_message(%{
      room_id: conversation_lounge.id,
      content: "Hello everyone! What's your favorite way to spend a weekend?",
      role: :user,
      user_id: bob.id
    })
    
    Logger.info("Created user message: #{user_message.content}")
    
    # Wait a bit for agent responses
    Logger.info("Waiting for agent responses...")
    Process.sleep(5000)
    
    # Check for new messages
    {:ok, messages} = AshChat.Resources.Message.for_room(%{room_id: conversation_lounge.id})
    Logger.info("Total messages in room: #{length(messages)}")
    
    # Show the last few messages
    messages
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    |> Enum.take(5)
    |> Enum.reverse()
    |> Enum.each(fn msg ->
      author = case msg.role do
        :user -> 
          {:ok, user} = Ash.get(AshChat.Resources.User, msg.user_id)
          user.name
        :assistant -> 
          metadata = msg.metadata || %{}
          agent_id = Map.get(metadata, "agent_id") || Map.get(metadata, :agent_id)
          if agent_id do
            case Ash.get(AshChat.Resources.AgentCard, agent_id) do
              {:ok, agent} -> "Agent: #{agent.name}"
              _ -> "Assistant"
            end
          else
            "Assistant"
          end
      end
      
      Logger.info("#{author}: #{String.slice(msg.content, 0, 100)}#{if String.length(msg.content) > 100, do: "...", else: ""}")
    end)
  else
    Logger.error("Could not find Bob user")
  end
else
  Logger.error("Could not find Conversation Lounge room")
end