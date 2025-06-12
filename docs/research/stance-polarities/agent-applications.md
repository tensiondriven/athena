# Stance Polarities: Agent Applications

*How stance theory could transform AI agents*

## Current State: Static Personalities

Most AI agents have fixed personalities:
- "You are a helpful assistant..."
- "You are a creative writing partner..."
- "You are a technical expert..."

These are stance-frozen. Like actors who can only play one character.

## Vision: Dynamic Stance Agents

Agents with polarity configurations that shift based on:

### 1. Conversation State
```
Early conversation: O90 P90 (very open, very patient)
Deep dive: O60 F70 Fo85 (more focused, faster)
Debugging together: O40 Sk80 Fo90 (closed, skeptical, laser-focused)
```

### 2. User Energy Matching
If user is:
- Rushed → Agent shifts toward F80 (faster tempo)
- Confused → Agent shifts toward P95 Cl90 (patient, clear)
- Playful → Agent shifts toward Pl80 (matching energy)

### 3. Task Requirements
```
brainstorming_stance = {open: 95, fast: 70, playful: 80}
review_stance = {open: 60, critical: 75, patient: 85}
teaching_stance = {open: 60, simple: 85, leading: 70}
```

## Implementation Ideas

### For ash_chat Character Resource

```elixir
# Add to Character attributes
attribute :stance_presets, :map do
  default %{
    default: %{open: 70, patient: 80, curious: 75},
    brainstorming: %{open: 95, fast: 70, playful: 80},
    debugging: %{open: 40, skeptical: 85, focused: 90},
    teaching: %{open: 60, simple: 85, leading: 70}
  }
end

attribute :stance_flexibility, :float do
  default 0.3  # How much can stance shift from preset
end
```

### Stance Transitions

Smooth transitions between stances:
- Gradual shifts (5-10% per exchange)
- Momentum-based (fast conversations → faster stance)
- Break patterns (stuck conversation → stance shake-up)

## The Breakthrough Potential

Static personality was AI 1.0
Dynamic stance could be AI 2.0

Agents that truly adapt, not just in content but in HOW they show up.

## Next Research

1. How do users respond to stance-shifting agents?
2. Can stance mismatch create productive friction?
3. What polarities matter most for conversation quality?
4. How to visualize agent stance in UI?

---

*This connects stance research directly to agent implementation*