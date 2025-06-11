# Checklist MCP - Hierarchical Task Management for LLMs

A Model Context Protocol server providing nested todo lists with an LLM-friendly text interface.

## Features

- **Hierarchical Structure**: Nest items within items for complex task breakdown
- **Multiple Lists**: Create and switch between different checklists
- **Status Tracking**: `[ ]` pending, `[~]` in progress, `[x]` completed, `[!]` blocked
- **Notes**: Add context to any item
- **TUI Output**: Clean text rendering optimized for LLM reading

## Installation

1. Add to your Claude Desktop config:
```json
{
  "mcpServers": {
    "athena-checklist": {
      "command": "python",
      "args": [
        "/Users/j/Code/athena/system/athena-mcp/checklist_mcp_server.py"
      ]
    }
  }
}
```

2. Restart Claude Desktop

## Usage

### Basic Operations

```
# Create a new checklist
checklist_create(name="feature-xyz")

# Add items
checklist_add(text="Design API endpoints")
# Returns: Added 'Design API endpoints' to feature-xyz (ID: item_1)

# Add nested items
checklist_add(text="Define request schemas", parent_id="item_1")
checklist_add(text="Define response schemas", parent_id="item_1")

# Update status
checklist_status(item_id="item_2", status="completed")

# Add notes
checklist_note(item_id="item_1", note="Following REST conventions")

# View checklist
checklist_view()
```

### Example Output

```
=== feature-xyz ===
[~] item_1: Design API endpoints // Following REST conventions
  [x] item_2: Define request schemas
  [ ] item_3: Define response schemas
[ ] item_4: Implement endpoints
[ ] item_5: Write tests

--- Progress: 1/5 completed ---
```

## Design Philosophy

1. **LLM-First Interface**: Text-based output that's easy to parse visually
2. **Minimal Friction**: Simple commands, clear feedback
3. **Hierarchical Thinking**: Supports natural task decomposition
4. **Stateful Context**: Maintains current list context between calls

## Integration with Athena

This MCP complements the TodoWrite/TodoRead tools by providing:
- More granular task breakdown
- Visual hierarchy in text format
- Quick status overview
- Session-specific task tracking

## Future Enhancements

- [ ] Persistence across sessions
- [ ] Time tracking per item
- [ ] Priority levels
- [ ] Export to markdown
- [ ] Integration with TodoWrite

---

*Part of the Athena MCP ecosystem*