# Future Work & Ideas

*Planned improvements and explorations for athena-capture*

## Core System

### Event Pipeline Integration
- [ ] Connect to actual athena-ingest pipeline (currently just logging events)
- [ ] Add event filtering and routing capabilities
- [ ] Implement event replay/reprocessing functionality

### Storage & Persistence
- [ ] Add SQLite dependency (esqlite3) to fix EventStore warnings
- [ ] Consider object storage integration for screenshots
- [ ] Implement event archival and cleanup policies

### Monitoring & Observability
- [ ] Add metrics collection (event rates, file sizes, errors)
- [ ] Build web dashboard for real-time event monitoring
- [ ] Implement alerting for capture failures

## Screenshot Capabilities

### Enhanced Context
- [ ] Add screen resolution and display info to metadata
- [ ] Capture multiple monitors independently
- [ ] Include cursor position and active UI elements

### Smart Capture
- [ ] Automatic capture based on activity patterns
- [ ] Integration with focus/productivity tracking
- [ ] Content-aware capture (detect code, documents, etc.)

## Conversation Analysis

### Claude Logs Processing
- [ ] Extract and analyze tool usage patterns
- [ ] Build conversation topic classification
- [ ] Track code generation and iteration cycles

### Knowledge Graph Integration
- [ ] Map conversations to code changes
- [ ] Build project context from session history
- [ ] Create searchable conversation archive

## Development & Operations

### Testing & Quality
- [ ] Add comprehensive test suite
- [ ] Set up CI/CD pipeline
- [ ] Implement integration tests with real Claude logs

### Documentation
- [ ] Add usage examples and tutorials
- [ ] Document event schema and API
- [ ] Create deployment and configuration guides

## Process & Collaboration

### Team Dynamics
- [ ] **Clarify AI & human's roles and accountabilities**
- [ ] Define code review and approval processes
- [ ] Establish testing and deployment responsibilities

---

*Add new ideas and track progress on existing items*