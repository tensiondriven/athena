# Phase 1: Chat UI Implementation Plan

## Overview
Redesign the chat interface with a clean, functional sidebar and improved user experience. Following ChatGPT-style interface patterns while maintaining simplicity.

## Core Requirements

### 1. Sidebar Layout
- **Visible by default** when chat interface loads
- **Collapsible/expandable** with toggle button
- **Fixed width** when expanded (e.g., 260px)
- **Smooth animation** for expand/collapse

### 2. Room Management
- **Room list** displayed in sidebar
- **"+" button** at top of sidebar to create new rooms
- **Hide rooms** instead of delete (soft delete)
  - Hidden rooms accessible via toggle or separate section
  - Implement `hidden` boolean field on Room/Channel resource
- **Room titles** display in sidebar (editing not required for Phase 1)

### 3. Routing
- **Update URL** when switching rooms: `/chat/{room-id}`
- **Direct linking** to specific rooms via URL
- **Default route** `/chat` creates new room or loads most recent

### 4. Model Selector
- **Located at bottom of sidebar** below room list
- **Visible panel** showing current model
- **Dropdown** to switch between available models
- **Persist selection** per room or globally (TBD)

### 5. Chat Interface
- **Keep existing message functionality** (it's working)
- **Message input at bottom** of screen
- **Typing indicators** when AI is generating response
  - Show "AI is thinking..." or similar
  - Consider progress indication if possible

### 6. Existing Features to Maintain
- Ollama integration
- Message sending/receiving
- System prompt configuration
- Error handling and display

## Technical Implementation Notes

### Resources to Update
1. Rename `Chat` resource to `Room` or `Channel`
2. Add `hidden` field to Room resource
3. Add `current_model` field to Room (or use global setting)

### LiveView Updates
1. Add sidebar component
2. Implement room switching logic
3. Update routing to handle room IDs
4. Add collapse/expand state management

### UI Components
1. Sidebar with room list
2. Room creation modal/inline form
3. Model selector dropdown
4. Typing indicator component

## Out of Scope for Phase 1
- Room title editing
- Keyboard shortcuts
- Image/file uploads
- Node visualization
- MCP tool integration
- Interrupt handling
- Alert entities

## Success Criteria
1. Users can create and switch between rooms
2. Sidebar provides clear navigation
3. URL reflects current room
4. Model selection is accessible
5. Hidden rooms are manageable
6. Overall UX is clean and responsive