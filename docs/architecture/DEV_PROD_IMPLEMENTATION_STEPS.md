# Dev/Prod Implementation Steps

**Status Tracking**: 🔵 Planned | 🟡 In Progress | ✅ Done | ❌ Blocked

## Phase 1: Live Chat Dashboard

### Step 1: Extend Shell Collector for Claude JSONL
**Status**: 🔵 Planned  
**Goal**: Monitor Claude Code JSONL files and stream to Phoenix

**Tasks**:
- [ ] Modify `/domains/events/sources/macos/athena-collector-shell.sh`
- [ ] Add Claude Code logs directory monitoring (`~/.claude-code/logs/`)
- [ ] Stream full JSONL file contents when changes detected
- [ ] Test with real Claude Code conversation logs

**Implementation Notes**:
- Use existing fswatch infrastructure
- Store entire file contents (not incremental)
- Send to Phoenix via HTTP/WebSocket

### Step 2: Add Live Events Page to ash_chat
**Status**: 🔵 Planned  
**Goal**: Real-time dashboard showing chat conversations

**Tasks**:
- [ ] Create new LiveView at `/live-events` in ash_chat
- [ ] Add route in router.ex
- [ ] Set up PubSub subscription for chat events
- [ ] Display JSONL chat messages in real-time
- [ ] Add basic message count/rate metrics

**Implementation Notes**:
- Extend existing ash_chat Phoenix app
- Use Phoenix.PubSub for real-time updates
- Simple list view of messages flowing in

### Step 3: Connect Collector to Phoenix
**Status**: 🔵 Planned  
**Goal**: Data flow from collector to LiveView dashboard

**Tasks**:
- [ ] Set up HTTP endpoint in ash_chat for receiving events
- [ ] Configure shell collector to POST to ash_chat
- [ ] Implement PubSub broadcasting in Phoenix
- [ ] Test end-to-end data flow

**Implementation Notes**:
- Reuse existing event ingestion patterns
- Minimal processing - just pass through to dashboard
- Focus on reliability over complexity

### Step 4: Verify Live Data Flow
**Status**: 🔵 Planned  
**Goal**: Demonstrate real chat conversations appearing

**Tasks**:
- [ ] Start ash_chat Phoenix app
- [ ] Start shell collector
- [ ] Have Claude Code conversation
- [ ] Verify conversation appears in `/live-events` dashboard
- [ ] Document success metrics

**Success Criteria**:
- Chat messages appear in real-time as they're created
- File modification metrics continue working
- Dashboard shows "numbers going up"

## Phase 2: Future Enhancements (Not Started)

### Knowledge Graph Integration
**Status**: 🔵 Planned  
- [ ] Neo4j connection for chat data
- [ ] Conversation parsing and extraction
- [ ] Entity/relationship identification

### Multimodal Support
**Status**: 🔵 Planned  
- [ ] Image file monitoring
- [ ] Audio file processing
- [ ] Document ingestion pipeline

### Dev/Prod Environment Split
**Status**: 🔵 Planned  
- [ ] Environment-specific configurations
- [ ] Separate data stores
- [ ] Deployment automation

## Current Blockers

**None identified** - Path is clear for Phase 1 implementation

## Dependencies

**External**:
- fswatch (already installed)
- ash_chat Phoenix app (already running)
- Claude Code generating JSONL logs

**Internal**:
- Shell collector script updates
- Phoenix app modifications
- PubSub integration

## Testing Strategy

**Manual Testing**:
1. Start collector and Phoenix app
2. Generate Claude Code conversations
3. Watch dashboard for real-time updates
4. Verify data completeness

**Success Metrics**:
- Real-time chat message visibility
- Zero data loss from JSONL files  
- Reliable collection across app restarts