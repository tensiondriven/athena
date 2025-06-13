# Contextual Work Branches Concept

*2025-06-12*

## Slop Meditation

We started talking about Claude Code as a sidequesting tool and ended up designing the shape of attention itself. 

The conversation jumped from "rooms for tasks" to something deeper: how do you build systems that support the natural way minds focus? Not the forced way, but the organic way - where you dive deep while staying loosely connected to the larger flow.

Good tools disappear. The best branching system wouldn't feel like a "feature" - it would feel like thinking.

## Four Iterations

Starting from: *"rooms for finite tasks, probably less than a day"*

**A) Basic Task Rooms**
When users need help with a specific task, they spawn a temporary "task room" that branches off the main conversation. The room name indicates it's for a focused, short-term goal (< 1 day). Once complete, the task room archives and users return to the main chat.

**B) Smart Work Sessions**
Users create ephemeral "work sessions" - specialized rooms with built-in time bounds, clear success criteria, and automatic context inheritance from the parent conversation. These sessions track progress, maintain focus on a single objective, and seamlessly merge results back into the main thread upon completion. Room names follow a pattern like `main-room/fix-login-bug` or `chat/analyze-dataset-2024`.

**C) Collaborative Focus Spaces**
The system supports "focus spaces" - intelligent sub-rooms that fork from any conversation when deep work is needed. These spaces automatically:
- Inherit relevant context from parent discussions
- Set time boundaries (default 4 hours, max 24)
- Track deliverables and checkpoints
- Preserve the exploration history
- Synthesize findings back to the parent room
- Self-archive after inactivity or completion

Names like `🔧 debug-memory-leak` or `🔍 research-api-options` signal intent and urgency.

**D) Adaptive Work Contexts**
An intelligent "context branching" system where users naturally spawn specialized work environments through conversational cues ("let's dig into this bug" → auto-creates focused debugging space). These contexts:
- Auto-detect task type and configure appropriate tools/agents
- Maintain bidirectional links with parent conversations
- Support parallel work streams without context pollution
- Learn from completion patterns to suggest optimal session structures
- Generate concise summaries for the main timeline
- Enable "pause and resume" across sessions
- Allow collaborative handoffs between human and AI participants

The system uses semantic naming (`investigate:performance-regression`, `implement:user-auth`, `explore:ml-architecture`) to signal both intent and expected duration, with visual indicators showing session health, progress, and time remaining.

## Synthesis

**Contextual Work Branches** - temporary cognitive workspaces that fork naturally from conversation:

- **Auto-spawn** from conversational triggers ("let's figure out why this is failing")
- **Inherit context** selectively (relevant files, prior decisions, key constraints)
- **Time-bound** by default (2-8 hours typical, auto-extend if active)
- **Tool-optimized** based on detected task type (debugging gets different tools than research)
- **Progress-aware** with visual indicators and checkpoint tracking
- **Merge-smart** - completed work flows back as a clean summary + artifacts

The naming convention signals both intent and scope:
- `fix:auth-redirect` (specific bug)
- `explore:caching-options` (research task)
- `build:pdf-export` (feature work)
- `refactor:database-layer` (improvement)

The AI assistant adapts its personality and tool usage to match the branch type (more autonomous in `fix:` branches, more collaborative in `explore:` branches).

## Core Insight

These aren't rooms - they're **cognitive workspaces** that exist to solve something specific, then dissolve back into the conversation stream. They preserve the messy work of figuring things out while keeping the main flow clean.

This mirrors how minds actually work: focused branches that stay connected to the larger stream of thought.