#!/usr/bin/env python3
"""
Simple Claude Spawner MCP Server (No YAML dependencies)
Test version for verifying MCP protocol and spawning functionality
"""

import asyncio
import json
import subprocess
import sys
import os
import time
from typing import Any, Dict, List, Optional
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SimpleClaudeSpawnerMCP:
    def __init__(self):
        self.name = "claude-spawner-simple"
        self.version = "1.0.0"
        
        # Safety limits (hardcoded for now)
        self.max_spawn_depth = 2
        self.max_concurrent_spawns = 3
        self.max_ttl_minutes = 5
        
        # Tracking
        self.active_spawns = {}
        
    def check_safety_limits(self) -> Optional[str]:
        """Check if we can safely spawn a new instance"""
        current_time = time.time()
        
        # Clean up expired spawns
        expired = [
            spawn_id for spawn_id, start_time in self.active_spawns.items()
            if current_time - start_time > (self.max_ttl_minutes * 60)
        ]
        for spawn_id in expired:
            del self.active_spawns[spawn_id]
            logger.warning(f"Spawn {spawn_id} expired after {self.max_ttl_minutes} minutes")
        
        # Check concurrent limit
        if len(self.active_spawns) >= self.max_concurrent_spawns:
            return f"Maximum concurrent spawns ({self.max_concurrent_spawns}) reached"
        
        # Check depth limit
        current_depth = int(os.environ.get("CLAUDE_SPAWN_DEPTH", "0"))
        if current_depth >= self.max_spawn_depth:
            return f"Maximum spawn depth ({self.max_spawn_depth}) reached"
        
        return None
    
    def register_spawn(self, spawn_id: str) -> None:
        """Register a new spawn for tracking"""
        self.active_spawns[spawn_id] = time.time()
        logger.info(f"Registered spawn {spawn_id}. Active spawns: {len(self.active_spawns)}")
    
    def unregister_spawn(self, spawn_id: str) -> None:
        """Unregister a completed spawn"""
        if spawn_id in self.active_spawns:
            del self.active_spawns[spawn_id]
            logger.info(f"Unregistered spawn {spawn_id}. Active spawns: {len(self.active_spawns)}")
        
    async def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle incoming MCP requests"""
        try:
            method = request.get("method")
            params = request.get("params", {})
            
            if method == "tools/list":
                return await self.list_tools()
            elif method == "tools/call":
                return await self.call_tool(params)
            elif method == "initialize":
                return await self.initialize(params)
            else:
                return {
                    "error": {
                        "code": -32601,
                        "message": f"Method not found: {method}"
                    }
                }
        except Exception as e:
            logger.error(f"Error handling request: {e}")
            return {
                "error": {
                    "code": -32603,
                    "message": f"Internal error: {str(e)}"
                }
            }
    
    async def initialize(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Initialize the MCP server"""
        return {
            "protocolVersion": "2024-11-05",
            "capabilities": {
                "tools": {}
            },
            "serverInfo": {
                "name": self.name,
                "version": self.version
            }
        }
    
    async def list_tools(self) -> Dict[str, Any]:
        """List available tools"""
        return {
            "tools": [
                {
                    "name": "spawn_claude",
                    "description": "Spawn a Claude instance with a specific prompt",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "prompt": {
                                "type": "string",
                                "description": "The prompt to give to the spawned Claude instance"
                            },
                            "timeout": {
                                "type": "number",
                                "description": "Timeout in seconds (default: 120)",
                                "default": 120
                            }
                        },
                        "required": ["prompt"]
                    }
                },
                {
                    "name": "spawn_status",
                    "description": "Check status of spawning system and active spawns",
                    "inputSchema": {
                        "type": "object",
                        "properties": {}
                    }
                }
            ]
        }
    
    async def call_tool(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Call a specific tool"""
        tool_name = params.get("name")
        arguments = params.get("arguments", {})
        
        if tool_name == "spawn_claude":
            return await self.spawn_claude(arguments)
        elif tool_name == "spawn_status":
            return await self.spawn_status(arguments)
        else:
            return {
                "error": {
                    "code": -32602,
                    "message": f"Unknown tool: {tool_name}"
                }
            }
    
    async def spawn_status(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Check spawning system status"""
        return {
            "content": [
                {
                    "type": "text",
                    "text": f"""Spawning System Status:
- Active spawns: {len(self.active_spawns)}
- Max concurrent: {self.max_concurrent_spawns}
- Max depth: {self.max_spawn_depth}
- Max TTL: {self.max_ttl_minutes} minutes
- Current depth: {os.environ.get("CLAUDE_SPAWN_DEPTH", "0")}

Active spawn IDs: {list(self.active_spawns.keys())}"""
                }
            ]
        }
    
    async def spawn_claude(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Spawn a Claude instance with the given prompt"""
        # Check safety limits first
        safety_error = self.check_safety_limits()
        if safety_error:
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"SPAWN BLOCKED: {safety_error}"
                    }
                ]
            }
        
        prompt = args["prompt"]
        timeout = args.get("timeout", 120)
        
        # Generate spawn ID and register it
        spawn_id = f"claude_{int(time.time() * 1000)}"
        self.register_spawn(spawn_id)
        
        try:
            # Build the claude command with depth tracking
            current_depth = int(os.environ.get("CLAUDE_SPAWN_DEPTH", "0"))
            
            cmd = ["claude", "-p", prompt]
            
            # Set environment variables for the spawned process
            spawn_env = os.environ.copy()
            spawn_env["CLAUDE_SPAWN_DEPTH"] = str(current_depth + 1)
            spawn_env["CLAUDE_SPAWN_ID"] = spawn_id
            spawn_env["CLAUDE_SPAWN_TTL"] = str(int(time.time()) + (self.max_ttl_minutes * 60))
            
            logger.info(f"Spawning Claude {spawn_id} at depth {current_depth + 1}")
            
            # Run the command
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=spawn_env
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(), 
                    timeout=timeout
                )
                
                self.unregister_spawn(spawn_id)
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"""Claude Spawn {spawn_id} Completed
Depth: {current_depth + 1}
Duration: {timeout}s max

=== OUTPUT ===
{stdout.decode('utf-8')}

=== STDERR ===
{stderr.decode('utf-8')}"""
                        }
                    ]
                }
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                self.unregister_spawn(spawn_id)
                return {
                    "content": [
                        {
                            "type": "text", 
                            "text": f"Claude spawn {spawn_id} timed out after {timeout} seconds"
                        }
                    ]
                }
                
        except Exception as e:
            self.unregister_spawn(spawn_id)
            logger.error(f"Error spawning Claude: {e}")
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"Error spawning Claude {spawn_id}: {str(e)}"
                    }
                ]
            }

async def main():
    """Main function to run the MCP server"""
    server = SimpleClaudeSpawnerMCP()
    
    logger.info("Simple Claude Spawner MCP server starting...")
    
    # Read from stdin and write to stdout (MCP protocol)
    while True:
        try:
            line = await asyncio.get_event_loop().run_in_executor(None, sys.stdin.readline)
            if not line:
                break
                
            request = json.loads(line.strip())
            response = await server.handle_request(request)
            
            # Add request ID if present
            if "id" in request:
                response["id"] = request["id"]
            
            print(json.dumps(response))
            sys.stdout.flush()
            
        except json.JSONDecodeError:
            continue
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
            continue

if __name__ == "__main__":
    asyncio.run(main())