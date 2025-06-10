# Repository Organization Audit - Critical Findings

**Date**: 2025-06-09  
**Context**: Systematic cleanup of Athena monorepo after error watchdog implementation

## Major Issues Discovered

### 1. Data Bloat in domains/ Directory ⚠️ CRITICAL
- **Total size**: 1.9GB out of 3.2GB total repo
- **Location**: `domains/events/sources/macos/data/files/`
- **Content**: 897 JSONL files containing collector output data
- **Total lines**: 723,388 lines of collected data
- **Issue**: Raw collector data committed to git (should be in .gitignore)

### 2. Domains Directory Analysis
The `domains/` folder appears to be from an **incomplete migration attempt** rather than Ash codegen:
- `domains/events/` - 1.9GB (mostly data files)
- `domains/hardware/` - Empty placeholder directories
- `domains/intelligence/` - Empty placeholder directories

**MIGRATION_TO_DOMAINS.md** shows this was a planned architectural refactor that's partially complete.

### 3. Current Working Implementation
**ash_chat/** (207MB) is the actual functional system with:
- **Chat System**: `ai/`, `message.ex`, `room.ex` 
- **Event System**: `event.ex`, `event_source.ex`
- **Ash Domain**: Properly defined with 4 resources
- **Error Watchdog**: Working integration

### 4. System Directory Analysis
- `system/athena-ner/` - 524MB (Python venv taking most space)
- Multiple duplicate implementations found and removed
- Legacy components that may not align with current ash_chat approach

## Duplicates Removed (Atomic Commits)
1. ✅ `system/athena-collectors/macos/athena-collector-macos.py` - duplicate of domains version
2. ✅ `system/athena-capture/` - duplicate of domains version  
3. ✅ `docs/FUTURE_WORK.md` - consolidated into physics-of-work version

## File Organization Issues Fixed
1. ✅ Added comprehensive .gitignore for log files and crash dumps
2. ✅ Fixed missing newlines in source files
3. ✅ Updated outdated path references in documentation

## Recommendations

### Immediate Actions Needed
1. **Clean up data files**: Remove 1.8GB of collected data from git
2. **Decide on domains/ folder**: Keep or remove incomplete migration
3. **Focus on ash_chat/**: Consolidate around working implementation

### Strategic Decisions Required
1. **Single source of truth**: Choose between domains/ migration vs ash_chat/ focus
2. **Data storage**: Move collector output to proper data directories outside git
3. **Monorepo boundaries**: Clarify which components are active vs legacy

## Repository Structure Analysis

### Current Reality (Post-Cleanup)
```
athena/ (3.2GB total)
├── ash_chat/ (207MB) ← WORKING IMPLEMENTATION
│   ├── lib/ash_chat/ai/ (chat system)
│   ├── lib/ash_chat/resources/ (4 Ash resources)
│   └── error_watchdog.sh (active tooling)
├── domains/ (1.9GB) ← MIGRATION ATTEMPT + DATA BLOAT
│   └── events/sources/macos/data/ (1.8GB raw data)
├── system/ (587MB) ← LEGACY COMPONENTS
│   └── athena-ner/.venv/ (524MB Python deps)
└── docs/ (1MB) ← CLEAN
```

### Ash Framework Implementation
The working Ash implementation is in `ash_chat/domain.ex`:
```elixir
resources do
  resource AshChat.Resources.Room
  resource AshChat.Resources.Message  
  resource AshChat.Resources.Event
  resource AshChat.Resources.EventSource
end
```

This shows **two logical components** that could potentially be split:
1. **Chat Domain**: Room, Message
2. **Events Domain**: Event, EventSource

## Next Steps

### Atomic Cleanup Tasks
1. Remove data files from domains/events/sources/macos/data/
2. Update .gitignore to prevent future data commits
3. Decide fate of domains/ migration vs focusing on ash_chat/
4. Clean up system/ legacy components

### Strategic Planning
1. Determine if domains/ migration should be completed or abandoned
2. Consider splitting ash_chat into chat + events domains if beneficial
3. Establish clear data storage patterns outside of git

---

**Analysis Tools Used**: `du`, `find`, `wc`, directory spelunking  
**Key Insight**: Repository grew to 3.2GB primarily due to collector data being committed instead of .gitignored  
**Status**: Ready for systematic cleanup with atomic commits