# Autonomous Agent Architecture

Implemented an event-driven system where agents can converse autonomously, even when no users have the chat UI open.

## Key Components

### 1. MessageEventProcessor
- Central hub for all message events
- Generates events for the event feed
- Broadcasts to UI subscribers
- Manages room workers
- Located at: `lib/ash_chat/ai/message_event_processor.ex`

### 2. RoomConversationWorker
- Handles agent conversations for a specific room
- Message queue ensures proper ordering
- Idle timeout after 30 minutes of inactivity
- Located at: `lib/ash_chat/ai/room_conversation_worker.ex`

### 3. RoomConversationSupervisor
- DynamicSupervisor for room workers
- Handles worker lifecycle
- Restarts failed workers
- Located at: `lib/ash_chat/ai/room_conversation_supervisor.ex`

## Event Flow

1. User/Agent creates message → Message resource triggers event processor
2. MessageEventProcessor:
   - Generates event for event feed
   - Broadcasts to UI subscribers
   - Ensures room worker exists
   - Sends message to room worker
3. RoomConversationWorker:
   - Queues incoming messages
   - Processes messages in order
   - Triggers agent responses
   - Broadcasts thinking states
4. Agent responses create new messages → Loop continues

## Benefits

- **Autonomous Conversations**: Agents can talk without UI
- **Event Sourcing**: All messages generate events
- **Resilient**: Supervised workers restart on failure
- **Ordered**: Message queues preserve conversation flow
- **Efficient**: Workers shut down when idle
- **Observable**: Telemetry tracks performance

## Example: Agents Conversing Alone

```elixir
# Even with no LiveView connections, this works:
# 1. Agent A posts a message
# 2. MessageEventProcessor picks it up
# 3. RoomConversationWorker triggers Agent B to respond
# 4. Agent B's response triggers Agent A
# 5. Conversation continues autonomously
```

## Configuration

Workers shut down after 30 minutes of inactivity:
```elixir
@idle_timeout :timer.minutes(30)
```

## Future Enhancements

- Circuit breakers for external services
- Backpressure for high message volumes
- Distributed support across nodes
- Event replay capabilities
- Conversation checkpoints