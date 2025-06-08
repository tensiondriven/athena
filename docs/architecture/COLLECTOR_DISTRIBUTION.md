# Athena Collector Distribution Architecture

## System Distribution Strategy

### Central Hub (macOS Development Machine)
**Single Daemon**: `athena-collector-macos`

**Responsibilities:**
- File system watching (FSEvents API for efficiency)
- Screenshot capture (macOS screencapture command)
- Local data ingestor (validates, transforms, stores)
- Central coordination of all collectors
- Data aggregation and analysis

**Rationale:**
- Keep complexity on powerful development machine
- Single installation reduces maintenance overhead
- Leverages macOS native APIs for performance

### Edge Devices (Raspberry Pi)
**Lightweight Collectors**: `athena-collector-pi`

**Responsibilities:**
- Camera event detection
- Motion/audio sensing
- Basic preprocessing
- Forward events to central hub via MQTT/HTTP

**Rationale:**
- Minimal resource usage on constrained devices
- Simple, reliable data forwarding
- Easy to deploy and maintain

### Existing Infrastructure
**IP Cameras, Home Assistant, IoT Devices**

**Integration:**
- Use existing tools and APIs
- Forward data through standard protocols (MQTT, HTTP)
- Minimal custom code required

## File Structure

```
system/athena-collectors/
├── macos/
│   ├── athena-collector-macos.py     # Main daemon
│   ├── filesystem_watcher.py         # FSEvents wrapper
│   ├── screenshot_capture.py         # macOS screencapture
│   ├── local_ingestor.py            # Process and store
│   └── config/
│       └── collector_config.yaml
├── pi/
│   ├── athena-collector-pi.py        # Lightweight daemon
│   ├── camera_events.py              # Camera integration
│   ├── mqtt_forwarder.py             # Send to central hub
│   └── install.sh                    # Pi deployment script
├── shared/
│   ├── event_schema.py               # Common event validation
│   ├── mqtt_client.py                # Shared MQTT client
│   └── utils.py                      # Common utilities
└── docs/
    ├── deployment.md                 # Deployment guides
    └── configuration.md              # Config documentation
```

## Data Flow

```
[Edge Devices] → MQTT/HTTP → [Central Hub] → SQLite → [Analysis/Visualization]
     ↓                           ↓
[Local Events] → [File Watcher] → [Ingestor] → [Database]
```

## Implementation Phases

### Phase 1: Central Hub (Current Work)
- macOS daemon with file watching
- Screenshot capture
- Local SQLite ingestor
- Basic event schema validation

### Phase 2: Edge Collectors (Future GitHub Issues)
- Raspberry Pi collector development
- MQTT infrastructure setup
- Camera integration protocols

### Phase 3: Integration (Future GitHub Issues)
- Home Assistant connector
- IP camera integration
- Cross-device event correlation

---
*Hub-and-spoke architecture for distributed Athena data collection*