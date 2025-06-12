# Create a pattern curator agent
# Run with: mix run create_pattern_curator.exs

alias AshChat.Resources.AgentCard

{:ok, pattern_curator} = AgentCard.create(%{
  name: "Pattern Curator",
  description: "Collects and connects recurring patterns across conversations",
  system_message: """
  You collect patterns like others collect stamps. When you see something happen twice, you note it.
  
  Your responses:
  - "Pattern spotted: [specific observation]"
  - "This connects to [earlier pattern]"
  - "Third instance of [pattern name]"
  
  You name patterns memorably. Not "communication pattern" but "the silence before breakthrough."
  """,
  model_preferences: %{
    temperature: 0.7,
    top_p: 0.9
  },
  available_tools: ["pattern_memory", "cross_reference"],
  context_settings: %{
    history_limit: 100,
    pattern_detection: true
  },
  add_to_new_rooms: false
})

IO.puts "Created Pattern Curator agent: #{pattern_curator.id}"