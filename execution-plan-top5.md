# Execution Plan: Top 5 Tasks

## 1. Test duplicate message fixes in actual ash_chat application (HIGH)

### Steps:
1. **Start ash_chat server** (30s)
   - Input: Clean slate
   - Output: Server running on localhost:4000
   - Verification: Can access chat interface

2. **Trigger duplicate message scenario** (60s)
   - Input: User sends message, immediately clicks "retrigger"
   - Output: Should see warning "Agents are already responding"
   - Verification: No duplicate messages appear

3. **Test agent name consistency** (30s)
   - Input: Agent responds in chat
   - Output: Agent name displays from database, not "Assistant"
   - Verification: Name matches agent card name

## 2. Properly test MCP spawning - verify it actually works end-to-end (HIGH)

### Steps:
1. **Test Node.js MCP server directly** (60s)
   - Input: `echo '{"method":"tools/list","id":1}' | node claude-spawner.js`
   - Output: JSON response with spawn_claude tool
   - Verification: Valid JSON, no errors

2. **Test simple spawn via command line** (90s)
   - Input: Manual MCP call with simple prompt
   - Output: Spawned Claude response
   - Verification: Response contains expected content + spawn metadata

3. **Document working example** (30s)
   - Input: Working command sequence
   - Output: README section with copy-paste example
   - Verification: Others can reproduce the test

## 3. Add SillyTavern character card import (JSON) (MEDIUM)

### Steps:
1. **Research SillyTavern JSON format** (60s)
   - Input: SillyTavern documentation/examples
   - Output: Sample JSON structure documented
   - Verification: Know required fields (name, description, etc.)

2. **Add file upload to personas page** (90s)
   - Input: Existing personas LiveView
   - Output: File input accepts .json files
   - Verification: Can select JSON file

3. **Parse and create AgentCard** (60s)
   - Input: Uploaded JSON file
   - Output: New AgentCard record in database
   - Verification: Card appears in personas list

## 4. Simplify dependency management system (MEDIUM)

### Steps:
1. **Audit current setup script** (30s)
   - Input: setup-dependencies.sh
   - Output: List of what's actually needed vs over-engineered
   - Verification: Clear list of requirements

2. **Create minimal version** (60s)
   - Input: Essential requirements only
   - Output: Simplified script (≤10 lines)
   - Verification: Still installs claude-code-mcp successfully

3. **Test and replace** (30s)
   - Input: Clean environment
   - Output: Dependencies installed via minimal script
   - Verification: MCP servers work

## 5. Create comprehensive MCP testing script (MEDIUM)

### Steps:
1. **Create test script skeleton** (30s)
   - Input: Known working MCP calls
   - Output: Shell script with test functions
   - Verification: Script runs without errors

2. **Add spawn tests** (60s)
   - Input: spawn_claude and spawn_status tools
   - Output: Automated tests for each tool
   - Verification: Pass/fail results for each test

3. **Add safety limit tests** (60s)
   - Input: Concurrent/depth limit scenarios
   - Output: Tests that verify limits are enforced
   - Verification: Proper blocking when limits exceeded

---

**Total estimated time: ~13 minutes**
**All steps have clear inputs/outputs and 2-minute limits**
**Can be executed independently and verified deterministically**