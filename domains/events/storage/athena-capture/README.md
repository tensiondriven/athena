# Athena Capture

Real-time event detection and monitoring system for the Athena project ecosystem. Captures and stores raw event feeds for downstream processing by athena-ingest.

## Overview

Athena Capture is dedicated to the continuous monitoring and detection of various system events, user activities, and media changes. It maintains a lightweight, high-performance event detection engine that feeds raw data to the athena-ingest processing pipeline.

## Core Responsibilities

- **Event Detection**: Real-time monitoring of system and user activities
- **Raw Data Collection**: Capturing events in their original format
- **Event Feed Management**: Maintaining immutable event streams
- **Performance Optimization**: Minimal overhead continuous monitoring

## Features

### 🔍 **Event Monitoring**
- **File System Events**: File creation, modification, deletion, access
- **Browser Activity**: Bookmarks, page visits, downloads, tab changes
- **Screen Capture**: Screenshot detection, window focus changes
- **System Events**: Application launches, config changes, network activity
- **Time Events**: Scheduled triggers, system clock changes
- **User Interactions**: Clicks, keyboard input, focus changes

### 📊 **Data Management**
- **Raw Event Storage**: Immutable event logs with timestamps
- **Event Streaming**: Real-time feed for downstream consumers
- **Buffer Management**: Efficient memory usage for continuous operation
- **Event Deduplication**: Intelligent filtering of redundant events

### 🚀 **Performance**
- **Low Latency**: Sub-millisecond event detection
- **Minimal Overhead**: <1% CPU usage during normal operation
- **Memory Efficient**: Bounded memory usage with circular buffers
- **Configurable Sampling**: Adjustable event collection rates

## Architecture

```
System Events → Event Detectors → Raw Event Buffer → Event Feed API
     ↓              ↓                    ↓              ↓
File System    Browser Monitor    Memory Manager    athena-ingest
Screen Cap     Time Monitor       Persistence       External APIs
User Input     System Monitor     Streaming
```

## Event Types

### File System Events
```json
{
  "type": "file_event",
  "action": "created|modified|deleted|accessed",
  "path": "/path/to/file",
  "timestamp": "2025-06-06T22:52:00Z",
  "metadata": { "size": 1024, "ext": ".txt" }
}
```

### Browser Events
```json
{
  "type": "browser_event",
  "action": "bookmark_added|page_visit|download",
  "url": "https://example.com",
  "title": "Page Title",
  "timestamp": "2025-06-06T22:52:00Z"
}
```

### Screen Events
```json
{
  "type": "screen_event", 
  "action": "screenshot|window_focus|app_switch",
  "app": "Application Name",
  "timestamp": "2025-06-06T22:52:00Z",
  "metadata": { "window_title": "Document.txt" }
}
```

## Getting Started

### Prerequisites

- Python 3.8+
- OS-specific monitoring libraries
- Appropriate system permissions for event monitoring

### Installation

```bash
cd athena-capture
pip install -r requirements.txt

# Configure system permissions
sudo python setup_permissions.py

# Start event monitoring
python -m athena_capture.main
```

### Usage

```python
from athena_capture import EventCapture, EventFeed

# Start capturing events
capture = EventCapture()
capture.start()

# Access event feed
feed = EventFeed()
for event in feed.stream():
    print(f"Event: {event}")

# Configure specific monitors
capture.configure_file_monitor("/path/to/watch")
capture.configure_browser_monitor(browsers=["chrome", "firefox"])
```

## Project Structure

```
athena-capture/
├── src/
│   ├── monitors/           # Event detection modules
│   │   ├── file_monitor.py
│   │   ├── browser_monitor.py
│   │   ├── screen_monitor.py
│   │   └── system_monitor.py
│   ├── feed/               # Event feed management
│   │   ├── buffer.py
│   │   ├── stream.py
│   │   └── persistence.py
│   ├── api/                # External API interface
│   └── config/             # Configuration management
├── tests/                  # Test files
├── config/                 # Configuration files
└── README.md              # This file
```

## Configuration

Event monitoring can be configured via `config/capture.yaml`:

```yaml
monitors:
  file_system:
    enabled: true
    paths: ["/home/user", "/Documents"]
    ignore_patterns: ["*.tmp", "*.log"]
  
  browser:
    enabled: true
    browsers: ["chrome", "firefox"]
    
  screen:
    enabled: true
    screenshot_interval: 30
    
performance:
  max_memory_mb: 512
  event_buffer_size: 10000
  flush_interval: 5
```

## API Interface

Athena Capture exposes a simple API for athena-ingest and other consumers:

```python
# REST API endpoints
GET /events/stream          # Real-time event stream
GET /events/recent?limit=100 # Recent events
GET /events/range?start=X&end=Y # Events in time range
GET /health                 # System health check
```

## Development Status

🚧 **In Development** - Core event detection infrastructure is the immediate priority.

### Implementation Phases
1. **File System Monitoring** - Cross-platform file event detection
2. **Browser Integration** - Bookmark and activity monitoring
3. **Screen Capture** - Screenshot and window monitoring
4. **Event Feed API** - Streaming interface for athena-ingest
5. **Performance Optimization** - Memory and CPU efficiency
6. **Configuration System** - Flexible monitoring setup

## Integration with Athena Ingest

Athena Capture feeds events to [athena-ingest](../athena-ingest/) for processing:

```
athena-capture → Event Feed → athena-ingest → Knowledge Graph
```

## Contributing

This is part of the larger Athena project ecosystem. Please refer to the main project guidelines for contribution standards.

## License

[Add your license information here]