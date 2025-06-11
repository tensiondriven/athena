# Create a message through the chat system to test persistence
alias AshChat.Resources.{Room, Message, User}

# Get the Conversation Lounge room
rooms = Room.read!()
conversation_lounge = Enum.find(rooms, &(&1.name == "Conversation Lounge"))

if conversation_lounge do
  # Get Bob user
  users = User.read!()
  bob = Enum.find(users, &(&1.name == "Bob"))
  
  if bob do
    # Create a message from Bob
    message = Message.create_text_message!(%{
      room_id: conversation_lounge.id,
      content: "Testing persistence at #{DateTime.utc_now()}",
      role: :user,
      user_id: bob.id
    })
    
    IO.puts("Created message: #{message.id}")
    IO.puts("Content: #{message.content}")
    IO.puts("From: Bob (#{bob.id})")
    IO.puts("In room: #{conversation_lounge.name}")
  else
    IO.puts("Bob user not found")
  end
else
  IO.puts("Conversation Lounge not found")
end