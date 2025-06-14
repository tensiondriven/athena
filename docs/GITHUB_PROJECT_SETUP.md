# GitHub Project Setup Guide

This guide helps create the Athena Development Roadmap project on GitHub.

## Project Structure

### Board Columns
1. **📋 Backlog** - All unstarted features
2. **🎯 Sprint Ready** - Refined and ready to start
3. **🚧 In Progress** - Active development
4. **👀 Review** - PRs and testing
5. **✅ Done** - Completed and deployed

### Labels

#### Priority
- `priority:critical` - 🔴 Blocking issues
- `priority:high` - 🟡 Important features
- `priority:medium` - 🟢 Enhancements
- `priority:low` - 🔵 Nice to have

#### Type
- `type:feature` - New functionality
- `type:bug` - Something broken
- `type:enhancement` - Improvement
- `type:research` - Investigation needed
- `type:docs` - Documentation

#### Component
- `comp:chat` - Core chat system
- `comp:ai` - AI/LLM integration
- `comp:ui` - User interface
- `comp:mcp` - Model Context Protocol
- `comp:infra` - Infrastructure

#### Phase
- `phase:2` - Enhanced Chat
- `phase:3` - Visualization
- `phase:4` - Collaboration
- `phase:5` - Platform

## Creating Issues from Feature Cards

### Template

```markdown
## Description
[From feature card description]

## User Story
[From feature card user story]

## Acceptance Criteria
[From feature card AC]

## Technical Notes
[Any implementation details]

---
**Priority**: [critical|high|medium|low]
**Effort**: [small|medium|large]
**Phase**: [2|3|4|5]
```

### Quick Issue Creation

For each feature card in `docs/feature-cards/`:

```bash
# Example using GitHub CLI
gh issue create \
  --title "Interruptible AI Generation" \
  --body "$(cat docs/feature-cards/001-interruptible-generation.md)" \
  --label "type:feature,priority:critical,comp:chat,phase:2"
```

## Milestones

Create these milestones:

1. **Phase 2: Enhanced Chat** (Due: End Q2 2025)
   - Core fixes
   - Media support
   - Advanced agents

2. **Phase 3: Visualization** (Due: End Q3 2025)
   - Force graph
   - Context management
   - Tool ecosystem

3. **Phase 4: Collaboration** (Due: End Q4 2025)
   - Card game
   - Physical integration
   - Agent evolution

4. **Phase 5: Platform** (Due: Q1 2026)
   - Performance
   - Developer experience
   - Launch

## Initial Sprint Planning

### Sprint 1 (Current)
Move these to "Sprint Ready":
- Fix duplicate messages (if any remain)
- Interruptible generation
- Message interruption flags
- Performance optimization

### Backlog Grooming
Regularly review and update:
- Acceptance criteria
- Technical approach
- Dependencies
- Effort estimates

## Automation Ideas

### GitHub Actions
```yaml
name: Auto-label PRs
on: pull_request

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v4
        with:
          repo-token: "${{ secrets.GITHUB_TOKEN }}"
```

### Project Rules
- Auto-move issues to "In Progress" when branch created
- Auto-move to "Review" when PR opened
- Auto-move to "Done" when PR merged

## Team Practices

1. **Weekly Planning**
   - Review sprint progress
   - Groom upcoming items
   - Update estimates

2. **Daily Updates**
   - Comment on active issues
   - Update blockers
   - Share discoveries

3. **Sprint Review**
   - Demo completed features
   - Gather feedback
   - Plan next sprint

## Quick Links

- [Create Project](https://github.com/tensiondriven/athena/projects/new)
- [Feature Cards](/docs/feature-cards/)
- [Backlog](/docs/FEATURE_BACKLOG.md)
- [Project Plan](/docs/PROJECT_PLAN.md)

## Next Steps

1. Create the GitHub Project
2. Add initial columns
3. Create labels
4. Import high-priority issues
5. Set up automation
6. Share with team

---

*Remember: The project board is a living artifact. Keep it updated!*