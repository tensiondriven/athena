# Phase 2 Features

## Terminology Note
- Using "Rooms" or "Channels" instead of "Chats"
- Future entities might include: Alerts, etc.

## Chat Room Enhancements

### Image and File Attachments
- Support image uploads in chat rooms
- Support file attachments in chat rooms  
- Display images inline within the chat conversation
- Display file attachments with appropriate preview/download options
- These features will be helpful for sharing visual content and documents

## Node View Visualization

### D3 Force Graph Integration
- Create a separate node view interface
- Use D3.js force-directed graph layout
- Display nodes for:
  - Messages sent (both user and AI)
  - AI task start events
  - AI task stop events
- Each new node branches off from its parent node
- Show thought bubbles on nodes with truncated message content
- Real-time updates as new messages/events occur

### Implementation Notes
- This is a separate feature from the main chat interface
- Could be implemented as a toggle view or separate route
- Will need to track parent-child relationships between messages/events
- Consider performance implications for long conversations

## AI Agent Features

### MCP Tool Integration
- AI agents will have access to tools via MCP (Model Context Protocol)
- Consider implications for UI when AI is using tools
- May need to show tool usage in the interface

### Interruptible Generation
- Add flag on agent for "interrupt on new message"
- Allow users to send new messages while AI is still generating
- Previous generation should be cancelled when interrupted
- Consider UI implications for showing interrupted responses

## Architecture Considerations
- Explored idea of making entire chat interface work via MCP
- Decided against it for now (adds unnecessary complexity)