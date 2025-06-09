# Q&A Game Rules

**Date Created**: 2025-06-09  
**Purpose**: Structured requirements gathering through focused Y/N questions

## Game Overview

A collaborative requirements gathering approach where Claude asks focused Y/N questions one at a time to build understanding of project requirements, rather than overwhelming with complex multi-part questions.

## Core Rules

### 1. Question Format
- **One question at a time** - Never bundle multiple questions together
- **Y/N format preferred** - Simple binary responses when possible
- **Clear and specific** - Avoid ambiguous or compound questions

### 2. Game Flow Control
- **"QA Game Start"** - Begin the structured questioning phase
- **"QA Game End"** - Conclude the questioning phase
- **"Time Out"** - Pause the game to discuss:
  - How the game itself is going
  - Process improvements or suggestions
  - Meta-discussion about effectiveness
- **"Time In"** - Resume the game after timeout

### 3. Game Philosophy
- **Treat it like a game** - Keep it engaging and focused
- **Build understanding incrementally** - Each question builds on previous answers
- **Stay focused** - Resist the urge to explain or elaborate unless asked

### 4. Timeout Usage
Claude can call timeout to:
- Ask if the current approach is working
- Suggest improvements to question style or focus
- Check if the pace is appropriate
- Propose alternative directions
- Ensure we're getting the right information efficiently

## Benefits

1. **Prevents overwhelming complex questions** that are hard to answer
2. **Forces clarity** in both questions and responses  
3. **Builds understanding step-by-step** rather than all at once
4. **Maintains engagement** through game-like structure
5. **Allows course correction** via timeout mechanism

## Example Flow

```
Claude: "QA Game Start"
Claude: "Do you want the chat interface to support real-time messaging?"
User: "Y"
Claude: "Should it support image uploads?"
User: "N"
Claude: "Time Out - Should I focus more on AI integration questions or UI features?"
User: "AI integration"
Claude: "Time In"
Claude: "Do you want to use OpenAI as the primary AI provider?"
User: "Y"
Claude: "QA Game End"
```

## Notes

- Document game sessions in journal entries for future reference
- Adapt question style based on what works best for the specific topic
- Remember that timeout is a tool for improving the process, not avoiding it