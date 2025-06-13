#!/usr/bin/env elixir

IO.puts("Starting simple AI test...")

# List all rooms
rooms = AshChat.Resources.Room.read!()
IO.puts("Found #{length(rooms)} rooms")

# Find Conversation Lounge
lounge = Enum.find(rooms, fn r -> r.title == "Conversation Lounge" end)

if lounge do
  IO.puts("Found Conversation Lounge: #{lounge.id}")
  
  # Get agent memberships
  case AshChat.Resources.AgentMembership.for_room(%{room_id: lounge.id}) do
    {:ok, memberships} ->
      IO.puts("Agents in room: #{length(memberships)}")
      for m <- memberships do
        case Ash.get(AshChat.Resources.AgentCard, m.agent_card_id) do
          {:ok, agent} -> IO.puts("  - #{agent.name}")
          _ -> IO.puts("  - Unknown agent")
        end
      end
    _ ->
      IO.puts("Could not get agent memberships")
  end
  
  # Find Jonathan
  users = AshChat.Resources.User.read!()
  jonathan = Enum.find(users, fn u -> u.name == "Jonathan" end)
  
  if jonathan do
    IO.puts("\nSending message as #{jonathan.name}...")
    
    case AshChat.Resources.Message.create_text_message(%{
      room_id: lounge.id,
      content: "Hey Sam and Maya! How are you both doing today?",
      role: :user,
      user_id: jonathan.id
    }) do
      {:ok, msg} ->
        IO.puts("Message sent successfully!")
        IO.puts("Triggering agent responses...")
        
        # Trigger agent responses
        responses = AshChat.AI.AgentConversation.process_agent_responses(
          lounge.id,
          msg,
          [user_id: jonathan.id]
        )
        
        IO.puts("Agent responses: #{inspect(responses)}")
        
      {:error, error} ->
        IO.puts("Error sending message: #{inspect(error)}")
    end
  else
    IO.puts("Could not find Jonathan user")
  end
else
  IO.puts("Could not find Conversation Lounge")
  IO.puts("Available rooms:")
  for r <- rooms, do: IO.puts("  - #{r.title}")
end