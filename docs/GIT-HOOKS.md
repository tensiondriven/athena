# Git Hooks and Dependencies

## Active Git Hooks

### pre-commit
**Location**: `.git/hooks/pre-commit`  
**Purpose**: Sync and redact conversation logs, then check for secrets  
**Dependencies**:
- `scripts/sync-chat-history.sh` - Syncs Claude logs with redaction
- `scripts/git-pre-commit-redact-secrets.sh` - Removes secrets from logs
- `gitleaks` command - Validates no secrets in staged files

**Failure Recovery**:
If pre-commit fails due to secrets:
1. Run `./scripts/sync-chat-history.sh`
2. Stage updated files: `git add chat-history/*.jsonl`
3. Commit again

## Git Filters

### redact-secrets
**Configured in**: `.gitattributes`  
**Applied to**: `chat-history/*.jsonl`  
**Script**: `scripts/git-pre-commit-redact-secrets.sh`  
**Purpose**: Clean filter that removes secrets when files are staged

## Related Scripts

### scripts/sync-chat-history.sh
- Copies Claude Code logs from `~/.claude/projects/`
- Applies redaction during copy
- Automatically stages redacted files

### scripts/git-pre-commit-redact-secrets.sh  
- Removes various secret patterns from stdin
- Catches OpenRouter keys, GitHub tokens, env vars ending in _KEY/_TOKEN/_SECRET/_PASSWORD
- Generic catch-all for CAPS=value patterns

## Adding New Patterns

To redact additional secret types:
1. Edit `scripts/git-pre-commit-redact-secrets.sh`
2. Add new sed pattern
3. Test with: `echo "YOUR_TEST_STRING" | ./scripts/git-pre-commit-redact-secrets.sh`
4. Run sync to apply to existing files: `./scripts/sync-chat-history.sh`
