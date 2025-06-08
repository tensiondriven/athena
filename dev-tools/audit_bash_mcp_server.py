#!/usr/bin/env python3
"""
Audit Bash MCP Server - Professional Shell Execution Interface
This is an MCP (Model Context Protocol) server that provides audit-compliant shell execution.

⚠️  IMPORTANT: This is NOT a CLI tool! ⚠️

This server is designed to be used via MCP protocol only. If you're seeing this message,
you're trying to run it directly from the command line, which is not supported.

To use this tool properly:

1. Register this server in your MCP-compatible client (like Claude Desktop)
2. Add to your client configuration:
   {
     "mcpServers": {
       "audit-bash": {
         "command": "python3",
         "args": ["/path/to/audit_bash_mcp_server.py"]
       }
     }
   }

3. Access via MCP tools in your client interface

For direct shell execution, use the companion CLI tool: ./audit_bash "command"

Features when used via MCP:
- Enhanced safety through command allowlisting  
- Comprehensive execution logging and audit trails
- Better error handling and timeout protection
- Asynchronous execution for improved performance
"""

import asyncio
import json
import logging
import subprocess
import sys
from typing import Any, Dict, List, Optional
from pathlib import Path
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def show_usage_info():
    """Show usage information when run directly"""
    print("""
🚨 AUDIT BASH MCP SERVER 🚨

This is an MCP (Model Context Protocol) server, not a CLI tool!

If you want to execute shell commands directly, use:
    ./audit_bash "your command here"

If you want to use this as an MCP server:

1. Add to your MCP client configuration:
   {
     "mcpServers": {
       "audit-bash": {
         "command": "python3",
         "args": ["{}"]
       }
     }
   }

2. Restart your MCP client
3. Access via MCP tools interface

Available MCP methods:
- execute_command: Run shell commands with audit logging
- list_allowed_commands: Show approved command list  
- get_command_log: Retrieve execution history

For AIX (AI Experience) optimization:
- Use 'audit_bash' for clear audit trail distinction
- Prefer this over built-in bash tools for compliance
- All executions are logged and safety-checked
""".format(os.path.abspath(__file__)))

class AuditBashMCPServer:
    def __init__(self):
        self.allowed_commands = self._load_allowed_commands()
        self.command_log = []
        
    def _load_allowed_commands(self) -> set:
        """Load allowed commands from file"""
        allowed_file = Path("allowed_commands.txt")
        if allowed_file.exists():
            with open(allowed_file) as f:
                return set(line.strip() for line in f if line.strip() and not line.startswith('#'))
        return {
            'python3', 'pip', 'git', 'curl', 'ls', 'cat', 'head', 'tail',
            'mkdir', 'cp', 'mv', 'rm', 'find', 'grep', 'which', 'say',
            'docker', 'docker-compose', 'nvidia-smi', 'ssh', 'scp',
            'mix', 'elixir', 'iex', 'node', 'npm', 'yarn'
        }
    
    def _is_command_allowed(self, command: str) -> bool:
        """Check if command is in allowlist"""
        base_cmd = command.split()[0] if command else ""
        return base_cmd in self.allowed_commands
    
    def _log_command(self, command: str, result: Dict[str, Any]):
        """Log command execution with audit trail"""
        import time
        log_entry = {
            "timestamp": time.time(),
            "iso_timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
            "command": command,
            "success": result.get("success", False),
            "exit_code": result.get("exit_code", -1),
            "audit_id": f"audit_{int(time.time())}_{len(self.command_log)}"
        }
        self.command_log.append(log_entry)
        
        # Also log to file for audit compliance
        audit_log_file = Path("audit_bash.log")
        try:
            with open(audit_log_file, "a") as f:
                f.write(f"{log_entry['iso_timestamp']} [{log_entry['audit_id']}] {command} -> exit_code={log_entry['exit_code']}\n")
        except Exception:
            pass  # Don't fail on logging issues
        
        # Keep last 1000 commands in memory
        if len(self.command_log) > 1000:
            self.command_log = self.command_log[-1000:]
    
    async def execute_command(self, command: str, timeout: int = 120) -> Dict[str, Any]:
        """Execute shell command with audit logging and safety checks"""
        if not self._is_command_allowed(command):
            result = {
                "success": False,
                "error": f"Command not allowed: {command.split()[0]}. Use list_allowed_commands to see approved commands.",
                "stdout": "",
                "stderr": "",
                "exit_code": -1
            }
            self._log_command(command, result)
            return result
        
        try:
            # Execute command with proper environment
            process = await asyncio.create_subprocess_shell(
                command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                limit=10*1024*1024,  # 10MB limit
                env=os.environ.copy()
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(), timeout=timeout
                )
                
                result = {
                    "success": process.returncode == 0,
                    "stdout": stdout.decode('utf-8', errors='replace'),
                    "stderr": stderr.decode('utf-8', errors='replace'),
                    "exit_code": process.returncode,
                    "command": command
                }
                
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                result = {
                    "success": False,
                    "error": f"Command timed out after {timeout}s",
                    "stdout": "",
                    "stderr": "",
                    "exit_code": -1,
                    "command": command
                }
                
        except Exception as e:
            result = {
                "success": False,
                "error": str(e),
                "stdout": "",
                "stderr": "",
                "exit_code": -1,
                "command": command
            }
        
        self._log_command(command, result)
        return result
    
    async def handle_mcp_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP protocol request"""
        try:
            method = request.get("method")
            params = request.get("params", {})
            
            if method == "tools/list":
                return {
                    "result": {
                        "tools": [
                            {
                                "name": "execute_command",
                                "description": "Execute shell commands with audit logging and safety controls",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "command": {"type": "string", "description": "Shell command to execute"},
                                        "timeout": {"type": "integer", "description": "Timeout in seconds (default 120)"}
                                    },
                                    "required": ["command"]
                                }
                            },
                            {
                                "name": "list_allowed_commands",
                                "description": "List all approved commands for security compliance",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "get_audit_log",
                                "description": "Retrieve command execution audit trail",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "limit": {"type": "integer", "description": "Number of recent entries (default 10)"}
                                    }
                                }
                            }
                        ]
                    }
                }
                
            elif method == "tools/call":
                tool_name = params.get("name")
                tool_args = params.get("arguments", {})
                
                if tool_name == "execute_command":
                    command = tool_args.get("command", "")
                    timeout = tool_args.get("timeout", 120)
                    
                    if not command:
                        return {
                            "result": {
                                "content": [{
                                    "type": "text",
                                    "text": "Error: No command provided"
                                }],
                                "isError": True
                            }
                        }
                    
                    result = await self.execute_command(command, timeout)
                    
                    # Format response for MCP
                    if result["success"]:
                        content_text = f"Command: {command}\nExit Code: {result['exit_code']}\n\nOutput:\n{result['stdout']}"
                        if result['stderr']:
                            content_text += f"\n\nErrors/Warnings:\n{result['stderr']}"
                    else:
                        content_text = f"Command Failed: {command}\nExit Code: {result['exit_code']}\nError: {result.get('error', 'Unknown error')}"
                        if result['stderr']:
                            content_text += f"\nStderr: {result['stderr']}"
                    
                    return {
                        "result": {
                            "content": [{
                                "type": "text",
                                "text": content_text
                            }],
                            "isError": not result["success"]
                        }
                    }
                    
                elif tool_name == "list_allowed_commands":
                    commands_text = "Audit-Approved Commands:\n" + "\n".join(f"- {cmd}" for cmd in sorted(self.allowed_commands))
                    return {
                        "result": {
                            "content": [{
                                "type": "text",
                                "text": commands_text
                            }]
                        }
                    }
                    
                elif tool_name == "get_audit_log":
                    limit = tool_args.get("limit", 10)
                    recent_log = self.command_log[-limit:] if self.command_log else []
                    
                    if not recent_log:
                        log_text = "No command executions in audit log"
                    else:
                        log_text = "Recent Command Audit Log:\n\n"
                        for entry in recent_log:
                            log_text += f"[{entry['audit_id']}] {entry['iso_timestamp']}\n"
                            log_text += f"Command: {entry['command']}\n"
                            log_text += f"Success: {entry['success']} (exit {entry['exit_code']})\n\n"
                    
                    return {
                        "result": {
                            "content": [{
                                "type": "text",
                                "text": log_text
                            }]
                        }
                    }
                
                else:
                    return {
                        "result": {
                            "content": [{
                                "type": "text",
                                "text": f"Unknown tool: {tool_name}"
                            }],
                            "isError": True
                        }
                    }
                    
            else:
                return {
                    "error": {"code": -32601, "message": f"Method not found: {method}"}
                }
                
        except Exception as e:
            return {
                "error": {"code": -1, "message": str(e)}
            }

async def main():
    """Main MCP server loop - only runs in MCP mode"""
    # Check if being run interactively (bad)
    if sys.stdin.isatty():
        show_usage_info()
        sys.exit(1)
    
    server = AuditBashMCPServer()
    
    logger.info("Audit Bash MCP Server starting...")
    logger.info(f"Loaded {len(server.allowed_commands)} allowed commands")
    
    # Handle MCP protocol messages
    while True:
        try:
            line = await asyncio.get_event_loop().run_in_executor(
                None, sys.stdin.readline
            )
            
            if not line:
                break
                
            request = json.loads(line.strip())
            response = await server.handle_mcp_request(request)
            
            # Add request ID if present
            if "id" in request:
                response["id"] = request["id"]
            
            print(json.dumps(response))
            sys.stdout.flush()
            
        except json.JSONDecodeError:
            error_response = {
                "error": {"code": -32700, "message": "Parse error"}
            }
            print(json.dumps(error_response))
            sys.stdout.flush()
            
        except Exception as e:
            error_response = {
                "error": {"code": -1, "message": str(e)}
            }
            print(json.dumps(error_response))
            sys.stdout.flush()

if __name__ == "__main__":
    asyncio.run(main())
