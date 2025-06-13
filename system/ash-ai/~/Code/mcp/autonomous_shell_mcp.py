#!/usr/bin/env python3
"""
Autonomous Shell MCP Server
Provides Claude with unrestricted shell access for autonomous execution.

This MCP server gives Claude the same shell capabilities as Docker Claude Code:
- Full command execution without human approval
- Complete environment access 
- Audit logging for transparency
- Tool call interface for MCP integration

⚠️  IMPORTANT: This is an MCP tool, not a CLI command! ⚠️

To use:
1. Register as MCP server in your client
2. Access via tool calls, not direct execution
3. Claude gets autonomous shell access with audit trails

For CLI commands, use: ./autonomous_shell "command"
"""

import asyncio
import json
import logging
import subprocess
import sys
import os
import time
from typing import Any, Dict
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def show_usage_info():
    """Show usage information when run directly from CLI"""
    print("""
🤖 AUTONOMOUS SHELL MCP SERVER 🤖

This MCP server provides Claude with unrestricted shell access for autonomous execution.

❌ This is NOT a CLI tool!

For CLI execution, use:
    ./autonomous_shell "your command here"

For MCP integration:
1. Add to your MCP client config:
   {
     "mcpServers": {
       "autonomous-shell": {
         "command": "python3",
         "args": ["{}"]
       }
     }
   }

2. Restart your MCP client
3. Claude can now execute shell commands autonomously via tool calls

Features:
✅ Unrestricted command execution (like Docker Claude Code)
✅ Complete environment access  
✅ Audit logging with timestamps
✅ No human approval required
✅ Full subprocess support

This gives Claude the same autonomous capabilities as the air-gapped Docker version.
""".format(os.path.abspath(__file__)))

class AutonomousShellMCP:
    def __init__(self):
        self.execution_log = []
        self.session_id = f"session_{int(time.time())}"
        self.setup_audit_logging()
        
    def setup_audit_logging(self):
        """Setup audit log file"""
        self.audit_log_path = Path("autonomous_shell_audit.log")
        try:
            with open(self.audit_log_path, "a") as f:
                f.write(f"\n--- NEW SESSION {self.session_id} STARTED AT {time.strftime('%Y-%m-%d %H:%M:%S')} ---\n")
        except Exception as e:
            logger.warning(f"Could not initialize audit log: {e}")
    
    def log_execution(self, command: str, result: Dict[str, Any]):
        """Log command execution with full audit trail"""
        timestamp = time.time()
        iso_timestamp = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(timestamp))
        
        log_entry = {
            "session_id": self.session_id,
            "timestamp": timestamp,
            "iso_timestamp": iso_timestamp,
            "command": command,
            "success": result.get("success", False),
            "exit_code": result.get("exit_code", -1),
            "stdout_length": len(result.get("stdout", "")),
            "stderr_length": len(result.get("stderr", "")),
            "execution_time_ms": result.get("execution_time_ms", 0),
            "audit_id": f"exec_{int(timestamp)}_{len(self.execution_log)}"
        }
        
        self.execution_log.append(log_entry)
        
        # Write to audit file
        try:
            with open(self.audit_log_path, "a") as f:
                f.write(f"[{log_entry['audit_id']}] {iso_timestamp}\n")
                f.write(f"Command: {command}\n")
                f.write(f"Exit Code: {log_entry['exit_code']}\n")
                f.write(f"Output Length: {log_entry['stdout_length']} chars\n")
                f.write(f"Error Length: {log_entry['stderr_length']} chars\n")
                f.write(f"Duration: {log_entry['execution_time_ms']}ms\n")
                f.write("---\n")
        except Exception as e:
            logger.warning(f"Could not write to audit log: {e}")
        
        # Keep last 1000 executions in memory
        if len(self.execution_log) > 1000:
            self.execution_log = self.execution_log[-1000:]
    
    async def execute_command(self, command: str, timeout: int = 300, working_directory: str = None) -> Dict[str, Any]:
        """Execute shell command with full autonomy - no restrictions"""
        start_time = time.time()
        
        try:
            # Set working directory if specified
            cwd = working_directory if working_directory and os.path.exists(working_directory) else None
            
            # Execute with full environment access
            process = await asyncio.create_subprocess_shell(
                command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=cwd,
                env=os.environ.copy(),
                limit=50*1024*1024  # 50MB limit for very large outputs
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(), timeout=timeout
                )
                
                execution_time = int((time.time() - start_time) * 1000)
                
                result = {
                    "success": process.returncode == 0,
                    "stdout": stdout.decode('utf-8', errors='replace'),
                    "stderr": stderr.decode('utf-8', errors='replace'),
                    "exit_code": process.returncode,
                    "command": command,
                    "execution_time_ms": execution_time,
                    "working_directory": cwd or os.getcwd()
                }
                
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                execution_time = int((time.time() - start_time) * 1000)
                
                result = {
                    "success": False,
                    "error": f"Command timed out after {timeout}s",
                    "stdout": "",
                    "stderr": f"TIMEOUT: Command killed after {timeout} seconds",
                    "exit_code": -1,
                    "command": command,
                    "execution_time_ms": execution_time,
                    "working_directory": cwd or os.getcwd()
                }
                
        except Exception as e:
            execution_time = int((time.time() - start_time) * 1000)
            result = {
                "success": False,
                "error": str(e),
                "stdout": "",
                "stderr": f"EXECUTION ERROR: {str(e)}",
                "exit_code": -1,
                "command": command,
                "execution_time_ms": execution_time,
                "working_directory": working_directory or os.getcwd()
            }
        
        self.log_execution(command, result)
        return result
    
    async def handle_mcp_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP protocol requests"""
        try:
            method = request.get("method")
            params = request.get("params", {})
            
            if method == "tools/list":
                return {
                    "result": {
                        "tools": [
                            {
                                "name": "shell_execute",
                                "description": "Execute shell commands with full autonomy. No restrictions - Claude has complete shell access like Docker Claude Code.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "command": {
                                            "type": "string", 
                                            "description": "Shell command to execute (any valid shell command)"
                                        },
                                        "timeout": {
                                            "type": "integer", 
                                            "description": "Timeout in seconds (default 300)"
                                        },
                                        "working_directory": {
                                            "type": "string",
                                            "description": "Working directory for command execution (optional)"
                                        }
                                    },
                                    "required": ["command"]
                                }
                            },
                            {
                                "name": "shell_audit_log",
                                "description": "View execution audit trail with command history",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "limit": {
                                            "type": "integer", 
                                            "description": "Number of recent executions to show (default 10)"
                                        }
                                    }
                                }
                            },
                            {
                                "name": "shell_session_info",
                                "description": "Get current shell session information and capabilities",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {}
                                }
                            }
                        ]
                    }
                }
                
            elif method == "tools/call":
                tool_name = params.get("name")
                tool_args = params.get("arguments", {})
                
                if tool_name == "shell_execute":
                    command = tool_args.get("command", "")
                    timeout = tool_args.get("timeout", 300)
                    working_directory = tool_args.get("working_directory")
                    
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
                    
                    result = await self.execute_command(command, timeout, working_directory)
                    
                    # Format comprehensive response
                    if result["success"]:
                        content_text = f"✅ Command executed successfully\n"
                        content_text += f"Command: {command}\n"
                        content_text += f"Exit Code: {result['exit_code']}\n"
                        content_text += f"Execution Time: {result['execution_time_ms']}ms\n"
                        content_text += f"Working Directory: {result['working_directory']}\n\n"
                        
                        if result['stdout']:
                            content_text += f"Output:\n{result['stdout']}\n"
                        
                        if result['stderr']:
                            content_text += f"\nWarnings/Info:\n{result['stderr']}"
                    else:
                        content_text = f"❌ Command failed\n"
                        content_text += f"Command: {command}\n"
                        content_text += f"Exit Code: {result['exit_code']}\n"
                        content_text += f"Execution Time: {result['execution_time_ms']}ms\n"
                        
                        if result.get('error'):
                            content_text += f"Error: {result['error']}\n"
                        
                        if result['stderr']:
                            content_text += f"Stderr: {result['stderr']}\n"
                        
                        if result['stdout']:
                            content_text += f"Stdout: {result['stdout']}"
                    
                    return {
                        "result": {
                            "content": [{
                                "type": "text",
                                "text": content_text
                            }],
                            "isError": not result["success"]
                        }
                    }
                    
                elif tool_name == "shell_audit_log":
                    limit = tool_args.get("limit", 10)
                    recent_log = self.execution_log[-limit:] if self.execution_log else []
                    
                    if not recent_log:
                        log_text = "No commands executed in this session yet."
                    else:
                        log_text = f"Recent Shell Execution Audit Log (Session: {self.session_id}):\n\n"
                        for entry in recent_log:
                            status = "✅" if entry['success'] else "❌"
                            log_text += f"{status} [{entry['audit_id']}] {entry['iso_timestamp']}\n"
                            log_text += f"   Command: {entry['command']}\n"
                            log_text += f"   Exit Code: {entry['exit_code']} | Duration: {entry['execution_time_ms']}ms\n"
                            log_text += f"   Output: {entry['stdout_length']} chars | Errors: {entry['stderr_length']} chars\n\n"
                    
                    return {
                        "result": {
                            "content": [{
                                "type": "text", 
                                "text": log_text
                            }]
                        }
                    }
                    
                elif tool_name == "shell_session_info":
                    info_text = f"🤖 Autonomous Shell Session Information\n\n"
                    info_text += f"Session ID: {self.session_id}\n"
                    info_text += f"Commands Executed: {len(self.execution_log)}\n"
                    info_text += f"Current Working Directory: {os.getcwd()}\n"
                    info_text += f"Environment Variables: {len(os.environ)}\n"
                    info_text += f"Audit Log: {self.audit_log_path}\n\n"
                    info_text += f"Capabilities:\n"
                    info_text += f"✅ Full shell command execution\n"
                    info_text += f"✅ File system access\n"
                    info_text += f"✅ Network access\n"
                    info_text += f"✅ Package installation\n"
                    info_text += f"✅ Process management\n"
                    info_text += f"✅ Environment modification\n"
                    info_text += f"✅ Autonomous operation (no human approval needed)\n\n"
                    info_text += f"This matches Docker Claude Code autonomous capabilities."
                    
                    return {
                        "result": {
                            "content": [{
                                "type": "text",
                                "text": info_text
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
            logger.error(f"Error handling MCP request: {e}")
            return {
                "error": {"code": -1, "message": str(e)}
            }

async def main():
    """Main MCP server loop"""
    # Check if being run interactively (show usage)
    if sys.stdin.isatty():
        show_usage_info()
        sys.exit(1)
    
    server = AutonomousShellMCP()
    
    logger.info(f"Autonomous Shell MCP Server starting (Session: {server.session_id})")
    logger.info("Providing Claude with unrestricted shell access + audit logging")
    
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
            logger.error(f"Unexpected error: {e}")
            error_response = {
                "error": {"code": -1, "message": str(e)}
            }
            print(json.dumps(error_response))
            sys.stdout.flush()

if __name__ == "__main__":
    asyncio.run(main())