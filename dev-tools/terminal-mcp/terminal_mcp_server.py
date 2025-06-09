#!/usr/bin/env python3
"""
Terminal MCP Server - Provides terminal command execution via AppleScript
Exposes commands to send bash commands to iTerm with timeout and buffer reading

IMPORTANT: This is the PREFERRED way to run bash commands on macOS.
- DO NOT use the built-in Bash tool anymore
- This server uses AppleScript + iTerm for proper macOS integration
- Targets specific 'athena' terminal pane to avoid interference
- Includes timeout handling and buffer reading capabilities

PLATFORM REQUIREMENT: macOS only - requires iTerm2 and AppleScript support
"""

import asyncio
import json
import subprocess
import tempfile
import os
import platform
import sys
from pathlib import Path
from typing import Dict, Any, List

# Platform check
def check_platform():
    """Ensure we're running on macOS with iTerm2 support"""
    if platform.system() != "Darwin":
        print(json.dumps({
            "error": {
                "code": -32603,
                "message": "Terminal MCP Server requires macOS (Darwin). Current platform: " + platform.system()
            }
        }))
        sys.exit(1)
    
    # Check if iTerm2 is available
    try:
        subprocess.run(["osascript", "-e", "tell application \"iTerm2\" to get version"], 
                      capture_output=True, check=True, timeout=5)
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError):
        print(json.dumps({
            "error": {
                "code": -32603, 
                "message": "Terminal MCP Server requires iTerm2 to be installed and running"
            }
        }))
        sys.exit(1)

# MCP server boilerplate  
class McpServer:
    def __init__(self):
        self.tools = {
            "send_terminal_command": {
                "description": "Send a command to the 'athena' terminal pane in iTerm",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "command": {
                            "type": "string",
                            "description": "The bash command to execute"
                        },
                        "working_directory": {
                            "type": "string",
                            "description": "Directory to change to before executing command (optional)"
                        },
                        "timeout": {
                            "type": "integer", 
                            "description": "Timeout in seconds (default: 30)",
                            "default": 30
                        }
                    },
                    "required": ["command"]
                }
            },
            "read_terminal_buffer": {
                "description": "Read the current contents of the 'athena' terminal pane",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "lines": {
                            "type": "integer",
                            "description": "Number of lines to read (default: 50)",
                            "default": 50
                        }
                    }
                }
            },
            "send_command_and_read": {
                "description": "Send a command, wait for completion, then return terminal buffer",
                "parameters": {
                    "type": "object", 
                    "properties": {
                        "command": {
                            "type": "string",
                            "description": "The bash command to execute"
                        },
                        "working_directory": {
                            "type": "string",
                            "description": "Directory to change to before executing command (optional)"
                        },
                        "timeout": {
                            "type": "integer",
                            "description": "Timeout in seconds (default: 30)", 
                            "default": 30
                        },
                        "wait_for_completion": {
                            "type": "boolean",
                            "description": "Wait for command completion before reading output (default: true)",
                            "default": True
                        },
                        "max_wait_seconds": {
                            "type": "integer",
                            "description": "Maximum seconds to wait for completion (default: 10)",
                            "default": 10
                        }
                    },
                    "required": ["command"]
                }
            }
        }
        
        # Get paths to our AppleScript tools
        self.script_dir = Path(__file__).parent
        self.send_script = self.script_dir / "send-athena-command.applescript"
        self.read_script = self.script_dir / "read-athena-buffer.applescript"
        self.wait_script = self.script_dir / "wait-for-prompt.applescript"
    
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
            
            if tool_name == "send_terminal_command":
                return await self._send_command(arguments)
            elif tool_name == "read_terminal_buffer":
                return await self._read_buffer(arguments)
            elif tool_name == "send_command_and_read":
                return await self._send_and_read(arguments)
            else:
                return {"error": f"Unknown tool: {tool_name}"}
        
        return {"error": f"Unknown method: {method}"}
    
    async def _send_command(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Send command to athena terminal pane"""
        command = args.get("command", "")
        working_directory = args.get("working_directory")
        timeout = args.get("timeout", 30)
        
        if not command:
            return {"error": "Command is required"}
        
        try:
            # Use our AppleScript to send command to athena pane
            script_args = ["osascript", str(self.send_script), command]
            if working_directory:
                script_args.append(working_directory)
            
            result = subprocess.run(script_args, capture_output=True, text=True, timeout=timeout)
            
            if result.returncode == 0:
                display_cmd = f"{command[:50]}..." if len(command) > 50 else command
                wd_info = f" (in {working_directory})" if working_directory else ""
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"✅ Command sent to athena terminal{wd_info}: {display_cmd}"
                        }
                    ]
                }
            else:
                return {
                    "content": [
                        {
                            "type": "text", 
                            "text": f"❌ Failed to send command: {result.stderr}"
                        }
                    ]
                }
                
        except subprocess.TimeoutExpired:
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"⏰ Command timed out after {timeout} seconds"
                    }
                ]
            }
        except Exception as e:
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"❌ Error sending command: {str(e)}"
                    }
                ]
            }
    
    async def _read_buffer(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Read terminal buffer contents"""
        lines = args.get("lines", 50)
        
        try:
            # Use AppleScript to read terminal contents
            result = subprocess.run([
                "osascript",
                str(self.read_script)
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                buffer_content = result.stdout.strip()
                # Limit to requested number of lines
                buffer_lines = buffer_content.split('\n')[-lines:]
                limited_content = '\n'.join(buffer_lines)
                
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"📖 Terminal Buffer (last {len(buffer_lines)} lines):\n\n{limited_content}"
                        }
                    ]
                }
            else:
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"❌ Failed to read buffer: {result.stderr}"
                        }
                    ]
                }
                
        except Exception as e:
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"❌ Error reading buffer: {str(e)}"
                    }
                ]
            }
    
    async def _send_and_read(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Send command, wait for completion, then read output"""
        command = args.get("command", "")
        timeout = args.get("timeout", 30)
        wait_for_completion = args.get("wait_for_completion", True)
        max_wait_seconds = args.get("max_wait_seconds", 10)
        
        if not command:
            return {"error": "Command is required"}
        
        # First send the command
        send_args = {"command": command, "timeout": timeout}
        if "working_directory" in args:
            send_args["working_directory"] = args["working_directory"]
        send_result = await self._send_command(send_args)
        
        if "error" in send_result:
            return send_result
        
        # Wait for command to complete or timeout
        if wait_for_completion:
            try:
                wait_result = subprocess.run([
                    "osascript", str(self.wait_script), str(max_wait_seconds)
                ], capture_output=True, text=True, timeout=max_wait_seconds + 5)
                
                wait_status = wait_result.stdout.strip()
                if wait_status == "timeout":
                    status_msg = f"⏰ Command may still be running (waited {max_wait_seconds}s)"
                elif wait_status == "session_not_found":
                    status_msg = "❌ Athena session not found"
                else:
                    status_msg = f"✅ Command completed"
            except Exception:
                status_msg = "⚠️ Could not detect completion, showing current output"
        else:
            await asyncio.sleep(2)  # Brief wait
            status_msg = "📸 Current output (not waiting for completion)"
        
        # Then read the buffer
        read_result = await self._read_buffer({"lines": 50})
        
        display_cmd = f"{command[:50]}..." if len(command) > 50 else command
        
        # Combine results
        return {
            "content": [
                {
                    "type": "text",
                    "text": f"🚀 Executed: {display_cmd}\n{status_msg}\n\n{read_result['content'][0]['text']}"
                }
            ]
        }

# MCP Protocol Implementation
async def main():
    # Verify platform compatibility
    check_platform()
    
    server = McpServer()
    
    # Simple line-based MCP protocol over stdio
    while True:
        try:
            line = input()
            if not line:
                break
                
            request = json.loads(line)
            response = await server.handle_request(request)
            
            # Add MCP envelope
            mcp_response = {
                "jsonrpc": "2.0",
                "id": request.get("id"),
                "result": response
            }
            
            print(json.dumps(mcp_response))
            
        except EOFError:
            break
        except json.JSONDecodeError:
            error_response = {
                "jsonrpc": "2.0", 
                "id": None,
                "error": {"code": -32700, "message": "Parse error"}
            }
            print(json.dumps(error_response))
        except Exception as e:
            error_response = {
                "jsonrpc": "2.0",
                "id": request.get("id") if 'request' in locals() else None,
                "error": {"code": -32603, "message": f"Internal error: {str(e)}"}
            }
            print(json.dumps(error_response))

if __name__ == "__main__":
    asyncio.run(main())