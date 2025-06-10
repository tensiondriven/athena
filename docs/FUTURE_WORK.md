# Future Work

## Checklist Maker MCP

**Concept**: Simple checklist/list management MCP tool for Claude Code sessions

### Core Features
- **Create lists** with title and single-sentence items
- **List all lists** with status/metadata (creation date, item count)
- **View list contents** by line number
- **Simple metadata** tracking (age, completion status)

### Technical Design
- **No UI required** - pure MCP text interface
- **Lightweight storage** - JSON files or simple database
- **Line-numbered output** for easy reference
- **Basic CRUD operations** via MCP protocol

### Use Cases
- Session task tracking
- Quick note organization  
- Project checklists
- Research item collection
- Development todos

### Example Commands
```
list_all_checklists
create_checklist "Shopping List"
add_item "Shopping List" "Buy groceries"
show_checklist "Shopping List"
```

### Integration
- Works seamlessly with Claude Code
- Complements existing todo functionality
- Could integrate with project-specific workflows

---
*Added: 2025-06-09*