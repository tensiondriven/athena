# Athena Event Types and Data Sources

## User Stories

**"I want all my conversations with Claude Code to be searchable in future conversations and I want to be able to extract knowledge from it and then visualize and query that later"**

This drives the need to capture:
- Chat logs (JSONL files from Claude conversations)
- System prompts and responses
- Code changes and git commits from those conversations
- File modifications made during conversations

**"I want to understand patterns in how I work - when I'm most productive, what triggers deep work sessions, how my environment affects my focus"**

This drives the need to capture:
- Browser bookmarks changes
- Browsing history (if enabled)
- Application usage patterns
- File access patterns
- Home Assistant device states (lighting, temperature, etc.)

**"I want the system to learn from everything happening in my physical space and make intelligent decisions about displays, alerts, and automation"**

This drives the need to capture:
- Motion detection events
- Person/animal/vehicle detection
- PTZ camera position changes
- Screenshot captures and video recordings
- Sound level changes and audio classification
- Microphone and speaker activity

**"I want a complete audit trail of how my home automation responds to events, so I can improve the system and troubleshoot issues"**

This drives the need to capture:
- MQTT messages from IoT devices
- Device state changes (lights, sensors, etc.)
- Automation triggers and responses
- Device heartbeats and connectivity changes
- System resource usage and error events

## Event Sources

Based on these user stories, we capture data from:

- Chat logs and voice interactions
- Browser and application activity
- File system modifications
- Home automation devices and sensors  
- Cameras and audio equipment
- Network and infrastructure systems
- Media files (images, video, audio, documents)

## Event Schema Structure

```json
{
  "timestamp": "2025-06-08T16:30:00Z",
  "source_type": "logged-conversation",
  "source_id": "claude-code-session-2025-06-08",
  "data": {
    "file_path": "/path/to/chat.jsonl",
    "size_bytes": 1024,
    "message_count": 15
  },
  "metadata": {
    "confidence": 1.0,
    "processing_time_ms": 5,
    "tags": ["ai", "collaboration", "physics-of-work"]
  }
}
```

**Example source_types:**
- `captured-still`, `detected-motion`, `recorded-video`
- `logged-conversation`, `sent-message`, `updated-prompt`
- `modified-file`, `changed-bookmark`, `accessed-document`
- `triggered-automation`, `changed-device-state`, `sent-mqtt`

## Storage Targets

### Primary Storage
- **SQLite database** (`data/events.db`) - structured queries
- **File queue** (`data/queue/`) - processing backlog

### Future Storage Options
- **S3 bucket** - long-term archive
- **Neo4j graph** - relationship analysis
- **Time series DB** - temporal patterns

## Ingestion Pipeline

1. **File watchers** monitor directories
2. **Event extractors** parse different formats
3. **Event validator** ensures schema compliance
4. **Storage engine** persists to database/queue
5. **AI processors** analyze and respond

---
*Comprehensive event taxonomy for Athena distributed AI system*