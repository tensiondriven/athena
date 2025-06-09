# Dev/Prod Implementation Steps

**Status Tracking**: 🔵 Planned | 🟡 In Progress | ✅ Done | ❌ Blocked

## Phase 1: Live Chat Dashboard

### Step 1: Extend Shell Collector for Claude JSONL
**Status**: ✅ Done  
**Goal**: Monitor Claude Code JSONL files and stream to Phoenix

**Tasks**:
- [x] Modify `/domains/events/sources/macos/athena-collector-shell.sh`
- [x] Add Claude Code logs directory monitoring (`~/.claude-code/logs/`)
- [x] Stream full JSONL file contents when changes detected
- [x] Test with real Claude Code conversation logs

**Implementation Notes**:
- Uses fswatch infrastructure
- Stores entire file contents (complete approach)
- Sends to Phoenix via HTTP POST

### Step 2: Add Live Events Page to ash_chat
**Status**: ✅ Done  
**Goal**: Real-time dashboard showing chat conversations

**Tasks**:
- [x] Create new LiveView at `/live-events` in ash_chat
- [x] Add route in router.ex
- [x] Set up PubSub subscription for chat events
- [x] Display JSONL chat messages in real-time
- [x] Add basic message count/rate metrics

**Implementation Notes**:
- Extended ash_chat Phoenix app
- Uses Phoenix.PubSub for real-time updates
- Shows messages with content preview and statistics

### Step 3: Connect Collector to Phoenix
**Status**: ✅ Done  
**Goal**: Data flow from collector to LiveView dashboard

**Tasks**:
- [x] Extended Event resource with content/source_path fields
- [x] Updated EventController to handle collector data format
- [x] Implemented PubSub broadcasting to "live_events" topic
- [x] Fixed .gitignore to allow lib/ directories

**Implementation Notes**:
- Reused existing /api/events endpoint
- Added dual PubSub broadcasting (events + live_events)
- Handles complete file content storage

### Step 4: Verify Live Data Flow
**Status**: 🟡 Ready for Testing  
**Goal**: Demonstrate real chat conversations appearing

**Tasks**:
- [ ] Start ash_chat Phoenix app (`cd ash_chat && mix phx.server`)
- [ ] Start shell collector (`cd domains/events/sources/macos && ./athena-collector-shell.sh`)
- [ ] Have Claude Code conversation (this generates JSONL files)
- [ ] Visit http://localhost:4000/live-events
- [ ] Verify conversation appears in dashboard in real-time
- [ ] Document success metrics

**Success Criteria**:
- Chat messages appear in real-time as they're created
- File modification metrics continue working  
- Dashboard shows "numbers going up"
- Full file content visible in event previews

**Ready to test!** All components implemented and committed.

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