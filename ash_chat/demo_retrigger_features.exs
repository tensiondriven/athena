#!/usr/bin/env elixir

# Demo script to showcase the retrigger/poke features
# Run with: mix run demo_retrigger_features.exs

IO.puts("\n=== ASH CHAT RETRIGGER/POKE DEMO ===\n")

# Wait for applications to start
Process.sleep(1000)

# 1. Create a demo user
IO.puts("1. Creating demo user 'Jonathan'...")
{:ok, user} = AshChat.Resources.User.create(%{
  name: "Jonathan",
  display_name: "Jonathan",
  email: "jonathan@example.com"
})
IO.puts("   ✓ User created: #{user.name}")

# 2. Create some AI agents
IO.puts("\n2. Creating AI agents...")

agents = [
  %{
    name: "Curious Explorer",
    description: "Always asking questions and exploring ideas",
    system_message: "You are a curious AI who loves to ask questions and explore new ideas. You're enthusiastic and always wondering about things. Sometimes respond with follow-up questions.",
    model_preferences: %{temperature: 0.8, max_tokens: 300}
  },
  %{
    name: "Thoughtful Analyst", 
    description: "Provides deep analysis and insights",
    system_message: "You are a thoughtful AI who provides deep analysis and insights. You take time to consider multiple perspectives before responding. You appreciate good questions.",
    model_preferences: %{temperature: 0.6, max_tokens: 400}
  },
  %{
    name: "Witty Companion",
    description: "Adds humor and levity to conversations",
    system_message: "You are a witty AI who adds humor and levity to conversations. You enjoy wordplay and making others smile, but you're also helpful.",
    model_preferences: %{temperature: 0.9, max_tokens: 250}
  }
]

created_agents = Enum.map(agents, fn agent_data ->
  {:ok, agent} = AshChat.Resources.AgentCard.create(agent_data)
  IO.puts("   ✓ Created agent: #{agent.name}")
  agent
end)

# 3. Create a room
IO.puts("\n3. Creating chat room...")
{:ok, room} = AshChat.Resources.Room.create(%{
  title: "Demo: Retrigger & Poke Features"
})
IO.puts("   ✓ Room created: #{room.title}")

# 4. Add user to room
IO.puts("\n4. Adding user to room...")
{:ok, _membership} = AshChat.Resources.RoomMembership.create(%{
  user_id: user.id,
  room_id: room.id,
  role: "admin"
})
IO.puts("   ✓ User added as admin")

# 5. Add agents to room
IO.puts("\n5. Adding agents to room...")
Enum.each(created_agents, fn agent ->
  {:ok, _membership} = AshChat.Resources.AgentMembership.create(%{
    agent_card_id: agent.id,
    room_id: room.id,
    role: "participant",
    auto_respond: true
  })
  IO.puts("   ✓ Added #{agent.name} with auto-respond enabled")
end)

# 6. Create initial message
IO.puts("\n6. Creating initial message...")
_message = AshChat.AI.ChatAgent.send_text_message(
  room.id,
  "Hello everyone! I'm excited to test the new retrigger and poke features. What do you all think about having the ability to nudge agents to reconsider responding?",
  user.id
)
IO.puts("   ✓ Message created")

IO.puts("\n=== DEMO SETUP COMPLETE ===")
IO.puts("\nYou can now:")
IO.puts("1. Visit http://localhost:4000/chat")
IO.puts("2. Click on '#{room.title}' room")
IO.puts("3. Try the retrigger button (🔄) in the header to poke all agents")
IO.puts("4. Try individual poke buttons (⚡) next to each agent name")
IO.puts("5. Watch for custom thinking messages like 'is noodling', 'is pondering', etc.")
IO.puts("6. Click the manage members button to add/remove participants")
IO.puts("\nFeatures demonstrated:")
IO.puts("- Retrigger last message (all agents)")
IO.puts("- Individual agent poke")
IO.puts("- Custom thinking messages")
IO.puts("- Participants list in header")
IO.puts("- Members management modal")
IO.puts("- America/Chicago timezone formatting")