# Development Checklists

> Lightweight reminders based on real experience. Context notes in parentheses explain when to use or skip each item.

## ⚡ Quick Checklist for Simple Changes
- [ ] Git status clean? (quick check)
- [ ] Make the change (keep it minimal)
- [ ] Test it works (basic verification)
- [ ] Commit with clear message (what and why)
- [ ] Push immediately (real-time tracking)

## 🔍 Before You Code - Discovery Checklist
- [ ] Search for existing implementations:
  - [ ] `find . -name "*feature*" -o -name "*tool*"` (broad search)
  - [ ] Check `/system/` for external integrations (MCP servers, daemons)
  - [ ] Check `/domains/` for domain-specific code
  - [ ] Review `EXISTING_TOOLS_AND_SYSTEMS.md` (living document)
- [ ] Look for patterns:
  - [ ] Similar resource definitions in `/resources/`
  - [ ] Existing LiveView components
  - [ ] Python MCP servers that might already exist
- [ ] Ask yourself: "Did we already build this?"
- [ ] Document findings before coding (add to EXISTING_TOOLS_AND_SYSTEMS.md)

## 🚀 Starting a New Feature
- [ ] Complete "Before You Code" checklist first (prevents duplicate work)
- [ ] Read relevant documentation first (critical - saves hours of rework)
- [ ] Check if similar patterns exist in codebase (always do - consistency matters)
- [ ] Create TodoWrite list for complex tasks (skip for single-step tasks)
- [ ] Verify dependencies exist before adding (`mix hex.info package_name`) (learned the hard way with esqlite3)
- [ ] Test in IEx/REPL before standalone scripts (always - scripts lack app context)
- [ ] Check git status is clean before starting (optional but helps track changes)

## 🔍 Before Implementation
- [ ] State confidence level for approach (helps identify when to ask for guidance)
- [ ] Check existing code conventions (critical - match the codebase style)
- [ ] Verify library availability (`mix hex.info`) (always for new deps)
- [ ] Consider minimal approach first (core philosophy - always ask this)
- [ ] Ask: "What's the smallest useful version?" (prevents over-engineering)

## 💾 During Implementation
- [ ] Commit every meaningful change (critical for conversation archaeology)
- [ ] Use descriptive commit messages (future you will thank you)
- [ ] Test incrementally (catch errors early)
- [ ] Keep changes reversible (avoid one-way decisions)
- [ ] Document decisions inline (skip if obvious from code)
- [ ] Push on every commit for real-time progress tracking (others can follow along)
- [ ] Update todos as you complete them (maintains accurate state)

## ✅ After Implementation
- [ ] Run compilation check (always - catches silly errors)
- [ ] Test the happy path (minimum verification)
- [ ] Create usage documentation (skip for internal-only features)
- [ ] Add to relevant indexes (helps discoverability)
- [ ] Clean up test files (keep repo clean)

## 🚨 When Things Go Wrong
- [ ] Check error message carefully (read the whole thing, not just the first line)
- [ ] Verify function signatures (arity matters! - Exqlite.Sqlite3.bind/2 not bind/3)
- [ ] Test in application context (standalone scripts miss dependencies)
- [ ] Look for similar working code (grep is your friend)
- [ ] Document the fix (add to lessons learned)
- [ ] Check if gitleaks is blocking commits (git hashes in mix.lock got us)
- [ ] Verify module/library actually exists (esqlite3 vs exqlite mistake)

## 📝 Documentation Checklist
- [ ] Implementation guide (for complex features)
- [ ] Usage examples (always helpful)
- [ ] Lessons learned (capture mistakes for next time)
- [ ] Quick reference (copy-paste commands)
- [ ] Index/navigation aids (when docs proliferate)

## 🎯 Philosophy Check
- [ ] Is this the minimal solution? (always ask - core principle)
- [ ] Am I going down a rabbit hole? (stop and reassess if yes)
- [ ] Would a simpler approach work? (usually yes)
- [ ] Is this a "small sharp tool"? (single purpose, does it well)
- [ ] Can this be easily modified/removed? (avoid deep coupling)
- [ ] Am I losing the plot? (check against original request)

## 🔄 Every 5 Turns
- [ ] Re-read the quickstart (keeps context fresh)
- [ ] Check TodoRead status (are we completing tasks?)
- [ ] Assess progress vs plan (adjust if needed)
- [ ] Commit and push current work (checkpoint progress)
- [ ] Verify still on track (not wandering)
