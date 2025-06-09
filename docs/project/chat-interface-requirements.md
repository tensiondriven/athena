# Chat Interface Requirements

**Date**: 2025-06-09  
**Status**: Product requirements gathering complete  
**Current Issue**: Chat crashes when typing a message

## Core Requirements

### 1. AI Integration
- **Provider**: Ollama (as configured previously)
- **Functionality**: Real-time chat with AI responses

### 2. Persistence & Sessions
- **Server-side storage**: All conversation history stored on server
- **Multiple conversations**: Support concurrent chat sessions/tabs
- **URL structure**: `/chat/:chat_id` for specific conversations

### 3. System Prompts & Presets
- **Customizable system prompts** per conversation
- **Save/edit presets**: Users can create, save, and edit system prompt templates
- **Preset selection**: Choose from saved presets when starting conversations

### 4. User Interface Features
- **Markdown rendering**: Full markdown support for AI responses (code blocks, formatting)
- **Typing indicators**: Display when AI is generating (if easy, otherwise future work)
- **Message display**: Support for both text and images in message history

### 5. Image Support
- **No user uploads**: Users cannot upload images directly
- **Agent-driven images**: Images come from various sources and agents can request images be added
- **Display capability**: Chat interface must render images in conversation flow

### 6. Tool Calling & MCP Integration
- **Open-ended MCP**: Full MCP (Model Context Protocol) support
- **Tool list configuration**: Tools provided via configuration, not hardcoded
- **Leverage Ash AI MCP**: Use existing Ash AI MCP infrastructure if possible
- **Dynamic MCP config**: Store MCP configuration dynamically to add tools as needed
- **Off-the-shelf tools**: Use existing MCP tools rather than custom implementations

### 7. Navigation & Organization
- **Sidebar navigation**: Left sidebar for conversation switching
- **Conversation list**: Sorted descending by last update
- **Time grouping**: 
  - First 5 days: grouped by day
  - Older: grouped by week
- **Conversation management**: Create new conversations, switch between existing

### 8. Agent-Driven Features
- **Room settings MCP**: Expose MCP tools for agents to interact with chat room
- **Required MCP tools**:
  - `get_room_info`: Agent can retrieve room/conversation information
  - `set_room_name`: Agent can set/update conversation title
- **Agent autonomy**: Agents can manage conversation metadata via MCP

## Technical Architecture

### Data Models
- **Chat Resource**: UUID, title, active status, timestamps, system_prompt_id
- **Message Resource**: Text, image URLs/data, user/assistant/system roles, metadata
- **SystemPrompt Resource**: Name, content, user-created presets
- **MCPConfig Resource**: Dynamic tool configuration storage

### UI Layout
```
[Sidebar: Conversations]  [Main: Chat Interface]
- Today                   - System prompt selector
  - Chat 1                - Message history
  - Chat 2                - Input field
- Yesterday               - Tool calling indicators
  - Chat 3
- This Week
  - Chat 4
```

### MCP Integration
- Dynamic tool loading from stored configuration
- Agent tools for room management (get_room_info, set_room_name)
- Integration with existing Ash AI MCP infrastructure
- Off-the-shelf tool support (web search, file ops, etc.)

## Success Criteria
1. ✅ User can type message without crash
2. ✅ AI responds via Ollama integration
3. ✅ Conversations persist across browser sessions
4. ✅ Multiple conversations work simultaneously
5. ✅ System prompts can be customized and saved
6. ✅ Markdown renders properly in responses
7. ✅ Sidebar navigation between conversations
8. ✅ MCP tools are available and functional
9. ✅ Agents can manage room settings via MCP

## Current Status
- **Existing**: Full chat implementation exists but crashes on message send
- **Next**: Debug and fix the crash, then enhance based on requirements