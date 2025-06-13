#!/usr/bin/env elixir

# Clean seed script - minimal data for a fresh start
IO.puts("🧹 Cleaning all data and creating minimal seed...")

# First, let's clear everything
alias AshChat.Resources.{User, Room, AgentCard, Profile, SystemPrompt, Message, RoomMembership, AgentMembership}

# Clear all existing data
User.read!() |> Enum.each(&User.destroy!/1)
Room.read!() |> Enum.each(&Room.destroy!/1)
AgentCard.read!() |> Enum.each(&AgentCard.destroy!/1)
Profile.read!() |> Enum.each(&Profile.destroy!/1)
SystemPrompt.read!() |> Enum.each(&SystemPrompt.destroy!/1)
Message.read!() |> Enum.each(&Message.destroy!/1)
RoomMembership.read!() |> Enum.each(&RoomMembership.destroy!/1)
AgentMembership.read!() |> Enum.each(&AgentMembership.destroy!/1)

IO.puts("✅ Cleared all existing data")

# Create minimal clean data
# 1. One user (Jonathan)
jonathan = User.create!(%{
  name: "Jonathan",
  email: "jonathan@athena.local",
  display_name: "Jonathan",
  avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=Jonathan",
  preferences: %{
    "theme" => "system",
    "notification_level" => "all"
  }
})

# 2. One profile (auto-detect OpenRouter vs Ollama)
use_openrouter = Application.get_env(:ash_chat, :use_openrouter, false)
openrouter_key = Application.get_env(:langchain, :openrouter_key)

profile = if use_openrouter && openrouter_key do
  Profile.create!(%{
    name: "OpenRouter (Cloud)",
    provider: "openrouter",
    url: "https://openrouter.ai/api/v1",
    api_key: openrouter_key,
    model: "qwen/qwen-2.5-72b-instruct",
    is_default: true
  })
else
  Profile.create!(%{
    name: "Local Ollama",
    provider: "ollama", 
    url: System.get_env("OLLAMA_URL", "http://10.1.2.200:11434"),
    model: "qwen2.5:latest",
    is_default: true
  })
end

# 3. One system prompt
system_prompt = SystemPrompt.create!(%{
  name: "Helpful Assistant",
  content: "You are a helpful, friendly assistant. Always respond with enthusiasm and try to be as helpful as possible. Keep responses concise but informative.",
  description: "A friendly and helpful AI assistant for general conversations",
  profile_id: profile.id,
  is_active: true
})

# 4. One agent card using the system prompt
agent_card = AgentCard.create!(%{
  name: "Helpful Assistant",
  description: "A friendly and helpful AI assistant",
  system_prompt_id: system_prompt.id,
  model_preferences: %{
    temperature: 0.7,
    max_tokens: 500
  },
  available_tools: [],
  context_settings: %{
    history_limit: 20,
    include_room_metadata: true
  },
  is_default: true,
  add_to_new_rooms: true
})

# 5. One room
room = Room.create!(%{
  title: "General Chat"
})

# 6. Add Jonathan to the room
RoomMembership.create!(%{
  user_id: jonathan.id,
  room_id: room.id,
  role: "admin"
})

# 7. Add the agent to the room
AgentMembership.create!(%{
  agent_card_id: agent_card.id,
  room_id: room.id,
  role: "participant",
  auto_respond: true
})

backend_info = if profile.provider == "openrouter" do
  "OpenRouter (Cloud)"
else
  "Local Ollama"
end

IO.puts("""

✅ Clean seed data created!

👤 User: Jonathan
🔧 Profile: #{profile.name} (#{profile.provider})
📝 System Prompt: #{system_prompt.name}
🤖 Agent: #{agent_card.name}
🏠 Room: #{room.title}

Ready to use! Visit /chat to start chatting.
""")