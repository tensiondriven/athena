# Trigger Maya in Coffee Chat
require Logger

# Find Coffee Chat room
coffee_chat = AshChat.Resources.Room.read!() |> Enum.find(&(&1.title == "Coffee Chat"))

if coffee_chat do
  IO.puts("Found Coffee Chat room: #{coffee_chat.id}")
  
  # Find Jonathan
  jonathan = AshChat.Resources.User.read!() |> Enum.find(&(&1.name == "Jonathan"))
  
  if jonathan do
    IO.puts("Found Jonathan: #{jonathan.id}")
    
    # Send a message
    IO.puts("\nSending message as Jonathan...")
    {:ok, msg} = AshChat.Resources.Message.create_text_message(%{
      room_id: coffee_chat.id,
      content: "Hey Maya! What's your favorite thing about coffee? I'm thinking of trying a new brewing method.",
      role: :user,
      user_id: jonathan.id
    })
    
    IO.puts("✓ Message sent!")
    IO.puts("Content: \"#{msg.content}\"")
    
    # Wait for Maya's response
    IO.puts("\nWaiting for Maya's response...")
    Process.sleep(5000)
    
    # Get messages after ours
    all_messages = AshChat.Resources.Message.for_room!(coffee_chat.id)
    our_msg_index = Enum.find_index(all_messages, &(&1.id == msg.id))
    
    if our_msg_index do
      new_messages = Enum.drop(all_messages, our_msg_index + 1)
      
      if length(new_messages) > 0 do
        IO.puts("\n✅ Maya responded!")
        for response <- new_messages do
          agent_name = get_in(response.metadata || %{}, ["agent_name"]) || "Assistant"
          IO.puts("\n#{agent_name}:")
          IO.puts(response.content)
        end
      else
        IO.puts("\n❌ No response from Maya yet")
        
        # Check Maya's membership status
        maya_card = AshChat.Resources.AgentCard.read!() |> Enum.find(&(&1.name == "Maya"))
        if maya_card do
          maya_membership = case AshChat.Resources.AgentMembership.for_room(%{room_id: coffee_chat.id}) do
            {:ok, memberships} -> Enum.find(memberships, &(&1.agent_card_id == maya_card.id))
            _ -> nil
          end
          
          if maya_membership do
            IO.puts("\nMaya membership status:")
            IO.puts("- Auto-respond: #{maya_membership.auto_respond}")
            IO.puts("- Active: #{maya_membership.is_active}")
          else
            IO.puts("\nMaya is not in the room!")
          end
        end
      end
    else
      IO.puts("\n❌ Could not find our message in the room")
    end
  else
    IO.puts("Could not find Jonathan")
  end
else
  IO.puts("Could not find Coffee Chat room")
end