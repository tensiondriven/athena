# Events Domain

Event lifecycle management from collection through storage.

## Architecture Flow

```
Sources → Processors → Storage
   ↓         ↓          ↓
Hardware   Router     Neo4j
Software   Enricher   Files  
Files      Filter     Analytics
```

## Current Components

### Sources (Data Collection)
- **macOS**: File monitoring, bookmarks, desktop events ✅ Migrated
- **Pi cameras**: Video streams, motion detection  
- **MQTT sensors**: IoT device data
- **Web scrapers**: External content ingestion

### Processors (Event Pipeline) 
- **Event router**: Central ingest endpoint (from claude_collector)
- **AI enrichers**: Content analysis, vectorization, classification
- **Transformers**: Format conversion, validation, routing

### Storage (Persistence)
- **Neo4j adapter**: Knowledge graph with relationships
- **File store**: Binary assets (images, videos, documents)
- **Analytics**: Query engine, reporting, dashboards

## Event Schema

Following the established event format from collector testing:

```elixir
defmodule Events.Resources.Event do
  use Ash.Resource,
    domain: Events.Domain,
    extensions: [AshAi]

  ash_ai do
    vectorize text: :content_summary,
             on: [:create, :update],
             store: Events.VectorStore
  end

  attributes do
    uuid_primary_key :id
    attribute :event_type, :atom  # collector_startup, file_changed, etc.
    attribute :source_path, :string
    attribute :content, :map
    attribute :metadata, :map
    attribute :file_size, :integer
    attribute :content_summary, :string
    create_timestamp :timestamp
    attribute :sent_to_server, :boolean, default: false
  end

  actions do
    defaults [:create, :read, :update]
    
    create :collect_file_event do
      argument :source_path, :string, allow_nil?: false
      argument :event_type, :atom, allow_nil?: false
      argument :content, :map
      argument :metadata, :map
      
      change set_attribute(:source_path, arg(:source_path))
      change set_attribute(:event_type, arg(:event_type))
      change set_attribute(:content, arg(:content))
      change set_attribute(:metadata, arg(:metadata))
    end
    
    read :semantic_search do
      argument :query, :string, allow_nil?: false
      argument :limit, :integer, default: 10
      # AshAI will handle semantic search automatically
    end
  end
end
```

## Integration Points

### With Hardware Domain
- Camera feeds → Events.Actions.collect_camera_frame
- Sensor data → Events.Actions.collect_sensor_reading
- PTZ commands → Events.Actions.log_hardware_action

### With Intelligence Domain  
- AI analysis → Events.Actions.enrich_with_ai
- Agent decisions → Events.Actions.log_agent_action
- Tool calls → Events.Actions.record_tool_usage

## Migration Status

- [x] Domain structure created
- [x] macOS collector migrated to sources/
- [ ] Event router from claude_collector
- [ ] Storage adapters from athena-capture
- [ ] Ash Resource definitions
- [ ] MCP tool integration