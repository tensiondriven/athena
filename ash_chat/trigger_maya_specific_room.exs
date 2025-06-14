# Trigger Maya in the specific room
require Logger

room_id = "61af25ab-1575-4442-9f11-85f25e220c8e"

# Get the room
{:ok, room} = Ash.get(AshChat.Resources.Room, room_id)
IO.puts("Working with room: #{room.title}")

# Find Maya
maya = AshChat.Resources.AgentCard.read!() |> Enum.find(&(&1.name == "Maya"))

if maya do
  IO.puts("Found Maya agent: #{maya.id}")
  
  # Get Jonathan user
  jonathan = AshChat.Resources.User.read!() |> Enum.find(&(&1.name == "Jonathan"))
  
  if jonathan do
    # Send a message as Jonathan
    {:ok, user_msg} = AshChat.Resources.Message.create_text_message(%{
      room_id: room.id,
      content: "Hey Maya! What's your take on the perfect cup of coffee? I'm always looking for new brewing techniques.",
      role: :user,
      user_id: jonathan.id
    })
    
    IO.puts("\nSent message as Jonathan:")
    IO.puts("\"#{user_msg.content}\"")
    IO.puts("Message ID: #{user_msg.id}")
    
    # The message event processor should automatically trigger Maya's response
    IO.puts("\nWaiting for Maya's response...")
    Process.sleep(5000)
    
    # Check for new messages after ours
    all_messages = AshChat.Resources.Message.for_room!(room.id)
    our_msg_index = Enum.find_index(all_messages, &(&1.id == user_msg.id))
    
    if our_msg_index do
      new_messages = Enum.drop(all_messages, our_msg_index + 1)
      
      if length(new_messages) > 0 do
        IO.puts("\n✓ Got responses:")
        for msg <- new_messages do
          agent_name = get_in(msg.metadata || %{}, ["agent_name"]) || 
                      (if msg.role == :assistant, do: "Assistant", else: "Unknown")
          IO.puts("\n#{agent_name}: #{msg.content}")
        end
      else
        IO.puts("\n✗ No response yet. Checking Maya's status...")
        
        # Check Maya's membership
        maya_membership = AshChat.Resources.AgentMembership.for_room(%{room_id: room.id})
        |> case do
          {:ok, memberships} -> 
            membership = Enum.find(memberships, &(&1.agent_card_id == maya.id))
            IO.puts("Found #{length(memberships)} agent memberships in room")
            membership
          error -> 
            IO.puts("Error getting memberships: #{inspect(error)}")
            nil
        end
        
        if maya_membership do
          IO.puts("\nMaya membership details:")
          IO.puts("- Agent Card ID: #{maya_membership.agent_card_id}")
          IO.puts("- Role: #{maya_membership.role}")
          IO.puts("- Auto-respond: #{maya_membership.auto_respond}")
          IO.puts("- Active: #{maya_membership.is_active}")
          
          if !maya_membership.auto_respond do
            IO.puts("\n⚠️  Maya's auto-respond is disabled. Enabling it...")
            {:ok, updated} = AshChat.Resources.AgentMembership.update(maya_membership, %{auto_respond: true})
            IO.puts("✓ Updated Maya's auto-respond to: #{updated.auto_respond}")
            
            # Try sending another message
            IO.puts("\nSending another test message...")
            {:ok, test_msg} = AshChat.Resources.Message.create_text_message(%{
              room_id: room.id,
              content: "Maya, are you there? I'd love to hear your thoughts!",
              role: :user,
              user_id: jonathan.id
            })
            
            Process.sleep(5000)
            
            final_messages = AshChat.Resources.Message.for_room!(room.id)
            test_msg_index = Enum.find_index(final_messages, &(&1.id == test_msg.id))
            
            if test_msg_index do
              responses = Enum.drop(final_messages, test_msg_index + 1)
              if length(responses) > 0 do
                IO.puts("\n✓ Maya responded after enabling auto-respond:")
                for msg <- responses do
                  agent_name = get_in(msg.metadata || %{}, ["agent_name"]) || "AI"
                  IO.puts("#{agent_name}: #{msg.content}")
                end
              else
                IO.puts("\n✗ Still no response from Maya")
              end
            end
          end
        else
          IO.puts("\n⚠️  Maya is not in this room! Adding her...")
          
          {:ok, membership} = AshChat.Resources.AgentMembership.create(%{
            room_id: room.id,
            agent_card_id: maya.id,
            role: "participant",
            auto_respond: true
          })
          
          IO.puts("✓ Added Maya to the room with auto-respond enabled")
          
          # Send another message
          {:ok, welcome_msg} = AshChat.Resources.Message.create_text_message(%{
            room_id: room.id,
            content: "Welcome to the chat, Maya! What's your favorite topic to discuss?",
            role: :user,
            user_id: jonathan.id
          })
          
          IO.puts("\nSent welcome message...")
          Process.sleep(5000)
          
          final_messages = AshChat.Resources.Message.for_room!(room.id)
          welcome_index = Enum.find_index(final_messages, &(&1.id == welcome_msg.id))
          
          if welcome_index do
            responses = Enum.drop(final_messages, welcome_index + 1)
            if length(responses) > 0 do
              IO.puts("\n✓ Maya responded:")
              for msg <- responses do
                agent_name = get_in(msg.metadata || %{}, ["agent_name"]) || "AI"
                IO.puts("#{agent_name}: #{msg.content}")
              end
            end
          end
        end
      end
    end
  else
    IO.puts("Could not find Jonathan user")
  end
else
  IO.puts("Could not find Maya agent")
end