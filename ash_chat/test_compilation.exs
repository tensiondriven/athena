IO.puts("Testing compilation and basic functionality...")

# Seed data
AshChat.DemoData.clear_all()
AshChat.DemoData.seed_jonathan_setup()

# Check if resources work
rooms = AshChat.Resources.Room.read!()
users = AshChat.Resources.User.read!()
characters = AshChat.Resources.Character.read!()

IO.puts("✅ Room count: #{length(rooms)}")
IO.puts("✅ User count: #{length(users)}")
IO.puts("✅ Character count: #{length(characters)}")

IO.puts("✅ All resources working correctly!")
IO.puts("✅ No FunctionClauseError during setup!")