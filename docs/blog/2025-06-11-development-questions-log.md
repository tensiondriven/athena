# Development Questions Log

**Sprint**: Multi-agent chat, Event integration, MCP tools  
**Start Time**: 2025-06-11 14:00 UTC
**Goal**: Track questions during autonomous development

## Question Categories

- 🟢 **Curiosity** - Would be nice to know, won't affect implementation
- 🟡 **Context** - Additional background that might influence approach  
- 🟠 **Clarification** - Need to confirm understanding
- 🔵 **Philosophy** - Approach/style preferences (minimal vs comprehensive)
- 🟣 **Discovery** - Found something unexpected, need guidance
- 🟤 **Technical Debt** - "Should I fix this while I'm here?"
- 🔴 **Blocker** - Can work around but may build wrong thing
- 🛑 **Showstopper** - Cannot proceed without answer
- ⚡ **Assumption** - Proceeding with assumption, documenting for validation

---

## Initial QA Game Session

### Round 1: Raw Questions

1. For multi-agent chat, should the agents respond to each other automatically or only when triggered?
2. Should agent responses be immediate or have realistic delays?
3. Should agents have memory of previous conversations within a room?
4. For event integration, should chat messages create events in the event system?
5. Should events be able to trigger agent responses in chat?
6. Which MCP tools should each agent have access to?
7. Should there be permissions/restrictions on tool use?
8. Is it okay to modify the existing agent cards (Sam/Maya)?
9. Should agent conversations happen in real-time through websockets or polling?
10. Do you want a UI indication when agents are "thinking" or preparing responses?

### Round 2: Revised Questions (Clearer, More Focused)

1. Should agents automatically respond to each other's messages in chat rooms?
2. Should agent responses include artificial delays to seem more human-like?
3. Should agents remember previous messages within the same room session?
4. Should every chat message create an event in the event dashboard?
5. Should external events be able to trigger agent chat responses?
6. Should I give Sam system monitoring tools and Maya screenshot/visual tools?
7. Should agents require approval before using MCP tools?
8. Can I modify the existing Sam and Maya agent configurations?
9. Should multi-agent chat use the existing Phoenix channels/LiveView setup?
10. Should the UI show when an agent is processing/thinking?

### Round 3: Multiple Choice Predictions

**Q1: Should agents automatically respond to each other's messages in chat rooms?**
- A) Yes, always respond when mentioned or contextually relevant (75% confidence)
- B) No, only respond to human messages (10% confidence)
- C) Configurable per agent (15% confidence)

**Q2: Should agent responses include artificial delays to seem more human-like?**
- A) Yes, 1-3 second delays (60% confidence)
- B) No, instant responses are fine (30% confidence)
- C) Yes, but make it configurable (10% confidence)

**Q3: Should agents remember previous messages within the same room session?**
- A) Yes, full conversation context (70% confidence)
- B) Yes, but only last N messages (20% confidence)
- C) No, stateless responses (5% confidence)
- D) Only remember their own previous messages (5% confidence)

**Q4: Should every chat message create an event in the event dashboard?**
- A) Yes, all messages are events (20% confidence)
- B) Only agent messages create events (25% confidence)
- C) Only significant messages (mentions, commands) create events (40% confidence)
- D) No, keep chat and events separate (15% confidence)

**Q5: Should external events be able to trigger agent chat responses?**
- A) Yes, agents should comment on relevant events (65% confidence)
- B) Yes, but only specific event types (25% confidence)
- C) No, keep events separate from chat (10% confidence)

**Q6: Should I give Sam system monitoring tools and Maya screenshot/visual tools?**
- A) Yes, exactly as suggested (70% confidence)
- B) Yes, but let them share all tools (15% confidence)
- C) Start with read-only tools only (10% confidence)
- D) No tools yet, just chat (5% confidence)

**Q7: Should agents require approval before using MCP tools?**
- A) No, let them use tools autonomously (60% confidence)
- B) Yes, require user approval each time (10% confidence)
- C) Log tool use but don't require approval (25% confidence)
- D) Configurable per tool danger level (5% confidence)

**Q8: Can I modify the existing Sam and Maya agent configurations?**
- A) Yes, enhance them as needed (80% confidence)
- B) No, create new agents instead (5% confidence)
- C) Yes, but preserve their core personalities (15% confidence)

**Q9: Should multi-agent chat use the existing Phoenix channels/LiveView setup?**
- A) Yes, extend the current LiveView chat (85% confidence)
- B) No, build separate agent-specific system (5% confidence)
- C) Yes, but add agent-specific channels (10% confidence)

**Q10: Should the UI show when an agent is processing/thinking?**
- A) Yes, show "thinking" or typing indicator (70% confidence)
- B) No, just show the response when ready (20% confidence)
- C) Show indicator only for long operations (10% confidence)

---

## Questions During Development

### Answers from QA Game

**Q1: Agent auto-responses**
- Agents should respond when they think it's useful
- Must be able to NOT respond (selective engagement)
- Phase 2: Check for new messages before sending, reconsider if new info
- Must prevent conversation loops in design/implementation

**Q2: Response delays**
- No artificial delays, or max 200ms if any
- (My prediction of 1-3 seconds was way off!)

**Q3: Agent memory**
- Yes, agents read room message history as needed to get up to speed
- Can maintain explicit memory (not yet defined)
- Will have implicit memory (not yet defined)
- Focus on reading history rather than complex memory systems for now

**Q4: Messages as events**
- Yes, every chat message should create an event
- Watch out for loops (chat → event → chat → event)
- Phase 2: Add loop prevention (TTL or LLM check)
- (I'll note event type/priority questions for later)

**Q5-Q10: Marked for later discussion**
- Will proceed with reasonable assumptions
- Document decisions as I go

*Questions accumulating during work...*