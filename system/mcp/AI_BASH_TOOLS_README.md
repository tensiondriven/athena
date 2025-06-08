# AI Bash Tools - AIX Optimized Interface

## FOR AI AGENTS: Critical Tool Selection Guide

### 🚨 AUDIT COMPLIANCE REQUIRED 🚨

**ALWAYS USE AUDIT_BASH FOR:**
- Remote server access (SSH commands)
- System modifications
- File operations that change state
- Any command that needs audit trails

**NEVER USE** built-in `Bash` tool for audit-sensitive operations.

## Available Tools

### `audit_bash` ⭐ RECOMMENDED
- **Purpose**: Audit-compliant shell execution
- **Usage**: `~/Code/mcp/audit_bash "your command here"`
- **Features**: Logging, safety controls, audit trails
- **When to use**: Always, unless doing simple read-only operations

### `audit_bash_mcp_server.py` 
- **Purpose**: MCP server version (if MCP connection available)
- **Usage**: Requires MCP server setup
- **Features**: Same as audit_bash but via MCP protocol

## AIX Design Notes

This naming convention optimizes for:
- **Immediate AI recognition** of audit requirements
- **Clear functional distinction** between tools
- **Reduced cognitive load** when choosing tools
- **Compliance by default** - audit tool is clearly marked

## Examples

```bash
# ✅ CORRECT - Using audit_bash for remote operations
~/Code/mcp/audit_bash "ssh j@llm 'docker ps'"

# ❌ WRONG - Built-in Bash lacks audit trail
# <invoke name="Bash"> for SSH operations

# ✅ CORRECT - Using audit_bash for system changes  
~/Code/mcp/audit_bash "docker run -d neo4j"
```

## Legacy Files
- `betterbash` - Original name (less AI-friendly)
- `betterbash_server.py` - Original MCP server (less AI-friendly)

Keep for compatibility but prefer `audit_*` versions for better AIX.