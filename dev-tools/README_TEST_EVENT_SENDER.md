# Test Event Sender

Simple utility to verify Athena event collection pipeline is working.

## Purpose

Sends a single test event directly to the Athena surveillance system database to confirm:
- Database connectivity
- Event schema validation  
- Dashboard real-time updates
- Event pipeline functionality

## Usage

```bash
# Make executable (one time)
chmod +x test-event-sender

# Send test event
./test-event-sender
```

## What It Does

1. **Checks Database Schema**: Verifies the events table exists and shows current stats
2. **Sends Test Event**: Inserts a timestamped test event with metadata
3. **Provides Verification Steps**: Shows how to confirm the event was received

## Example Output

```
🧪 Test Event Sender
========================================
📋 Database schema:
CREATE TABLE events (...)

📊 Current event count: 1
🕐 Last event: person_detected at 2025-06-07T20:02:01.480557

Sending test event...
✅ Test event sent successfully!
   Event ID: 2
   Type: test_event_from_cli
   Description: Test event sent at 2025-06-08 21:24:40
   Database: /Users/j/Code/athena/system/bigplan/data/events.db

🔍 Check the dashboard at: http://localhost:8080
📊 Or check database directly:
   sqlite3 /path/to/events.db "SELECT * FROM events WHERE id = 2;"
```

## Verification

After running, verify the event was received:

### Via Dashboard
- Open http://localhost:8080
- Check "Recent Activity" section
- Look for `test_event_from_cli` event

### Via API
```bash
curl http://localhost:8080/api/activity
curl http://localhost:8080/api/status
```

### Via Database
```bash
sqlite3 /Users/j/Code/athena/system/bigplan/data/events.db \
  "SELECT * FROM events ORDER BY created_at DESC LIMIT 5;"
```

## Event Structure

Test events include:
- **event_type**: `test_event_from_cli`
- **source_id**: `test-event-sender`
- **confidence**: 1.0
- **description**: Human-readable timestamp
- **metadata**: JSON with test flag and sender info

## Integration

This tool validates the core event collection pipeline:

```
test-event-sender → SQLite Database → Dashboard API → Web Interface
```

Perfect for:
- ✅ CI/CD pipeline validation
- ✅ Troubleshooting event collection issues  
- ✅ Confirming system health after changes
- ✅ Demonstrating real-time event processing