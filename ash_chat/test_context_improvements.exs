# Test context assembler improvements
# Run with: mix run test_context_improvements.exs

alias AshChat.AI.{ContextAssembler, ContextAssemblerImprovements, EventGenerator}
alias AshChat.Resources.{AgentCard, Event}

# Create test agent
{:ok, test_agent} = AgentCard.create(%{
  name: "Test Observer",
  description: "Agent for testing context improvements",
  system_message: "You are a test agent.",
  add_to_new_rooms: false
})

IO.puts "Created test agent: #{test_agent.name}"

# Generate some events from this agent
{:ok, _} = EventGenerator.discovery_moment(
  test_agent.name,
  "Test discovery: Context can include events!",
  %{test: true}
)

{:ok, _} = EventGenerator.pattern_detected(
  test_agent.name,
  "test-repeat-pattern",
  3,
  %{test: true}
)

IO.puts "Generated test events"

# Build context with improvements
assembler = ContextAssembler.new(%{test: true})
|> ContextAssembler.add_component(:system_message, test_agent.system_message, priority: 10)
|> ContextAssemblerImprovements.add_relevant_events(test_agent)
|> ContextAssemblerImprovements.add_agent_patterns(test_agent)

IO.puts "\nContext components:"
ContextAssembler.inspect_components(assembler)
|> Enum.each(fn component ->
  IO.puts "  #{component.order}. #{component.type} (priority: #{component.priority})"
  IO.puts "     Preview: #{component.content_preview}"
  IO.puts "     Metadata: #{inspect(component.metadata)}"
end)

IO.puts "\nSuccess! Context assembler can now include:"
IO.puts "- Recent relevant events"
IO.puts "- Discovered patterns"
IO.puts "- Multi-agent awareness"