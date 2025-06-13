#!/usr/bin/env elixir

IO.puts("Checking users...")
users = AshChat.Resources.User.read!()
for user <- users do
  IO.puts("- #{user.name} (ID: #{user.id})")
end

IO.puts("\nChecking rooms...")
rooms = AshChat.Resources.Room.read!()
for room <- rooms do
  IO.puts("- #{room.title} (ID: #{room.id})")
end

IO.puts("\nChecking agent cards...")
agents = AshChat.Resources.AgentCard.read!()
for agent <- agents do
  IO.puts("- #{agent.name}: #{agent.description}")
end