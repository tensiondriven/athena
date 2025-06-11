# Claude Conversation Logs Archive

This directory contains a safe, append-only archive of Claude conversation logs.

## Directory Structure

```
claude-logs/
├── archive/                    # Timestamped backups
│   └── YYYYMMDD_HHMMSS_*      # Full snapshots
├── live/                       # Live sync from ~/.claude/projects
│   └── {project-paths}/        # Project-specific JSONL logs
├── sync_claude_logs.sh         # Sync script (append-only)
├── sync.log                    # Sync operation logs
└── README.md                   # This file
```

## Log Format

Claude Code stores conversations in JSONL (JSON Lines) format:
- Location: `~/.claude/projects/{project-path}/*.jsonl`
- Each line is a JSON object representing a conversation event
- Files are append-only (new events added to end)

## Safety Features

1. **Never modifies source files** - Only reads from ~/.claude
2. **Append-only sync** - Uses rsync --append-verify
3. **Timestamped backups** - Full snapshots in archive/
4. **Git tracking** - Optional git commits for version history
5. **Detailed logging** - All operations logged to sync.log

## Usage

### Manual Sync
```bash
./sync_claude_logs.sh
```

### Automated Sync (macOS launchd)
```bash
# Create ~/Library/LaunchAgents/com.athena.claude-logs-sync.plist
# Run every 5 minutes
```

### Access Logs Programmatically
The Claude collector reads from the `live/` directory to avoid
interfering with Claude's own file operations.

## Important Notes

- **DO NOT DELETE** any files from ~/.claude/projects
- **DO NOT MODIFY** the JSONL files (append-only)
- The sync script is idempotent and safe to run multiple times
- Consider the logs as sensitive data (contains conversation history)

## Example Log Entry

```json
{"type":"user","message":{"role":"user","content":"Where were we?"},"uuid":"b3c06436-7263-4bbd-8edc-d1d23418457a","timestamp":"2025-06-08T21:50:08.505Z"}
```

---
*Created: 2025-06-08 - Part of Athena event collection system*