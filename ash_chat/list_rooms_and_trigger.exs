# List rooms and trigger Maya
require Logger

IO.puts("Checking all rooms in the system:")
rooms = AshChat.Resources.Room.read!()

if length(rooms) == 0 do
  IO.puts("No rooms found!")
else
  for room <- rooms do
    IO.puts("\nRoom: #{room.title}")
    IO.puts("ID: #{room.id}")
    
    # Get messages count
    messages = AshChat.Resources.Message.for_room!(room.id)
    IO.puts("Messages: #{length(messages)}")
    
    # Get members
    memberships = case AshChat.Resources.RoomMembership.for_room(%{room_id: room.id}) do
      {:ok, mems} -> mems
      _ -> []
    end
    
    agent_memberships = case AshChat.Resources.AgentMembership.for_room(%{room_id: room.id}) do
      {:ok, mems} -> mems
      _ -> []
    end
    
    IO.puts("Human members: #{length(memberships)}")
    IO.puts("Agent members: #{length(agent_memberships)}")
  end
  
  # Use the first room
  if room = List.first(rooms) do
    IO.puts("\n\n=== Working with room: #{room.title} ===")
    
    # Find Maya and Jonathan
    maya = AshChat.Resources.AgentCard.read!() |> Enum.find(&(&1.name == "Maya"))
    jonathan = AshChat.Resources.User.read!() |> Enum.find(&(&1.name == "Jonathan"))
    
    if maya && jonathan do
      IO.puts("Found Maya (#{maya.id}) and Jonathan (#{jonathan.id})")
      
      # Check if Maya is in the room
      maya_in_room = case AshChat.Resources.AgentMembership.for_room(%{room_id: room.id}) do
        {:ok, memberships} -> Enum.find(memberships, &(&1.agent_card_id == maya.id))
        _ -> nil
      end
      
      if maya_in_room do
        IO.puts("Maya is already in the room. Auto-respond: #{maya_in_room.auto_respond}")
      else
        IO.puts("Adding Maya to the room...")
        {:ok, _} = AshChat.Resources.AgentMembership.create(%{
          room_id: room.id,
          agent_card_id: maya.id,
          role: "participant",
          auto_respond: true
        })
        IO.puts("✓ Added Maya")
      end
      
      # Send a message
      IO.puts("\nSending message as Jonathan...")
      {:ok, msg} = AshChat.Resources.Message.create_text_message(%{
        room_id: room.id,
        content: "Hi Maya! I've been wondering - what's your perspective on the art of conversation? What makes a discussion truly engaging for you?",
        role: :user,
        user_id: jonathan.id
      })
      
      IO.puts("Message sent: \"#{String.slice(msg.content, 0, 50)}...\"")
      
      # Wait for response
      IO.puts("\nWaiting for Maya's response...")
      Process.sleep(7000)
      
      # Get all messages after ours
      all_messages = AshChat.Resources.Message.for_room!(room.id) |> Enum.reverse()
      our_msg_found = false
      
      IO.puts("\nRecent messages:")
      for message <- all_messages do
        if message.id == msg.id do
          IO.puts("\n[Our message found]")
          our_msg_found = true
        end
        
        if our_msg_found do
          sender = cond do
            message.role == :user && message.user_id ->
              case Ash.get(AshChat.Resources.User, message.user_id) do
                {:ok, user} -> "#{user.name} (User)"
                _ -> "User"
              end
            message.role == :assistant ->
              agent_name = get_in(message.metadata || %{}, ["agent_name"]) || "Assistant"
              "#{agent_name} (AI)"
            true ->
              "System"
          end
          
          time = Calendar.strftime(message.created_at, "%I:%M:%S %p")
          IO.puts("\n[#{time}] #{sender}:")
          IO.puts("#{message.content}")
        end
      end
    else
      IO.puts("Could not find Maya or Jonathan")
    end
  end
end