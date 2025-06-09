# Migration to Domain-First Architecture

## Overview
Migrating Athena from component-based to domain-first architecture following Ash Framework patterns.

## Migration Mapping

### Events Domain ✅
```
system/athena-collectors/macos/     → domains/events/sources/macos/
system/athena-ingest/claude_collector/ → domains/events/processors/event-router/
system/athena-capture/              → domains/events/storage/athena-capture/
```

### Hardware Domain (Planned)
```
system/hardware-controls/           → domains/hardware/controls/
system/sam-pipeline/               → domains/hardware/cameras/vision/
system/mcp/                        → domains/hardware/sensors/mqtt/
```

### Intelligence Domain (Planned)  
```
system/ash-ai/                     → domains/intelligence/agents/chat/
system/athena-mcp/                 → domains/intelligence/tools/mcp/
system/bigplan/                    → domains/intelligence/agents/orchestration/
```

## Benefits Achieved

### Clear Responsibilities
- **Events**: Collection → Processing → Storage
- **Hardware**: Cameras, Sensors, Controls  
- **Intelligence**: AI Agents, Knowledge, Tools

### Ash-Ready Structure
Ready for:
- `Ash.Domain` organization
- `Ash.Resource` with AI extensions
- MCP tool integration
- Real-time LiveView interfaces

### Reduced Naming Confusion
- No more collector/ingest/capture ambiguity
- Domain-specific terminology
- Clear data flow patterns

## Current Status

### ✅ Completed
- [x] Domain structure created
- [x] Events domain migration complete
- [x] Documentation and READMEs
- [x] Event router (claude_collector) repositioned

### 🔄 In Progress  
- [ ] Update import paths and configurations
- [ ] Test migrated components in new locations
- [ ] Create Ash Domain definitions

### 📋 Planned
- [ ] Hardware domain migration
- [ ] Intelligence domain migration  
- [ ] MCP server consolidation
- [ ] Remove old system/ directories

## Testing Strategy

### Phase 1: Events Domain
1. ✅ Test macOS collector in new location
2. 🔄 Test event-router (claude_collector) functionality
3. 📋 Test end-to-end: sources → processors → storage

### Phase 2: Integration
1. 📋 Update all service discovery and endpoints
2. 📋 Test cross-domain communication
3. 📋 Validate MCP server functionality

### Phase 3: Cleanup
1. 📋 Remove duplicate system/ components
2. 📋 Update all documentation references
3. 📋 Final integration testing

## Rollback Plan
If issues arise:
1. Original components remain in `system/` until testing complete
2. Can revert import paths quickly
3. Gradual migration allows step-by-step validation

---
*Migration started: 2025-06-08*