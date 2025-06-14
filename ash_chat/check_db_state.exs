#!/usr/bin/env elixir

# Check database state
{:ok, rooms} = AshChat.Resources.Room.read()
{:ok, users} = AshChat.Resources.User.read()
{:ok, agents} = AshChat.Resources.AgentCard.read()

IO.puts("Rooms: #{length(rooms)}")
for room <- rooms do
  IO.puts("  - #{room.title} (#{room.id})")
end

IO.puts("\nUsers: #{length(users)}")
for user <- users do
  IO.puts("  - #{user.display_name} (#{user.id})")
end

IO.puts("\nAgents: #{length(agents)}")
for agent <- agents do
  IO.puts("  - #{agent.name} (#{agent.id})")
end

# Check if we have any messages
{:ok, messages} = AshChat.Resources.Message.read()
IO.puts("\nTotal messages: #{length(messages)}")