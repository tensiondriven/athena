# Secret Redaction System

This document describes how secrets are automatically redacted from Claude Code conversation logs before they're committed to the repository.

## Overview

Claude Code conversation logs may contain sensitive information like API keys or tokens. To prevent these from entering the Git history, we automatically redact them during the pre-commit process.

## Components

### 1. Redaction Script
**Location**: `/scripts/redact-secrets.sh`

Removes the following patterns:
- GitHub Personal Access Tokens: `github_pat_*`, `ghp_*`, `ghs_*`
- JSON fields: `api_key`, `token`, `password`, `secret`

Usage:
```bash
./scripts/redact-secrets.sh < input.jsonl > output.jsonl
```

### 2. Sync Script
**Location**: `/scripts/sync-chat-history.sh`

- Copies new/modified Claude logs from `~/.claude/projects/-Users-j-Code-athena/`
- Applies redaction during copy
- Stages redacted files for commit

### 3. Pre-commit Hook
**Location**: `.git/hooks/pre-commit`

Automatically runs the sync script before each commit, ensuring all conversation logs are redacted before entering the repository.

### 4. Git Filter (Optional)
**Location**: `.gitattributes`

Configures Git to apply redaction filter to chat-history files:
```
chat-history/*.jsonl filter=redact-secrets
```

## Manual Testing

To test the redaction without committing:
```bash
# Run the sync manually
./scripts/sync-chat-history.sh

# Check what would be redacted
./scripts/redact-secrets.sh < ~/.claude/projects/-Users-j-Code-athena/some-file.jsonl | grep REDACTED
```

## Adding New Patterns

To redact additional secret patterns, edit `/scripts/redact-secrets.sh` and add new sed expressions:
```bash
-e 's/your_pattern_here/REDACTED/g' \
```

## Troubleshooting

1. **Sync not running**: Ensure scripts are executable: `chmod +x scripts/*.sh`
2. **Secrets still detected**: Add the pattern to redact-secrets.sh
3. **Files not syncing**: Check that Claude project path exists

## Security Notes

- Redaction happens BEFORE files enter Git
- Original Claude logs are never modified
- Redacted tokens are replaced with clear markers like `REDACTED_GITHUB_TOKEN`
- Always verify redaction worked before pushing

---

See also: [Security Practices](./SECURITY_PRACTICES.md)