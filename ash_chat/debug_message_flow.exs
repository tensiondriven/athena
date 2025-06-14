# Debug script to trace message flow
# Run in IEx after server is started

alias AshChat.Resources.{Room, User, Message}

# First, let's check what we have
{:ok, rooms} = Room.read()
{:ok, users} = User.read()
{:ok, agents} = AshChat.Resources.AgentCard.read()

IO.puts("\n=== Current State ===")
IO.puts("Rooms: #{length(rooms)}")
for room <- rooms do
  {:ok, memberships} = AshChat.Resources.AgentMembership.for_room(%{room_id: room.id})
  IO.puts("  - #{room.title}: #{length(memberships)} agents")
end

IO.puts("\nUsers: #{length(users)}")
for user <- users do
  IO.puts("  - #{user.display_name}")
end

IO.puts("\nAgents: #{length(agents)}")
for agent <- agents do
  IO.puts("  - #{agent.name}")
end

# Now let's trace a message
if room = List.first(rooms) do
  if user = List.first(users) do
    IO.puts("\n=== Creating Test Message ===")
    IO.puts("Room: #{room.title}")
    IO.puts("User: #{user.display_name}")
    
    # Enable some debug logging
    Logger.configure(level: :debug)
    
    # Create the message
    {:ok, msg} = Message.create_text_message(%{
      room_id: room.id,
      content: "Test message at #{DateTime.utc_now()}",
      role: :user,
      user_id: user.id
    })
    
    IO.puts("Created message: #{msg.id}")
    
    # Give it time to process
    Process.sleep(3000)
    
    # Check results
    {:ok, messages} = Message.for_room(%{room_id: room.id})
    IO.puts("\n=== Messages After Processing ===")
    IO.puts("Total: #{length(messages)}")
    
    # Show recent messages
    messages
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    |> Enum.take(5)
    |> Enum.reverse()
    |> Enum.each(fn m ->
      author = if m.role == :user, do: "User", else: "Agent"
      time = Calendar.strftime(m.created_at, "%H:%M:%S")
      IO.puts("[#{time}] #{author}: #{String.slice(m.content, 0, 60)}...")
    end)
  end
end