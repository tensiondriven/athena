# Existing Tools and Systems

> A living document of what's already built to avoid reinventing the wheel

## MCP Servers (Python)

Located in `/system/athena-mcp/`:

- **screenshot_mcp_server.py** - Takes screenshots from cameras/webcams
- **camera_mcp_server.py** - Generic camera control interface
- **ptz_mcp_server.py** - PTZ camera specific controls
- **qa_mcp_server.py** - QA game functionality
- **cheatsheet_server.py** - Cheatsheet access

## Event System

- **Resource**: `AshChat.Resources.Event` 
- **Attributes**: timestamp, event_type, source_id, source_path, content, metadata
- **Actions**: create, recent, by_event_type, by_source
- **Used for**: Tracking all system events including tool usage

## Screenshot/Camera Infrastructure

- **Athena Capture**: `/domains/events/storage/athena-capture/`
  - `screenshot_capture.ex` - Elixir screenshot capture module
  - `ptz_camera_capture.ex` - PTZ camera integration

- **Hardware Controls**: `/system/hardware-controls/`
  - `daemons/` - Camera daemon implementations
  - `ptz-rest-api/` - REST API for PTZ control
  - `webcam-ptz-native/` - Native webcam PTZ interface

## Tools System

- **AshChat.Tools** - Main tools module (currently placeholder)
- **Shell Tool** - `AshChat.Tools.Shell` (just created)
- **Integration Point**: Tools.list() returns LangChain-compatible tool definitions

## AI/MCP Integration

- **AshAi.Mcp** - MCP protocol implementation in Elixir
- **Supports**: JSON-RPC, SSE, session management
- **Location**: `ash_chat/deps/ash_ai/lib/ash_ai/mcp.ex`

## Data Persistence

- **SQLite**: Messages, rooms, users, agent_cards are persisted
- **ETS**: Events, agent memberships use in-memory storage
- **File**: `ash_chat.db` for SQLite persistence

## Agent System

- **AgentCard**: Personality/configuration
- **Profile**: Inference settings (model, temperature, etc)
- **AgentMembership**: Which agents are in which rooms
- **AgentConversation**: Multi-agent chat logic

## Event Dashboard

- **LiveView**: `/` route shows event dashboard
- **Phoenix**: Full web interface at port 4000