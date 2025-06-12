# Test stance tracking system
# Run with: mix run test_stance_tracker.exs

alias AshChat.AI.StanceTracker

# Create tracker for Curious Observer
tracker = StanceTracker.new("Curious Observer", %{
  exploration: 85,      # Very Open
  implementation: 70,   # Divergent
  teaching: 60,        # Balanced patient/direct
  revision: 30,        # Transform-leaning
  documentation: 75    # Clear over complete
})

IO.puts "Initial stances for Curious Observer:"
IO.puts StanceTracker.describe_stances(tracker)
IO.puts "Notation: #{StanceTracker.to_notation(tracker)}"

# Simulate stance shifts
IO.puts "\n--- Simulating discovery moment ---"
{:ok, tracker} = StanceTracker.update_stance(tracker, :exploration, 95)
IO.puts "After discovery: #{StanceTracker.to_notation(tracker)}"

IO.puts "\n--- Focusing on specific implementation ---"
{:ok, tracker} = StanceTracker.update_stance(tracker, :implementation, 25)
IO.puts "After focusing: #{StanceTracker.to_notation(tracker)}"

# Check for impossible stance
case StanceTracker.detect_impossible_stance(tracker) do
  {:impossible_stance, extremes} ->
    IO.puts "\n⚠️  Impossible stance detected!"
    IO.puts "Extreme stances: #{inspect(extremes)}"
  :normal ->
    IO.puts "\nStance configuration is normal"
end

# Test content analysis
test_messages = [
  "I'm curious what would happen if we tried a completely different approach",
  "Let's focus on getting this specific feature working correctly",
  "That's wrong - there's a fundamental flaw in this design"
]

IO.puts "\n--- Analyzing messages for stance shifts ---"
for msg <- test_messages do
  suggestions = StanceTracker.analyze_for_stance_shift(msg, tracker)
  if Enum.any?(suggestions) do
    IO.puts "Message: '#{String.slice(msg, 0, 50)}...'"
    IO.puts "Suggested shifts: #{inspect(suggestions)}"
  end
end