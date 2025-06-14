# Feature: Collaboration Card Game

**Priority**: 🟢 Medium  
**Phase**: 4
**Sprint**: 7
**Effort**: High

## Description

A turn-based card game that enacts the Collaboration Corpus through gameplay. Players (human or AI) use cards representing collaboration practices to achieve session goals.

## User Story

As a team member, I want to play a collaborative card game that helps me internalize good collaboration practices while working toward real project goals.

## Game Mechanics

### Core Rules
- 7-card hand per player
- Turn-based play
- Shared goal for the session
- Cards represent collaboration practices
- Playing cards triggers real actions

### Card Types
- **LEARN_FROM_MISTAKE**: Analyze recent error and document learning
- **REVIEW_DOCS**: Systematic documentation review
- **CHECK_ECOLOGY**: Assess project health and relationships
- **PAUSE_REFLECT**: Mandatory reflection period
- **REQUEST_HELP**: Invoke specific expertise
- **SHARE_CONTEXT**: Broadcast understanding to team
- **CELEBRATE_WIN**: Acknowledge progress

### Session Structure
```
games/
  2025-06-14-1430-implement-auth.game
  - players.json
  - deck.json
  - history.json
  - goal.md
  - outcome.md
```

## Acceptance Criteria

- [ ] Game session persistence
- [ ] Multiplayer support (human + AI)
- [ ] Real action triggers from cards
- [ ] Session goal tracking
- [ ] Score/progress system
- [ ] Game history replay

## Technical Approach

1. GenServer for game state
2. Phoenix Channels for multiplayer
3. Ash Resources for persistence
4. MCP integration for AI players
5. Event sourcing for history

## UI Components

- Card hand display
- Game board/tableau
- Turn indicator
- Goal progress
- Action log
- Player status

## Dependencies

- Multiplayer infrastructure
- MCP for AI players
- Phoenix Channels
- State persistence

## Testing

- [ ] Game rule engine tests
- [ ] Multiplayer synchronization
- [ ] AI player behavior
- [ ] Session persistence
- [ ] Performance with multiple games

## Future Enhancements

- Tournament mode
- Custom deck building
- Achievement system
- Statistical analysis
- Training scenarios

## Notes

This gamifies the Collaboration Corpus, making abstract practices concrete and learnable. Consider open-sourcing as a standalone collaboration tool.