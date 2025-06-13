users = AshChat.Resources.User.read!()

IO.puts("Current users in system:")
IO.puts("========================")

Enum.each(users, fn user ->
  IO.puts("ID: #{user.id}")
  IO.puts("Name: #{user.name}")
  IO.puts("Display Name: #{user.display_name}")
  IO.puts("Email: #{user.email}")
  IO.puts("Active: #{user.is_active}")
  IO.puts("------------------------")
end)

IO.puts("\nTotal users: #{length(users)}")