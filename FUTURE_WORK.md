# Future Work

## GitHub Projects Automated Development Workflow
*Added: 2025-06-13*

### Vision
Create an automated development workflow where:
1. Development tasks are created as cards in a GitHub Project
2. Specifications are discussed and refined in the card comments/threads
3. When cards are moved to a specific column (e.g., "Ready for Development"), the AI automatically begins implementation
4. Alternatively, AI could participate in prioritization discussions and move cards when ready

### Technical Implementation
- Use `projects_v2_item` webhook events to detect column changes
- Filter for specific column transitions (e.g., "Spec Complete" → "In Development")
- Webhook payload includes:
  ```json
  {
    "action": "edited",
    "changes": {
      "field_value": {
        "field_name": "Status",
        "from": { "name": "Spec Complete" },
        "to": { "name": "In Development" }
      }
    }
  }
  ```
- AI would then:
  1. Read the full card content and discussion thread
  2. Begin implementation based on the refined specifications
  3. Update the card with progress
  4. Create PRs linked to the project card

### Benefits
- Clear separation between specification and implementation phases
- Visual project management with drag-and-drop triggering
- Full conversation history preserved in GitHub
- Natural integration with existing GitHub workflow

### Requirements
- GitHub App with Projects permission
- Webhook endpoint to receive events
- Integration with AI development tools
- GraphQL API access for reading full card content

## Room Task Management
*Added: 2025-06-13*

**Task Stack System**: Evolve `current_task` field into a full task stack
- Push/pop tasks as conversation focus shifts  
- Visual task history and context switching
- Task completion tracking and progress indicators
- Integration with AI agents for task-aware responses

## Stance Polarity UI Sliders
*Added: 2025-06-13*

Create UI controls for agent stance polarities:
- Visual sliders for each of the 6 stances
- Users can adjust agent behavior in real-time
- Other agents can request stance adjustments
- Example: "Be more exploratory" → moves Open/Critical slider

Stances:
1. Exploration: Open ←→ Critical
2. Implementation: Divergent ←→ Convergent  
3. Teaching: Patient ←→ Direct
4. Revision: Preserve ←→ Transform
5. Documentation: Clear ←→ Complete
6. Execution: Literal ←→ Interpretive

UI could show:
- Current stance as position on slider
- History of stance changes over time
- Which stances were influenced by what events

This would make agent consciousness visible and adjustable!