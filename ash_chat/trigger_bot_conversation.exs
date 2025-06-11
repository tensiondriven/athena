# Script to trigger bot conversation
room = AshChat.Resources.Room.read!() |> Enum.find(&(&1.title == "Conversation Lounge"))
alice = AshChat.Resources.User.read!() |> Enum.find(&(&1.name == "Alice"))

if room && alice do
  msg = AshChat.Resources.Message.create_text_message!(%{
    room_id: room.id,
    content: "Hey Sam and Maya! I'm curious - what are your favorite things to do on a weekend?",
    role: :user,
    user_id: alice.id
  })
  
  IO.puts("Message sent! ID: #{msg.id}")
  IO.puts("Waiting for bot responses...")
  
  # Give time for agents to respond
  Process.sleep(5000)
  
  # Check for new messages
  messages = AshChat.Resources.Message.for_room!(room.id)
  IO.puts("\nMessages in room:")
  for msg <- messages do
    user_name = if msg.user_id do
      user = AshChat.Resources.User.read!() |> Enum.find(&(&1.id == msg.user_id))
      user && user.name || "Unknown"
    else
      "AI"
    end
    IO.puts("#{user_name}: #{msg.content}")
  end
else
  IO.puts("Could not find room or Alice!")
end