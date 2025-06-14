# Athena Feature Backlog

*Generated from comprehensive documentation analysis*
*Date: 2025-06-14*

This document consolidates all planned features, improvements, and ideas for the Athena AI collaboration platform. Features are organized by category with priority indicators.

## Priority Legend
- 🔴 **Critical** - Core functionality or blocking issues
- 🟡 **High** - Important features for primary use cases  
- 🟢 **Medium** - Enhancements and nice-to-haves
- 🔵 **Research** - Experimental or exploratory work

## 🎯 Core Chat System

### 🔴 Critical
- [ ] Fix duplicate AI message display issues
- [ ] Ensure agent names come from database, not hard-coded "Assistant"
- [ ] Interruptible AI generation - users can send messages while AI is typing

### 🟡 High Priority
- [ ] Multi-room chat support with OTP supervision
- [ ] Room-specific agent configurations
- [ ] Client presence tracking
- [ ] Message interruption flag on agents ("interrupt on new message")

### 🟢 Medium Priority
- [ ] Room hierarchy and organization
- [ ] Message search and filtering
- [ ] Conversation export formats

## 📎 File & Media Handling

### 🟡 High Priority
- [ ] Image uploads in chat rooms with inline display
- [ ] File attachments with preview/download
- [ ] Support for all common file types

### 🟢 Medium Priority
- [ ] Image annotation tools
- [ ] File versioning
- [ ] Media gallery view

## 🎨 Character & Persona System

### ✅ Completed
- [x] SillyTavern character card import (JSON)
- [x] PNG character card import (partial - embedding works)
- [x] Drag & drop support on personas page

### 🟡 High Priority
- [ ] Character cards with full system prompt support
- [ ] Per-character inference parameter defaults
- [ ] Character switching mid-conversation
- [ ] Character export functionality

### 🟢 Medium Priority
- [ ] Character marketplace/sharing
- [ ] Character version history
- [ ] Character composition (combining traits)

## 🔧 AI Model & Inference

### 🟡 High Priority
- [ ] Dynamic provider switching (Ollama, OpenAI, Anthropic)
- [ ] Per-message inference parameters
- [ ] Provider URL configuration UI
- [ ] Model selection with provider-specific lists

### 🟢 Medium Priority
- [ ] LLM Request Router - route simple/complex requests appropriately
- [ ] Model performance metrics
- [ ] Cost tracking per provider

### 🔵 Research
- [ ] Tool use impact on LLM intelligence study
- [ ] Forced JSON response impact analysis
- [ ] Hybrid approaches - direct vs tool-mediated generation

## 📊 Visualization & UI

### 🟡 High Priority
- [ ] D3 Force Graph Node View for conversations
  - [ ] Display messages and AI events as nodes
  - [ ] Real-time updates with relationships
  - [ ] Thought bubbles with truncated content
- [ ] Separate node view interface (toggle or route)

### 🟢 Medium Priority
- [ ] Dark mode support
- [ ] Mobile-responsive design
- [ ] Customizable UI themes

## 🛠️ MCP Integration & Tools

### ✅ Completed
- [x] Multi-agent MCP spawning system
- [x] Safety controls (depth limits, TTL)
- [x] Comprehensive MCP documentation

### 🟡 High Priority
- [ ] MCP Tool Integration for AI agents
- [ ] Bridge existing Athena tools (cameras, sensors)
- [ ] Tool calling through Ash resources
- [ ] Streaming tool responses
- [ ] Tool permission management

### 🟢 Medium Priority
- [ ] Claude Code as MCP server integration
- [ ] iTerm2 MCP integration
- [ ] Custom tool development framework

## 🧠 Context Management

### 🟡 High Priority
- [ ] Context parts system for modular prompts
- [ ] Dynamic context window management
- [ ] Context summarization strategies

### 🟢 Medium Priority
- [ ] RAG integration for long-term memory
- [ ] Context presets with named configurations
- [ ] Dynamic context compression
- [ ] Tool context registration API

## 🎮 Collaboration Features

### 🟢 Medium Priority
- [ ] Collaboration Card Game (MCP)
  - [ ] Turn-based with 7-card hand
  - [ ] Game session persistence
  - [ ] Card types: LEARN_FROM_MISTAKE, REVIEW_DOCS, etc.
  - [ ] Full Collaboration Corpus integration
- [ ] Async sidequests with parallel execution

## 🤖 Agent Evolution

### 🟢 Medium Priority
- [ ] Self-Reflective Role Update Agent
  - [ ] Periodic self-reflection (50 turns/hourly)
  - [ ] Behavior analysis vs definition
  - [ ] Micro git commits for updates
  - [ ] Cognitive dissonance documentation

### 🔵 Research
- [ ] Role Schema Enforcement System
- [ ] Glossary Historian Role
- [ ] Concept genealogy visualization

## 🔧 DevOps & Infrastructure

### ✅ Completed
- [x] Simplified dependency management
- [x] External dependencies in vendor/

### 🟢 Medium Priority
- [ ] Create minimal setup script (≤10 lines)
- [ ] Automated testing infrastructure
- [ ] CI/CD pipeline improvements

## 🏛️ Physical Integration

### 🟢 Medium Priority
- [ ] Raspberry Pi camera integration
- [ ] IP camera PTZ controls
- [ ] Microphone array support
- [ ] Display registry management

### 🔵 Research
- [ ] Motion event processing
- [ ] Sound event detection
- [ ] Home Assistant integration
- [ ] MQTT message handling

## 📝 Documentation

### 🟡 High Priority
- [ ] Comprehensive API documentation
- [ ] User guide and tutorials
- [ ] Developer onboarding guide

### 🟢 Medium Priority
- [ ] Intellectual history of practices
- [ ] Concept genealogy trees
- [ ] Connection to broader movements
- [ ] Publication workflow

## 🐛 Known Issues

### 🔴 Critical
- [x] Duplicate AI message display
- [x] Hard-coded "Assistant" names

### 🟡 High Priority
- [ ] Performance issues with long conversations
- [ ] Message retrigger scenario handling
- [ ] Context window overflow handling

## Implementation Notes

1. **Completed items** from the recent autonomous session are marked with ✅
2. **Priority assignments** based on user impact and technical dependencies
3. **Research items** may spawn new feature categories
4. **Physical integration** depends on hardware availability

## Next Steps

1. Convert critical and high-priority items to GitHub issues
2. Create project board with appropriate columns
3. Establish sprint/milestone structure
4. Define acceptance criteria for each feature

---

*This backlog is a living document. Update as features are completed or priorities shift.*