# Sidequest Protocol

## Purpose
Focused exploration of specific topics without losing main conversation context → **so that** we can gather needed information while maintaining momentum

## Trigger Phrases
- "Take a sidequest to..."
- "Do a quick sidequest on..."
- "Sidequest: [specific investigation]"

## Process

### 1. Quest Assignment
- Clear objective stated
- Scope boundaries defined
- Expected deliverable identified

### 2. Departure
```
🐎 Taking a sidequest to [objective]...
```

### 3. Investigation
- Use appropriate tools (Agent, WebSearch, Read)
- Time-box the effort (typically 10-30 minutes)
- Focus on actionable findings

### 4. Documentation
- Create research report if substantial
- File in `docs/research/[topic].md`
- Use AIX-friendly formatting

### 5. Return & Report
```
🏇 Sidequest complete!

**Key Findings:**
- [Finding 1]
- [Finding 2]

**Recommended Actions:**
- [Action 1]
```

## Example Sidequest

**Assignment**: "Take a sidequest to find the easiest way to embed charts in markdown"

**Execution**:
```
🐎 Taking a sidequest to research chart embedding...

[Investigation happens]

🏇 Sidequest complete!

**Key Findings:**
- Mermaid.js works in GitHub/GitLab markdown
- D3.js needs custom HTML but most flexible
- Chart.js good middle ground

**Recommended Actions:**
- Use Mermaid for simple diagrams
- Create HTML template for D3 force-directed graphs
```

## Best Practices
- Keep scope narrow and achievable
- Document findings immediately
- Return to main flow promptly
- File substantial research for future reference

---

*Sidequests turn questions into answers without derailing progress*