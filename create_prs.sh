#!/bin/bash
# Create pull requests for tonight's feature branches

echo "Creating pull requests for feature branches..."

# Event Generation PR
gh pr create \
  --base master \
  --head feature/agent-event-generation \
  --title "Add agent event generation system" \
  --body "$(cat <<'EOF'
## Summary
- Agents can now generate events as they work
- Support for discovery moments, pattern detection, multi-agent interactions
- Events flow into the dashboard automatically

## Implementation
- Created `EventGenerator` module with typed event methods
- Auto-broadcast to Phoenix PubSub channels
- Events include agent metadata and confidence scores

## Example Usage
```elixir
EventGenerator.discovery_moment("Curious Observer", "Found recurring pattern!", %{})
EventGenerator.pattern_detected("Pattern Curator", "silence-before-breakthrough", 3)
```

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"

# Context Assembler PR
gh pr create \
  --base master \
  --head feature/context-assembler-improvements \
  --title "Add event-aware context assembly" \
  --body "$(cat <<'EOF'
## Summary
- Context now includes recent relevant events
- Agents remember patterns they've discovered
- Multi-agent awareness shows who else is in conversation

## Features
- `add_relevant_events/3` - Include recent discoveries in context
- `add_agent_patterns/3` - Track discovered patterns across conversations
- `add_multi_agent_context/4` - Awareness of other agents and interaction styles

## Benefits
Agents now have memory across conversations and can build on previous discoveries.

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"

# Stance Tracking PR
gh pr create \
  --base master \
  --head feature/agent-stance-tracking \
  --title "Add agent stance tracking system" \
  --body "$(cat <<'EOF'
## Summary
Track agent operational modes using stance polarities framework from hundred-rounds research.

## Stances Tracked
- **Exploration**: Open (100) vs Critical (0)
- **Implementation**: Divergent (100) vs Convergent (0)
- **Teaching**: Patient (100) vs Direct (0)
- **Revision**: Preserve (100) vs Transform (0)
- **Documentation**: Clear (100) vs Complete (0)

## Features
- Compact notation: `O85 P25 Cr60 Pr30 L75`
- Detect "impossible stances" (multiple extremes)
- Analyze messages for suggested stance shifts
- Track significant shifts (>10 points)

## Note
Event generation temporarily commented out pending EventGenerator availability.

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"

echo "Pull requests created!"
echo "Visit https://github.com/tensiondriven/athena/pulls to review"