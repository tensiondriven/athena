# Check available rooms and trigger Maya
require Logger

IO.puts("Available rooms:")
rooms = AshChat.Resources.Room.read!()
for room <- rooms do
  IO.puts("- #{room.title} (ID: #{room.id})")
end

# Find the first room with messages
room_with_messages = Enum.find(rooms, fn room ->
  messages = AshChat.Resources.Message.for_room!(room.id)
  length(messages) > 0
end)

if room_with_messages do
  IO.puts("\n\nWorking with room: #{room_with_messages.title}")
  
  # Find Maya
  maya = AshChat.Resources.AgentCard.read!() |> Enum.find(&(&1.name == "Maya"))
  
  if maya do
    IO.puts("Found Maya agent: #{maya.id}")
    
    # Get Jonathan user
    jonathan = AshChat.Resources.User.read!() |> Enum.find(&(&1.name == "Jonathan"))
    
    if jonathan do
      # Send a message as Jonathan
      {:ok, user_msg} = AshChat.Resources.Message.create_text_message(%{
        room_id: room_with_messages.id,
        content: "Hey Maya! What do you think about coffee? Do you have a favorite way to prepare it?",
        role: :user,
        user_id: jonathan.id
      })
      
      IO.puts("\nSent message as Jonathan: #{user_msg.content}")
      IO.puts("Message ID: #{user_msg.id}")
      
      # The message event processor should automatically trigger Maya's response
      IO.puts("\nWaiting for Maya's response...")
      Process.sleep(5000)
      
      # Check for new messages
      new_messages = AshChat.Resources.Message.for_room!(room_with_messages.id)
      |> Enum.drop_while(&(&1.id != user_msg.id))
      |> Enum.drop(1)  # Skip our message
      
      if length(new_messages) > 0 do
        IO.puts("\n✓ Got responses:")
        for msg <- new_messages do
          agent_name = get_in(msg.metadata || %{}, ["agent_name"]) || "Unknown"
          IO.puts("\n#{agent_name}: #{msg.content}")
        end
      else
        IO.puts("\n✗ No response yet. Maya may not be set to auto-respond in this room.")
        
        # Check Maya's membership
        maya_membership = AshChat.Resources.AgentMembership.for_room(%{room_id: room_with_messages.id})
        |> case do
          {:ok, memberships} -> Enum.find(memberships, &(&1.agent_card_id == maya.id))
          _ -> nil
        end
        
        if maya_membership do
          IO.puts("Maya is in the room. Auto-respond: #{maya_membership.auto_respond}")
          
          if !maya_membership.auto_respond do
            IO.puts("\nUpdating Maya to auto-respond...")
            AshChat.Resources.AgentMembership.update!(maya_membership, %{auto_respond: true})
            IO.puts("✓ Updated Maya's auto-respond setting")
          end
        else
          IO.puts("Maya is not in this room")
        end
      end
    else
      IO.puts("Could not find Jonathan user")
    end
  else
    IO.puts("Could not find Maya agent")
  end
else
  IO.puts("\nNo rooms with messages found. Creating a test in the first room...")
  
  if first_room = List.first(rooms) do
    IO.puts("Using room: #{first_room.title}")
    
    # Proceed with the test in this room
    maya = AshChat.Resources.AgentCard.read!() |> Enum.find(&(&1.name == "Maya"))
    jonathan = AshChat.Resources.User.read!() |> Enum.find(&(&1.name == "Jonathan"))
    
    if maya && jonathan do
      # Make sure Maya is in the room
      maya_membership = AshChat.Resources.AgentMembership.for_room(%{room_id: first_room.id})
      |> case do
        {:ok, memberships} -> Enum.find(memberships, &(&1.agent_card_id == maya.id))
        _ -> nil
      end
      
      if !maya_membership do
        IO.puts("Adding Maya to the room...")
        AshChat.Resources.AgentMembership.create!(%{
          room_id: first_room.id,
          agent_card_id: maya.id,
          role: "participant",
          auto_respond: true
        })
      end
      
      # Send test message
      {:ok, msg} = AshChat.Resources.Message.create_text_message(%{
        room_id: first_room.id,
        content: "Hi Maya! Tell me about your favorite coffee experience.",
        role: :user,
        user_id: jonathan.id
      })
      
      IO.puts("\nSent test message")
      Process.sleep(5000)
      
      # Check for response
      messages = AshChat.Resources.Message.for_room!(first_room.id)
      |> Enum.drop_while(&(&1.id != msg.id))
      |> Enum.drop(1)
      
      if length(messages) > 0 do
        IO.puts("\n✓ Maya responded:")
        for msg <- messages do
          agent_name = get_in(msg.metadata || %{}, ["agent_name"]) || "AI"
          IO.puts("#{agent_name}: #{msg.content}")
        end
      else
        IO.puts("\n✗ No response from Maya")
      end
    end
  end
end