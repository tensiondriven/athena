# AI Learnings & Engineering Wisdom

*Collected insights from building athena-capture and other AI-assisted development*

## Core Philosophy

### When Implementation Requires Multiple Languages/Complex APIs, Step Back
**The "This is Getting Wack" Signal**: When you find yourself chaining Python → AppleScript → window server APIs just to get a window ID, you've overcomplicated it.
**The Wisdom**: If the implementation starts requiring multiple languages or complex platform APIs for basic functionality, there's usually a simpler path that's 80% as good and 10x more reliable.
**Example**: Screenshot window detection vs. full screen + metadata approach.

### Metadata About Context > Perfect Technical Execution  
**The Insight**: Knowing *what* window was active when a screenshot was taken is often more valuable than having a perfectly cropped image of just that window.
**Why**: The metadata enables search, categorization, and understanding - while perfect cropping adds fragility.
**Generalizes To**: Database schemas, API design, file naming - context beats precision.

### Reliable Simplicity Compounds Over Time
**The Pattern**: Simple, robust solutions become more valuable as systems scale because they don't break in edge cases.
**Anti-Pattern**: "We'll make it perfect later" - complex solutions rarely get simplified, they get patched.
**Test**: Can you explain the solution to someone in 30 seconds? If not, it might be too complex.

## Development Intuition

### Path Visibility Prevents Future Frustration
**The Problem**: Users (including future you) forget where files are stored.
**The Pattern**: Always surface storage paths in logs, docs, and error messages.
**Why It Matters**: Hidden file paths become "mystery meat" that frustrate users later.

### Event Architecture Enables Evolution
**The Insight**: Events let you add new behaviors without touching existing code.
**Example**: ConversationMonitor → EventStore → EventDashboard → (future: AI analysis, search, exports)
**Wisdom**: When you emit structured events, you create hooks for future capabilities.

### Progressive Disclosure in Code Architecture
**Pattern**: Start with the simplest thing that works, then add layers of sophistication.
**Why**: You learn what actually matters through usage, not speculation.
**Trap**: Building the "perfect" architecture upfront usually optimizes for the wrong things.

## Technical Subtleties

### File System Watchers Have Quirks
**Learning**: File system events can be noisy or missed - always have a periodic fallback check.
**Implementation**: Combine real-time watching with periodic scanning for robustness.

### GenServer State: Minimal and Derivable
**Wisdom**: Store only what you can't calculate. Derived values can be computed in handle_call.
**Why**: Simpler state means fewer bugs and easier reasoning.

---

*These patterns save hours of debugging and prevent overengineering. Add new insights as they emerge.*