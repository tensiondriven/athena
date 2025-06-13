IO.puts("Checking data...")

IO.puts("\nRooms:")
AshChat.Resources.Room.read!()
|> Enum.each(fn r -> 
  IO.puts("  - #{r.title} (ID: #{r.id})")
end)

IO.puts("\nUsers:")
AshChat.Resources.User.read!()
|> Enum.each(fn u -> 
  IO.puts("  - #{u.name}")
end)

IO.puts("\nAgent Cards:")
AshChat.Resources.AgentCard.read!()
|> Enum.each(fn a -> 
  IO.puts("  - #{a.name}")
end)