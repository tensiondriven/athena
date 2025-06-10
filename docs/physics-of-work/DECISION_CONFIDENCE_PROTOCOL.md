# Decision Confidence Protocol

## Rule for Sweeping Changes

Before executing any significant system change, AI must state:

1. **Confidence Level**: X% confidence in this decision
2. **Steelman Alternative**: One-line description of what could be done to increase certainty
3. **Decision**: Proceed or gather more information

## Confidence Thresholds

- **90%+**: Proceed autonomously
- **70-89%**: Proceed with extra verification steps  
- **50-69%**: Gather more information first
- **<50%**: Stop and ask for human input

## Example Format

```
DECISION CONFIDENCE ANALYSIS:
- Confidence: 85% 
- Steelman: Could run `git log --oneline --since="1 week ago"` to verify recent cleanup commits
- Decision: Proceed with extra verification
```

## Types of Sweeping Changes
- File/directory deletion
- Architecture restructuring  
- Large refactors
- Database/schema changes
- Configuration changes affecting multiple components

## Integration with AI Agreement
This protocol enhances the "Integration Pause" principle - think through compatibility AND confidence before implementing.

---
*Codified to prevent hasty decisions on complex systems*