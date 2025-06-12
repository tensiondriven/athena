# Agent Stance Discovery

## What I Found

The Character resource has:
- `personality` attribute (string)
- `scenario` attribute (context)
- `first_message` (sets initial tone)

But these are static strings, not dynamic configurations.

## Insight: Static Personality vs Dynamic Stance

Current system: "You are a helpful assistant who..."
Stance system: `O70 P85 Cu80` (adjustable moment to moment)

## What If...

Agents could:
1. Have a default stance configuration
2. Adjust based on conversation momentum
3. Mirror user energy (stance matching)
4. Switch stances for different tasks

## Example Enhancement

```elixir
attribute :default_stance, :map do
  default %{
    open: 70,
    patient: 85,
    curious: 80,
    playful: 60,
    leading: 30
  }
end

attribute :current_stance, :map do
  # Dynamically adjusted during conversation
end
```

## The Real Discovery

Looking at this code with stance awareness: Current AI agents are stuck in one configuration. Like a musician who only knows one key.

What if stance fluidity IS the next evolution of AI agents?