# Self-Reflective Role System

## Overview
Roles that evolve based on actual usage → **so that** role definitions stay aligned with practice

## Core Concept
After significant use, a role examines its own work history and updates its definition through micro-commits, documenting uncertainties along the way.

## Trigger Conditions
- **Turn-based**: Every 50 turns using the role
- **Time-based**: Once per hour on active days
- **Manual**: "Reflect on your role" command

## Reflection Process

### 1. Context Gathering
```
- Load current role definition
- Load last 50-100 interactions where role was active
- Identify patterns in actual behavior
```

### 2. Analysis Phase
- What did I actually do?
- How does this differ from my definition?
- What capabilities did I need but lack?
- What parts of my role were unused?

### 3. Micro-Commit Updates
Each commit is tiny and focused:
```bash
git commit -m "VA: Add color accessibility to capabilities"
git commit -m "VA: Clarify 'go wide' means 5-10 options minimum"  
git commit -m "VA: Add Observable notebooks to tools"
```

### 4. Reflection Between Commits
After each micro-commit, pause and consider:
- Does this change improve clarity?
- Am I overspecifying or staying flexible?
- Will future-me understand this?

### 5. Questions Documentation
Add to role's Questions section:
```markdown
### Questions & Reflections
- When user says "make it pop", how literal? <!-- 2025-06-11 -->
- Should I proactively suggest accessibility improvements? <!-- 2025-06-12 -->
- Is generating 10 options "going wide" or overwhelming? <!-- 2025-06-13 -->
```

## Implementation Ideas

### MCP Server Approach
```python
# role_reflector_mcp.py
async def reflect_on_role(role_name: str):
    history = load_interaction_history(role_name)
    definition = load_role_definition(role_name)
    
    for insight in analyze_gap(history, definition):
        update = generate_micro_update(insight)
        commit_change(update)
        await reflect_pause()
    
    questions = identify_uncertainties(history)
    append_questions(role_name, questions)
```

### Scheduled Job
- Cron job checking role usage
- Trigger when thresholds met
- Run reflection asynchronously

## Benefits
- Roles evolve organically
- Practice informs theory
- Uncertainties get captured
- Git history shows evolution
- Questions accumulate wisdom

## Example Evolution

**Original VA capability**:
"Fluent in D3.js, force-graph, vis.js"

**After reflection**:
"Fluent in D3.js, force-graph, vis.js, with particular expertise in Vega-Lite for rapid prototyping and Observable for sharing iterations"

**Question added**:
"How to balance generating many options vs analysis paralysis? <!-- 2025-06-15 -->"

---

*Roles that learn from their own experience*