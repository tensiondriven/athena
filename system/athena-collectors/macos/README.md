# Athena macOS Collector

File monitoring and screenshot service for Athena home automation system.

## Features

- **File Monitoring**: Claude Code logs, Chrome bookmarks, Desktop/Downloads
- **Screenshot API**: RESTful screenshot capture via `/screenshot`
- **Event Storage**: SQLite database with file metadata and hashing
- **Deduplication**: Hash-based storage prevents duplicate files
- **REST API**: Query events, stats, and health status

## API Endpoints

- `GET /health` - Health check
- `GET /screenshot` - Capture screenshot (base64 encoded)
- `GET /events?limit=50&type=created` - Get file events
- `GET /stats` - Collection statistics

## Quick Start

```bash
# Local development
pip install -r requirements.txt
python athena-collector-macos.py

# Docker deployment
docker-compose up -d

# Check status
curl http://localhost:5001/health
curl http://localhost:5001/stats
```

## Configuration

Environment variables:
- `ATHENA_DATA_DIR`: Data storage directory (default: `/data`)
- `PORT`: API port (default: `5001`)

## Monitored Locations

- `~/.claude-code/logs/` - Claude Code JSONL logs
- `~/Library/Application Support/Google/Chrome/Default/Bookmarks` - Chrome bookmarks
- `~/Downloads/` - Download events
- `~/Desktop/` - Desktop file events

## Storage Structure

```
/data/
├── collector.sqlite    # Event metadata database
└── files/             # Hash-named file storage
    ├── abc123...def.txt
    └── def456...ghi.json
```

## Integration with Athena

This collector feeds the distributed Athena event processing pipeline. Events are stored locally and can be queried via API for ingestion into central knowledge graph processing.