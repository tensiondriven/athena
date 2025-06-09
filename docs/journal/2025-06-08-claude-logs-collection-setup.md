# Setting Up Claude Logs Collection

**Date**: 2025-06-08  
**Context**: Building real-time Claude conversation collector  
**Discovery**: Claude Code stores logs in `~/.claude/projects/{project-path}/*.jsonl`

## The Quest for Claude Logs

Jonathan wanted real-time collection of Claude conversation logs. "We can post up the whole file, don't really care about redundancy," he said. The key requirement: **idempotent and append-only** - never delete any logs.

## Discovery Process

Started by searching the usual suspects:
- `~/Library/Application Support/Claude/` - config files only
- VS Code workspaces - found Copilot chat, not Claude
- Various Claude extensions - old conversations from other tools

Then found the jackpot: `~/.claude/projects/`

Each project gets its own directory with JSONL files containing the full conversation history. Each line is a JSON object representing a conversation event - user messages, assistant responses, tool uses, everything.

## Safety-First Architecture

Created a multi-layered approach to protect the logs:

### 1. Archive System
```
/Users/j/Code/athena/data/claude-logs/
├── archive/                    # Timestamped backups
├── live/                       # Live sync from ~/.claude/projects
├── sync_claude_logs.sh         # Append-only sync script
└── sync.log                    # Operation logs
```

### 2. Append-Only Sync
Used `rsync --append-verify` to ensure:
- Never modifies source files
- Only appends new content
- Verifies data integrity
- Preserves file timestamps

### 3. Automated Backups
- Initial timestamped backup: `20250608_234943_claude_projects_backup`
- Continuous sync every 5 minutes via launchd
- Optional git commits for version history

## Implementation Status

### Completed
- ✅ Located Claude logs in `~/.claude/projects/*.jsonl`
- ✅ Created backup/archive system
- ✅ Built append-only sync script
- ✅ Set up automated sync (launchd plist ready)
- ✅ Documented everything in README

### In Progress
- 🔄 Updating claude_collector to read from synced location
- 🔄 Testing JSONL parsing and event streaming
- 🔄 Wiring to Neo4j for knowledge graph storage

### Next Steps
1. Finish updating the Elixir collector to process JSONL files
2. Stream conversation events to Neo4j
3. Test with live conversation updates
4. Deploy collector as systemd/launchd service

## Technical Notes

The JSONL format is perfect for append-only operations. Each conversation event is a complete JSON object on its own line:

```json
{"type":"user","message":{"role":"user","content":"Where were we?"},"uuid":"b3c06436-7263-4bbd-8edc-d1d23418457a","timestamp":"2025-06-08T21:50:08.505Z"}
```

This means we can:
- Process files line by line (streaming)
- Track position in file for incremental processing
- Never worry about partial JSON parsing
- Detect new content by file size changes

## Lessons Learned

1. **Claude's file organization is clean** - One directory per project, JSONL for append-only logs
2. **macOS file watching can be tricky** - Using both FileSystem watcher and polling for reliability
3. **Safety first with user data** - Multiple backup layers before touching anything
4. **Idempotent operations are key** - Script can run repeatedly without issues

## The Human Touch

Jonathan's emphasis on "idempotent and append-only" shows the wisdom of someone who's lost data before. This isn't just about collecting logs - it's about respecting the conversation history and ensuring it's never lost.

The redundancy he mentioned ("don't really care about redundancy") is actually a feature - better to have multiple copies than risk losing unique conversations.

---

*Next session: Wire up the Elixir collector to start streaming these conversations into the knowledge graph*