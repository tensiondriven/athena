# Persistence Implementation: Lessons Learned

## What Worked Well

1. **Starting with Messages Only**
   - Tested the pattern with one resource first
   - Fixed binding errors early
   - Established the minimal pattern

2. **Copy-Paste Pattern**
   - Same ~20 lines for each resource
   - Easy to understand and modify
   - No abstraction overhead

3. **Async Task.start**
   - Zero performance impact
   - Silent failures don't break chat
   - Fire-and-forget simplicity

4. **JSON for Complex Fields**
   - `Jason.encode!` for maps and arrays
   - No complex schema migrations
   - Human-readable in SQLite

## Challenges Overcome

1. **Initial SQLite library issue**
   - esqlite3 didn't exist
   - Switched to exqlite quickly

2. **Binding function signature**
   - Wrong arity in first attempt
   - Fixed by checking docs

3. **Gitleaks blocking commits**
   - Git hashes in mix.lock
   - Added to allowlist

## What to Do Differently Next Time

1. **Check library existence first**
   - Run `mix hex.info <package>` before adding

2. **Test in IEx immediately**
   - Don't rely on standalone scripts
   - Use the app context

3. **Create tables upfront**
   - Even if lazy creation works
   - Easier to verify structure

## Minimal Philosophy Success

The implementation stayed true to principles:
- No feature creep
- No "while we're at it" additions  
- No premature optimization
- Just enough to collect data

Total implementation: ~200 lines across 4 files.