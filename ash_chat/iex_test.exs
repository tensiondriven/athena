# Paste this into IEx after starting with: iex -S mix phx.server

alias AshChat.Resources.{Room, User, Message, AgentMembership}

# Check what we have
{:ok, rooms} = Room.read()
{:ok, users} = User.read()

IO.puts("\nRooms: #{length(rooms)}")
for room <- rooms do
  {:ok, agents} = AgentMembership.for_room(%{room_id: room.id})
  auto_responders = Enum.filter(agents, & &1.auto_respond)
  IO.puts("  #{room.title}: #{length(agents)} agents (#{length(auto_responders)} auto-respond)")
end

IO.puts("\nUsers: #{length(users)}")
for user <- users do
  IO.puts("  #{user.display_name}")
end

# Send a test message if we have data
if room = List.first(rooms) do
  if user = List.first(users) do
    IO.puts("\n=== Sending test message ===")
    {:ok, msg} = Message.create_text_message(%{
      room_id: room.id,
      content: "Hello! Testing at #{DateTime.utc_now()}",
      role: :user,
      user_id: user.id
    })
    
    IO.puts("Created message: #{msg.id}")
    
    # Wait a bit
    Process.sleep(3000)
    
    # Check messages
    {:ok, messages} = Message.for_room(%{room_id: room.id})
    
    IO.puts("\nMessages in room (last 5):")
    messages
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    |> Enum.take(5)
    |> Enum.reverse()
    |> Enum.each(fn m ->
      role = if m.role == :user, do: "User", else: "Agent"
      IO.puts("  [#{role}] #{String.slice(m.content, 0, 60)}...")
    end)
  end
end

# Check if MessageEventProcessor is running
case Process.whereis(AshChat.AI.MessageEventProcessor) do
  nil -> IO.puts("\n⚠️  MessageEventProcessor is NOT running")
  pid -> IO.puts("\n✓ MessageEventProcessor is running: #{inspect(pid)}")
end

# Check if any room workers are running
room_workers = Process.registered() 
|> Enum.filter(&String.starts_with?(Atom.to_string(&1), "room_worker_"))

IO.puts("\nRoom workers: #{length(room_workers)}")
for worker <- room_workers do
  IO.puts("  #{worker}")
end