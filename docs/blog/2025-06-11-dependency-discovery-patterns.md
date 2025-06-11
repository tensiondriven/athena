# Dependency Discovery Patterns: Making Hidden Connections Visible

**Date**: 2025-06-11  
**Context**: Renaming `redact-secrets.sh` to `git-pre-commit-redact-secrets.sh`  
**Problem**: How do we make dependencies and relationships between files discoverable?

## The Problem

When you see a file like `redact-secrets.sh` in isolation, you can't tell:
- What depends on it
- When it's executed
- Whether it's part of the build/deploy pipeline
- If removing it would break something

## Five Rules from Different Perspectives

### 1. **Naming as Documentation Rule** (Developer Experience)
> "A file's name should include its trigger context when it's not directly invoked by developers"

Examples:
- `git-pre-commit-redact-secrets.sh` (triggered by git)
- `cron-daily-cleanup.sh` (triggered by cron)
- `webpack-plugin-assets.js` (used by webpack)
- `github-action-deploy.yml` (triggered by GitHub)

**When to apply**: When a script is invoked by a system/tool rather than directly by developers.

### 2. **Dependency Chain Rule** (Architecture)
> "Every automated script should have a 'Called by:' comment header listing its triggers"

Example:
```bash
#!/bin/bash
# Called by: .git/hooks/pre-commit
#            scripts/sync-chat-history.sh
# Purpose: Redact secrets from chat logs before commit
```

**When to apply**: Always, but especially critical for scripts in generic directories like `/scripts`.

### 3. **Inverse Manifest Rule** (Documentation)
> "Tools that invoke other files should maintain a manifest of their dependencies"

Example in `.git/hooks/pre-commit`:
```bash
# Dependencies:
# - scripts/sync-chat-history.sh
# - scripts/git-pre-commit-redact-secrets.sh
# - gitleaks (external command)
```

**When to apply**: In any orchestrator file (hooks, CI configs, makefiles).

### 4. **Co-location When Possible Rule** (Organization)
> "Keep single-purpose dependencies next to their caller when feasible"

Instead of:
```
/scripts/redact-secrets.sh
/.git/hooks/pre-commit
```

Consider:
```
/.git/hooks/pre-commit
/.git/hooks/pre-commit-redact-secrets.sh
```

**When to apply**: When a script has only one caller and no shared functionality.

### 5. **Discoverable Documentation Rule** (Tooling)
> "Create tool-specific dependency maps that are automatically findable"

Examples:
- `GIT-HOOKS.md` listing all git hooks and their dependencies
- `.github/PIPELINE-DEPS.md` for CI/CD dependencies
- `CRON-JOBS.md` for scheduled task dependencies

**When to apply**: When you have multiple hidden dependencies of the same type.

## The Meta-Rule

**"Make the implicit explicit"** - Whether through naming, documentation, organization, or tooling, hidden dependencies should be discoverable without having to trace through code execution.

## Applied to Our Case

We chose Rule #1 (Naming as Documentation) because:
- It's immediately visible without opening files
- It works well with existing project structure
- It's grep-friendly: `ls scripts/git-*` shows all git-related scripts
- It's self-documenting for new developers

## Questions for Future Consideration

1. Should we add a `DEPENDENCIES.md` at the project root?
2. Could we automate dependency discovery with tooling?
3. Would a naming convention like `[trigger]-[action]-[target].sh` be too verbose?

---

*The best documentation is the kind you can't avoid seeing* - Unknown