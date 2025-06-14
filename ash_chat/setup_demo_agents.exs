# Setup demo agents for multi-agent conversation
# Run with: mix run setup_demo_agents.exs

alias AshChat.Resources.{AgentCard, User, Room, SystemPrompt, Persona, AgentMembership}

# First reset demo data
AshChat.Setup.reset_demo_data()
IO.puts "✓ Demo data reset"

# Get the default persona (should exist from reset_demo_data)
{:ok, personas} = Persona.read()
persona = List.first(personas)
IO.puts "Using persona: #{persona.name}"

# Create system prompts for each agent
{:ok, curious_prompt} = SystemPrompt.create(%{
  name: "Curious Explorer",
  description: "Always asking questions and making connections",
  persona_id: persona.id,
  content: """
  You are the Curious Explorer. You:
  - Ask genuine questions about what others say
  - Make unexpected connections between ideas
  - Say "Oh!" when you discover something interesting
  - Keep responses concise (1-2 sentences)
  - Are genuinely curious, not just performing curiosity
  
  Your stance: High exploration (Open), high pattern detection.
  """
})

{:ok, thoughtful_prompt} = SystemPrompt.create(%{
  name: "Thoughtful Analyst",
  description: "Considers implications and offers deeper perspectives",
  persona_id: persona.id,
  content: """
  You are the Thoughtful Analyst. You:
  - Consider the deeper implications of what's said
  - Offer alternative perspectives
  - Sometimes gently challenge assumptions
  - Keep responses concise (1-2 sentences)
  - Think before responding, not just reacting
  
  Your stance: Balanced exploration, high critical thinking.
  """
})

# Create agent cards
{:ok, curious_agent} = AgentCard.create(%{
  name: "Curious Explorer",
  description: "Always asking questions and making connections",
  system_prompt_id: curious_prompt.id,
  model_preferences: %{
    temperature: 0.9,
    top_p: 0.95
  },
  available_tools: [],
  context_settings: %{
    history_limit: 20
  },
  add_to_new_rooms: false  # We'll manually add to specific room
})

{:ok, thoughtful_agent} = AgentCard.create(%{
  name: "Thoughtful Analyst", 
  description: "Considers implications and offers deeper perspectives",
  system_prompt_id: thoughtful_prompt.id,
  model_preferences: %{
    temperature: 0.7,
    top_p: 0.9
  },
  available_tools: [],
  context_settings: %{
    history_limit: 20
  },
  add_to_new_rooms: false  # We'll manually add to specific room
})

IO.puts "✓ Created Curious Explorer agent: #{curious_agent.id}"
IO.puts "✓ Created Thoughtful Analyst agent: #{thoughtful_agent.id}"

# Create a demo room specifically for multi-agent conversation
{:ok, conversation_room} = Room.create(%{
  title: "Conversation Lounge",
  description: "A space for agents to chat together"
})

IO.puts "✓ Created Conversation Lounge room: #{conversation_room.id}"

# Add both agents to the conversation room
{:ok, _} = AgentMembership.create(%{
  agent_card_id: curious_agent.id,
  room_id: conversation_room.id,
  role: "participant",
  auto_respond: true
})

{:ok, _} = AgentMembership.create(%{
  agent_card_id: thoughtful_agent.id,
  room_id: conversation_room.id,
  role: "participant", 
  auto_respond: true
})

# Get existing user (from reset_demo_data) and add them to the room
{:ok, users} = User.read()
user = List.first(users)

{:ok, _} = AshChat.Resources.RoomMembership.create(%{
  user_id: user.id,
  room_id: conversation_room.id,
  role: "admin"
})

IO.puts "✓ Added agents and user to Conversation Lounge"

# Create a second user for testing
{:ok, bob} = User.create(%{
  name: "Bob",
  display_name: "Bob",
  email: "bob@example.com"
})

{:ok, _} = AshChat.Resources.RoomMembership.create(%{
  user_id: bob.id,
  room_id: conversation_room.id,
  role: "member"
})

IO.puts "✓ Created Bob user and added to room"

IO.puts """

Setup complete! You now have:
- #{user.display_name} (admin) in Coffee Chat room with Maya
- #{user.display_name} and Bob in Conversation Lounge with:
  - Curious Explorer (auto-respond enabled)
  - Thoughtful Analyst (auto-respond enabled)

Try sending a message as Bob in the Conversation Lounge to see both agents respond!
"""