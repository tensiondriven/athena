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

**Q5: External events triggering agent responses**
- Agents should be able to query recent events (not auto-triggered)
- Phase 2: Get last N events, last N unique by type, subscriptions
- For now: Single method to get recent events

**Q6: Tool allocation for agents**
- All tools available to all agents (not tied to identity)
- Personality ≠ roles (important distinction!)
- Sam and Maya can use any tools they want

**Q7: Tool approval requirements**
- No approval needed
- Log all MCP calls as events in event system
- Full transparency and auditability

**Q8: Modifying Sam and Maya**
- Yes, free to enhance as needed
- They're demo agents meant to evolve

**Q9: Backend operation without UI**
- Must work when browser/LiveView closed
- Need backend-only operation
- Phase 2: Instrumentation and visualization

**Q10: Processing indicators**
- Nice to have, not required if hard
- Phase 2: "thought", "feeling", "emote" MCP tools
- Want signals for less concrete agent states

*Questions accumulating during work...*

### Development Started - 14:16 UTC

🟣 **Discovery**: Found that multi-agent chat already exists! Lines 111-142 in chat_live.ex show agents auto-responding to messages.

⚡ **Assumption**: The current implementation processes each agent sequentially. I'll enhance this to support agent-to-agent conversations.

🟢 **Curiosity**: The system uses agent_card for personality/config and profile for inference settings. Interesting separation of concerns.

🔵 **Philosophy**: Should I create a new feature for agent-to-agent chat or enhance the existing flow? Going minimal - enhance existing.

🟤 **Technical Debt**: The agent response processing happens in the Task.start block, which means agents won't see each other's messages in real-time. Should I fix this?

⚡ **Assumption**: For now, I'll add a PubSub subscription so agents can respond to each other's messages. This enables the requested behavior.

### Multi-Agent Chat Implementation - 14:45 UTC

🟢 **Status**: Multi-agent chat conversations are now implemented!

✅ **What Was Done**:
1. Created `AshChat.AI.AgentConversation` module for selective agent responses
2. Added PubSub broadcasting when agents post messages 
3. Added loop prevention (agents check last 3 messages)
4. Implemented selective response logic:
   - 100% respond if mentioned by name
   - 70% respond to questions
   - 30% respond to statements
5. Fixed metadata handling in Message resource
6. Added handle_info for {:new_agent_message} events

🟤 **Technical Debt Remaining**:
1. The unused alias warnings (AgentCard, AgentMembership) in chat_live.ex
2. Missing Exqlite dependency for SQLite persistence
3. Could enhance loop detection with LLM-based checking

⚡ **Assumptions Made**:
1. 200ms delay between agent responses (as specified by user)
2. Simple heuristic for "should respond" logic
3. Agents process responses in parallel with 5s timeout

🔵 **Philosophy Decision**: Kept the existing agent response flow and enhanced it rather than rewriting. The PubSub approach enables agent-to-agent while maintaining the original human-to-agent flow.

### Phase 2 Insights Captured - 16:50 UTC

🟣 **Key Discoveries from Q&A**:

1. **Personality vs Roles**: Important distinction! Agents have personalities (Sam is casual, Maya is thoughtful) but tools/capabilities shouldn't be tied to identity. Any agent can use any tool.

2. **Backend-First Architecture**: Agents must work without browser/UI. This means:
   - Can't rely on LiveView presence
   - Need persistent background processing
   - Instrumentation becomes critical for observability

3. **Event Transparency**: Every MCP tool call becomes an event:
   - "Command sent: ls -la" event
   - "Command completed: ls -la (exit 0)" event  
   - Enables audit trails and debugging

4. **Agent Inner Life**: Future idea for "thought/feeling/emote" tools to surface agent's internal states. Not just actions but the reasoning/emotions behind them.

5. **Event Access Pattern**: Agents need to query events (pull model) not be triggered by them (push model). Simpler to start with.

🟤 **Architecture Questions for Later**:
- How do agents run when no LiveView sessions exist?
- Should we use GenServers for persistent agent processes?
- How do we visualize agent activity without coupling to UI?