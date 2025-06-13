# Debug script to check participant structure
rooms = AshChat.Resources.Room.read!()
IO.puts("Found #{length(rooms)} rooms")

room = List.first(rooms)

if room do
  IO.puts("Checking room: #{room.title}")
  
  # Recreate the load_all_participants logic
  human_members = case AshChat.Resources.RoomMembership.for_room(%{room_id: room.id}) do
    {:ok, memberships} -> 
      Enum.map(memberships, fn membership ->
        case Ash.get(AshChat.Resources.User, membership.user_id) do
          {:ok, user} -> 
            %{
              id: user.id,
              name: user.display_name || user.name,
              type: :human,
              in_room: true,
              membership_id: membership.id
            }
          _ -> nil
        end
      end) |> Enum.filter(&(&1))
    _ -> []
  end
  
  ai_members = case AshChat.Resources.AgentMembership.for_room(%{room_id: room.id}) do
    {:ok, memberships} ->
      Enum.map(memberships, fn membership ->
        case Ash.get(AshChat.Resources.AgentCard, membership.agent_card_id) do
          {:ok, agent} ->
            %{
              id: agent.id,
              name: agent.name,
              type: :ai,
              in_room: true,
              membership_id: membership.id
            }
          _ -> nil
        end
      end) |> Enum.filter(&(&1))
    _ -> []
  end
  
  participants = human_members ++ ai_members
  
  IO.puts("\nRoom participants (#{length(participants)} total):")
  Enum.each(participants, fn p ->
    IO.puts("  - #{p.name} (#{p.type}) ID: #{p.id}")
  end)
  
  # Check for duplicates
  ids = Enum.map(participants, & &1.id)
  unique_ids = Enum.uniq(ids)
  
  if length(ids) != length(unique_ids) do
    IO.puts("\n⚠️  DUPLICATES FOUND!")
    duplicates = ids -- unique_ids
    IO.puts("Duplicate IDs: #{inspect(duplicates)}")
  else
    IO.puts("\n✓ No duplicates in participants")
  end
end