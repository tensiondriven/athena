# Run this in IEx after starting with: iex -S mix phx.server

# Create additional agents for multi-agent conversation
alias AshChat.Resources.{AgentCard, User, Room, SystemPrompt, Persona, AgentMembership}

# Get the default persona
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
  add_to_new_rooms: false
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
  add_to_new_rooms: false
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

# Get existing users and add them to the room
{:ok, users} = User.read()
for user <- users do
  {:ok, _} = AshChat.Resources.RoomMembership.create(%{
    user_id: user.id,
    room_id: conversation_room.id,
    role: "member"
  })
end

IO.puts "✓ Added agents and #{length(users)} users to Conversation Lounge"

# Create Bob if he doesn't exist
unless Enum.find(users, &(&1.name == "Bob")) do
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
end

IO.puts """

Setup complete! You now have:
- Multiple rooms with agents
- Conversation Lounge with:
  - Curious Explorer (auto-respond enabled)
  - Thoughtful Analyst (auto-respond enabled)

Try sending a message in the Conversation Lounge!
"""