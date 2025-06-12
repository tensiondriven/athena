# Generate test events to see them in the dashboard
# Run with: mix run generate_test_events.exs

alias AshChat.Resources.Event

event_types = [
  {"conversation_start", "New conversation initiated"},
  {"agent_response", "Agent generated response"},
  {"pattern_detected", "Recurring pattern identified"},
  {"stance_shift", "Agent stance changed"},
  {"discovery_moment", "Oh! moment captured"},
  {"slop_detected", "Generic content flagged"},
  {"force_push", "Git history rewritten"},
  {"multi_agent_interaction", "Agents responding to each other"}
]

source_ids = ["claude-code", "curious-observer", "pattern-curator", "anti-slop-guardian"]

# Generate 20 test events
for i <- 1..20 do
  {event_type, description_base} = Enum.random(event_types)
  source_id = Enum.random(source_ids)
  
  {:ok, event} = Event.create(%{
    timestamp: DateTime.utc_now() |> DateTime.add(-:rand.uniform(3600), :second),
    event_type: event_type,
    source_id: source_id,
    source_path: "/athena/#{source_id}/#{i}",
    content: "Test #{event_type} event ##{i}",
    confidence: :rand.uniform() * 0.5 + 0.5,  # 0.5 to 1.0
    description: "#{description_base} from #{source_id}",
    metadata: %{
      test: true,
      sequence: i,
      generated_at: DateTime.utc_now()
    }
  })
  
  IO.puts "Created #{event_type} event from #{source_id}"
end

IO.puts "\nGenerated 20 test events. Check http://localhost:4000/events"