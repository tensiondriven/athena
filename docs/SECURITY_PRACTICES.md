# Security Practices

## Secret Detection with Gitleaks

This project uses [gitleaks](https://github.com/gitleaks/gitleaks) for automated secret detection to prevent accidentally committing sensitive information.

### Pre-commit Hook

We have a git pre-commit hook that automatically runs gitleaks on all staged files before each commit:

```bash
# Location: .git/hooks/pre-commit
gitleaks protect --staged --verbose
```

This ensures no secrets make it into the repository history.

### Configuration

Our custom gitleaks configuration (`.gitleaks.toml`) extends the default rules and includes:
- Ignoring git commit hashes that may appear as false positives
- Custom detection for GitHub Personal Access Tokens

### Manual Scanning

To manually scan files or directories:

```bash
# Scan entire repository
gitleaks detect

# Scan specific directory without git context
cd /path/to/directory
gitleaks detect --no-git

# Scan staged files only
gitleaks protect --staged
```

### Claude Logs Handling

The Claude conversation logs in `data/claude-logs/` require special handling:

1. **Before committing**: Run the cleaning script to remove any secrets
   ```bash
   ./data/claude-logs/clean_logs.sh
   ```

2. **Verify cleaning**: Always run gitleaks manually on the logs before committing
   ```bash
   cd data/claude-logs/live
   gitleaks detect --no-git
   ```

3. **What gets cleaned**:
   - GitHub Personal Access Tokens
   - Phoenix session cookies from ash_chat
   - Sentry API keys
   - Generic API key patterns

### Git History Cleaning

If secrets are accidentally committed, we use `git-filter-repo` to clean the history:

```bash
# Example: Replace exposed tokens with REDACTED placeholders
git filter-repo --replace-text <(echo 'REDACTED_GITHUB_TOKEN==>REDACTED_GITHUB_TOKEN')
```

### Best Practices

1. **Never disable gitleaks** - It's our safety net against accidental secret exposure
2. **Always verify Claude logs** - Run gitleaks manually before committing conversation logs
3. **Check git status** - Review what you're committing before each commit
4. **Use environment variables** - Store secrets in `.env` files (which are gitignored)
5. **Regular audits** - Periodically run `gitleaks detect` on the entire repository

### Recovery

If the pre-commit hook is missing, reinstall it:

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Pre-commit hook to check for secrets using gitleaks

echo "Running gitleaks to check for secrets..."

# Check only staged files
gitleaks protect --staged --verbose

if [ $? -ne 0 ]; then
    echo "⚠️  Secrets detected in staged files!"
    echo "Please remove the secrets before committing."
    echo "You can use 'git reset HEAD <file>' to unstage files with secrets."
    exit 1
fi

echo "✅ No secrets detected in staged files."
exit 0
EOF

chmod +x .git/hooks/pre-commit
```