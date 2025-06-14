# Check Maya's auto-respond status
require Logger

IO.puts("Checking Maya's auto-respond status...")

# Get all rooms
rooms = AshChat.Resources.Room.read!()
IO.puts("\nFound #{length(rooms)} rooms:")

for room <- rooms do
  IO.puts("\n=== Room: #{room.title} (#{room.id}) ===")
  
  # Get agent memberships
  case AshChat.Resources.AgentMembership.for_room(%{room_id: room.id}) do
    {:ok, memberships} ->
      for membership <- memberships do
        case Ash.get(AshChat.Resources.AgentCard, membership.agent_card_id) do
          {:ok, agent} ->
            IO.puts("  Agent: #{agent.name}")
            IO.puts("    - Auto-respond: #{membership.auto_respond}")
            IO.puts("    - Is active: #{membership.is_active}")
            IO.puts("    - Role: #{membership.role}")
          _ ->
            IO.puts("  Unknown agent (ID: #{membership.agent_card_id})")
        end
      end
    _ ->
      IO.puts("  No agent memberships")
  end
end

# Check auto-responders function
IO.puts("\n\n=== Testing auto_responders_for_room function ===")
if room = List.first(rooms) do
  case AshChat.Resources.AgentMembership.auto_responders_for_room(%{room_id: room.id}) do
    {:ok, responders} ->
      IO.puts("Auto-responders in #{room.title}: #{length(responders)}")
      for r <- responders do
        case Ash.get(AshChat.Resources.AgentCard, r.agent_card_id) do
          {:ok, agent} -> IO.puts("  - #{agent.name}")
          _ -> IO.puts("  - Unknown agent")
        end
      end
    {:error, error} ->
      IO.puts("Error getting auto-responders: #{inspect(error)}")
  end
end