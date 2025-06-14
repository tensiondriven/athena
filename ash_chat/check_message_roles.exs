# Check what roles messages have
alias AshChat.Resources.{Message, Room}

{:ok, rooms} = Room.read()

for room <- rooms do
  {:ok, messages} = Message.for_room(%{room_id: room.id})
  
  if length(messages) > 0 do
    IO.puts("\nRoom: #{room.title}")
    IO.puts("Messages: #{length(messages)}")
    
    # Group by role
    by_role = Enum.group_by(messages, & &1.role)
    
    for {role, msgs} <- by_role do
      IO.puts("  #{role}: #{length(msgs)} messages")
    end
    
    # Show last few
    IO.puts("\nLast 3 messages:")
    messages
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    |> Enum.take(3)
    |> Enum.reverse()
    |> Enum.each(fn m ->
      metadata = inspect(m.metadata || %{})
      IO.puts("  [#{m.role}] #{String.slice(m.content, 0, 50)}... (metadata: #{metadata})")
    end)
  end
end