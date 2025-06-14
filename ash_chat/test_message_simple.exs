# Simple message test to debug agent responses
# Run in IEx: c("test_message_simple.exs")

alias AshChat.Resources.{Room, User, Message}

# Get first room and user
{:ok, [room | _]} = Room.read()
{:ok, [user | _]} = User.read()

IO.puts("Testing in room: #{room.title}")
IO.puts("As user: #{user.display_name}")

# Create a simple message
{:ok, msg} = Message.create_text_message(%{
  room_id: room.id,
  content: "Hello! Is anyone there?",
  role: :user,
  user_id: user.id
})

IO.puts("Created message: #{msg.id}")
IO.puts("Content: #{msg.content}")

# Check what happens next
Process.sleep(2000)

# Check for responses
{:ok, messages} = Message.for_room(%{room_id: room.id})
IO.puts("\nMessages in room: #{length(messages)}")

for m <- messages do
  author = if m.role == :user, do: "User", else: "Agent"
  IO.puts("  #{author}: #{String.slice(m.content, 0, 50)}..."
end