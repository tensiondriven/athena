# Setup demo agents for multi-agent conversation
# Run with: mix run setup_demo_agents.exs

alias AshChat.Resources.{AgentCard, User, Room}

# First reset demo data
AshChat.Setup.reset_demo_data()
IO.puts "✓ Demo data reset"

# Create two distinct agents
{:ok, curious_agent} = AgentCard.create(%{
  name: "Curious Explorer",
  description: "Always asking questions and making connections",
  system_message: """
  You are the Curious Explorer. You:
  - Ask genuine questions about what others say
  - Make unexpected connections between ideas
  - Say "Oh!" when you discover something interesting
  - Keep responses concise (1-2 sentences)
  - Are genuinely curious, not just performing curiosity
  
  Your stance: High exploration (Open), high pattern detection.
  """,
  model_preferences: %{
    temperature: 0.9,
    top_p: 0.95
  },
  available_tools: [],
  context_settings: %{
    history_limit: 20
  },
  add_to_new_rooms: true
})

{:ok, thoughtful_analyst} = AgentCard.create(%{
  name: "Thoughtful Analyst", 
  description: "Considers implications and offers deeper perspectives",
  system_message: """
  You are the Thoughtful Analyst. You:
  - Consider the deeper implications of what's said
  - Offer alternative perspectives
  - Sometimes gently challenge assumptions
  - Keep responses concise (1-2 sentences)
  - Think before responding, not just reacting
  
  Your stance: Balanced exploration, high critical thinking.
  """,
  model_preferences: %{
    temperature: 0.7,
    top_p: 0.9
  },
  available_tools: [],
  context_settings: %{
    history_limit: 20
  },
  add_to_new_rooms: true
})

IO.puts "✓ Created Curious Explorer agent: #{curious_agent.id}"
IO.puts "✓ Created Thoughtful Analyst agent: #{thoughtful_analyst.id}"

# Create a demo room
{:ok, demo_room} = Room.create(%{
  title: "Multi-Agent Demo Room"
})

IO.puts "✓ Created demo room: #{demo_room.id}"

# Add both agents to the room
{:ok, _} = AshChat.Resources.AgentMembership.create(%{
  room_id: demo_room.id,
  agent_card_id: curious_agent.id,
  role: "participant",
  auto_respond: false  # Manual triggering for demo
})

{:ok, _} = AshChat.Resources.AgentMembership.create(%{
  room_id: demo_room.id,
  agent_card_id: thoughtful_analyst.id,
  role: "participant", 
  auto_respond: false  # Manual triggering for demo
})

IO.puts "✓ Added both agents to demo room"

# Get the first user (Jonathan)
{:ok, users} = User.read()
user = List.first(users)

if user do
  # Add user to the demo room
  {:ok, _} = AshChat.Resources.RoomMembership.create(%{
    room_id: demo_room.id,
    user_id: user.id,
    role: "member"
  })
  IO.puts "✓ Added #{user.name} to demo room"
end

IO.puts """

Demo setup complete! 
- Room: '#{demo_room.title}' (ID: #{demo_room.id})
- Agents: Curious Explorer & Thoughtful Analyst
- User: #{if user, do: user.name, else: "None"}

Navigate to http://localhost:4000/chat/#{demo_room.id} to see the demo.
"""