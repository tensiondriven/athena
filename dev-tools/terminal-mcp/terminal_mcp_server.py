#!/usr/bin/env python3
"""
Terminal MCP Server - Cross-platform command execution via subprocess

Features:
- Execute bash commands with timeout and output capture
- Working directory support
- Returns both stdout and stderr
- Cross-platform compatibility
"""

import asyncio
import json
import subprocess
import os
import sys
from datetime import datetime
from typing import Dict, Any

# MCP server implementation
class McpServer:
    def __init__(self):
        self.tools = {
            "execute_command": {
                "description": "Execute a bash command and return output",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "command": {
                            "type": "string",
                            "description": "The bash command to execute"
                        },
                        "working_directory": {
                            "type": "string",
                            "description": "Directory to execute command in (optional)"
                        },
                        "timeout": {
                            "type": "integer", 
                            "description": "Timeout in seconds (default: 30)",
                            "default": 30
                        },
                        "shell": {
                            "type": "boolean",
                            "description": "Execute via shell (default: true)",
                            "default": True
                        }
                    },
                    "required": ["command"]
                }
            }
        }
    
    async def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP requests"""
        method = request.get("method")
        params = request.get("params", {})
        
        if method == "tools/list":
            return {
                "tools": [
                    {"name": name, **details} 
                    for name, details in self.tools.items()
                ]
            }
            
        elif method == "tools/call":
            tool_name = params.get("name")
            arguments = params.get("arguments", {})
            
            if tool_name == "execute_command":
                return await self._execute_command(arguments)
            else:
                return {"error": f"Unknown tool: {tool_name}"}
        
        return {"error": f"Unknown method: {method}"}
    
    async def _execute_command(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a bash command using subprocess"""
        command = args.get("command", "")
        working_directory = args.get("working_directory")
        timeout = args.get("timeout", 30)
        use_shell = args.get("shell", True)
        
        if not command:
            return {"error": "Command is required"}
        
        try:
            # Set up execution environment
            cwd = working_directory if working_directory else None
            if cwd and not os.path.exists(cwd):
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"❌ Working directory does not exist: {cwd}"
                        }
                    ]
                }
            
            # Execute command
            result = subprocess.run(
                command,
                shell=use_shell,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=cwd
            )
            
            # Format output
            output_parts = []
            display_cmd = f"{command[:50]}..." if len(command) > 50 else command
            wd_info = f" (in {working_directory})" if working_directory else ""
            
            if result.returncode == 0:
                status = f"✅ Command executed successfully{wd_info}: {display_cmd}"
            else:
                status = f"❌ Command failed (exit code {result.returncode}){wd_info}: {display_cmd}"
            
            output_parts.append(status)
            
            if result.stdout:
                output_parts.append(f"\n📤 STDOUT:\n{result.stdout}")
            
            if result.stderr:
                output_parts.append(f"\n📥 STDERR:\n{result.stderr}")
            
            if not result.stdout and not result.stderr:
                output_parts.append("\n(No output)")
            
            return {
                "content": [
                    {
                        "type": "text",
                        "text": "".join(output_parts)
                    }
                ]
            }
                
        except subprocess.TimeoutExpired:
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"⏰ Command timed out after {timeout} seconds: {command}"
                    }
                ]
            }
        except Exception as e:
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"❌ Error executing command: {str(e)}"
                    }
                ]
            }

# Logging setup
def setup_logging():
    """Set up logging to terminal-mcp.log"""
    log_file = os.path.join(os.path.dirname(__file__), "terminal-mcp.log")
    return log_file

def log_request(log_file: str, request_data: str):
    """Log incoming request with timestamp"""
    try:
        with open(log_file, "a", encoding="utf-8") as f:
            timestamp = datetime.now().isoformat()
            f.write(f"[{timestamp}] INPUT: {request_data}\n")
    except Exception:
        # Don't fail if logging fails
        pass

def log_response(log_file: str, response_data: str):
    """Log outgoing response with timestamp"""
    try:
        with open(log_file, "a", encoding="utf-8") as f:
            timestamp = datetime.now().isoformat()
            f.write(f"[{timestamp}] OUTPUT: {response_data}\n")
    except Exception:
        # Don't fail if logging fails
        pass

# MCP Protocol Implementation
async def main():
    server = McpServer()
    log_file = setup_logging()
    
    # Log startup
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.now().isoformat()}] Terminal MCP Server started\n")
    
    # Simple line-based MCP protocol over stdio
    while True:
        try:
            line = input()
            if not line:
                break
            
            # Log the input
            log_request(log_file, line)
                
            request = json.loads(line)
            response = await server.handle_request(request)
            
            # Add MCP envelope
            mcp_response = {
                "jsonrpc": "2.0",
                "id": request.get("id"),
                "result": response
            }
            
            response_json = json.dumps(mcp_response)
            
            # Log the output
            log_response(log_file, response_json)
            
            print(response_json)
            
        except EOFError:
            break
        except json.JSONDecodeError:
            error_response = {
                "jsonrpc": "2.0", 
                "id": None,
                "error": {"code": -32700, "message": "Parse error"}
            }
            error_json = json.dumps(error_response)
            log_response(log_file, error_json)
            print(error_json)
        except Exception as e:
            error_response = {
                "jsonrpc": "2.0",
                "id": request.get("id") if 'request' in locals() else None,
                "error": {"code": -32603, "message": f"Internal error: {str(e)}"}
            }
            error_json = json.dumps(error_response)
            log_response(log_file, error_json)
            print(error_json)

if __name__ == "__main__":
    asyncio.run(main())