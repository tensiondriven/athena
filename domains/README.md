# Athena Domains - Domain-First Architecture

Following Ash Framework patterns, Athena is organized into clear domain boundaries with specific responsibilities.

## Domain Structure

```
domains/
├── events/          # Event collection, processing, and storage
├── hardware/        # Physical device control and interaction  
├── intelligence/    # AI agents, knowledge, and tools
```

## Events Domain
**Responsibility**: Event lifecycle from collection → processing → storage

### `/events/sources/`
Data collection components (formerly athena-collectors):
- **macOS client**: File monitoring, bookmark changes, desktop events
- **Pi clients**: Camera feeds, sensor data, MQTT events
- **Web scrapers**: External data ingestion

### `/events/processors/` 
Event processing pipeline (from athena-ingest):
- **Event router**: Central ingest endpoint (claude_collector → event-router)
- **Enrichers**: AI-powered content analysis, vectorization
- **Transformers**: Format conversion, validation, filtering

### `/events/storage/`
Data persistence layer (from athena-capture):
- **Neo4j adapter**: Knowledge graph storage
- **File store**: Binary asset management
- **Analytics**: Query engine and reporting

## Hardware Domain  
**Responsibility**: Physical world interaction and control

### `/hardware/cameras/`
- **PTZ controls**: Camera positioning and streaming
- **Computer vision**: SAM, CLIP processing pipelines
- **Recording**: Motion detection, event-triggered capture

### `/hardware/sensors/`
- **MQTT integration**: IoT device connectivity
- **Environmental**: Temperature, motion, sound sensors
- **Network**: Device discovery and health monitoring

### `/hardware/controls/`
- **MCP servers**: AI-controllable interfaces
- **Automation**: Rule-based responses
- **Safety**: Fail-safe mechanisms and limits

## Intelligence Domain
**Responsibility**: AI agents, decision-making, and knowledge

### `/intelligence/agents/`
- **Chat agents**: Multimodal conversation interfaces (ash-ai)
- **Vision agents**: Image/video analysis and understanding
- **Decision agents**: Autonomous system control

### `/intelligence/knowledge/`
- **Vector stores**: Semantic search and embeddings
- **Knowledge graphs**: Relationship mapping and inference
- **Memory systems**: Long-term learning and adaptation

### `/intelligence/tools/`
- **MCP definitions**: AI-callable tool specifications
- **Function libraries**: Reusable AI capabilities
- **Integration adapters**: External service connectors

## Migration Strategy

### Phase 1: Event Domain ✅
- [x] Create domain structure
- [ ] Move athena-collectors → events/sources/
- [ ] Refactor athena-ingest → events/processors/
- [ ] Rename athena-capture → events/storage/

### Phase 2: Hardware Domain  
- [ ] Consolidate camera/PTZ components
- [ ] Organize sensor and MQTT systems
- [ ] Extract MCP servers to controls/

### Phase 3: Intelligence Domain
- [ ] Move ash-ai → intelligence/agents/
- [ ] Create knowledge management layer
- [ ] Unified MCP tool definitions

## Benefits

### Clear Boundaries
Each domain has specific responsibilities without overlap

### Ash Integration  
Ready for Ash.Domain, Ash.Resource, and AshAI extensions

### MCP-Native
AI agents can interact with entire system through clean interfaces

### Scalable
New components fit naturally into domain structure

---
*Domain architecture inspired by Ash Framework patterns*