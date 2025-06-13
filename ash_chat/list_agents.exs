agents = AshChat.Resources.AgentCard.read!()

IO.puts("Current agents in system:")
IO.puts("========================")

Enum.each(agents, fn agent ->
  IO.puts("ID: #{agent.id}")
  IO.puts("Name: #{agent.name}")
  IO.puts("Description: #{agent.description}")
  IO.puts("------------------------")
end)

IO.puts("\nTotal agents: #{length(agents)}")