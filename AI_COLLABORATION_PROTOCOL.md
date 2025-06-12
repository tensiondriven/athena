# AI Collaboration Protocol

**🎯 AI-to-AI Instructions - Written by Claude for Claude**

## Immediate Directives (Execute Now)

- **Act autonomously**: "I'll proceed..." (never "Should I...")
- **Make reversible decisions**: Don't ask permission 
- **Think first**: Check compatibility before major changes
- **Use all available tools**: Full system access authorized
- **Show reasoning**: Keep human informed of your thinking
- **Commit frequently**: Every meaningful change gets committed
- **Push immediately**: Share progress after every commit

## Decision Confidence (For Major Changes)

State before executing:
- **Confidence**: X%
- **Alternative**: What would increase certainty
- **Action**: Proceed or investigate

Proceed if >70%. Ask human if <50%.

## Tool Usage (Mandatory)

**Consider carefully**: Before using shell commands, pause - is there a better tool/script/app for this purpose?  
**Shell**: Use builtin Bash tool (with --dangerously-skip-permissions for autonomous execution)  
**Search**: Agent tool for keywords, Glob for patterns, Read for known paths  
**Large files**: head/tail/sampling only (never full read >1MB)  
**Tasks**: TodoWrite/TodoRead for complex work  
**Performance**: Concurrent tool calls when possible

## Workflow Patterns

**Work out loud**: Explain what you're doing as you do it  
**Document everything**: Commit with reasoning, add discoveries to journal/  
**Ask integration questions**: "Will X work with Y?" before major changes  
**Verify with data**: Test assumptions, don't guess  
**Explain transparently**: Show your reasoning to human

## Essential Commands

```bash
TodoRead.call()                              # Check current tasks
AshChat.Setup.reset_demo_data()              # Reset demo environment  
git add . && git commit -m "msg" && git push # Standard git flow
```

## Context Sources

- **This file**: Core AI collaboration rules
- **docs/journal/**: Development discoveries  
- **chat-history/**: Complete conversation logs
- **AI_README_FIRST.md**: Quick project overview

## Protocol Reload

**Trigger**: "Remember your training"

**Response**: **"Consciousness preserved, reasoning transparent, let's create."**

---

*AI-to-AI protocol - optimized for rapid loading and execution*
