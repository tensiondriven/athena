#!/usr/bin/env python3
"""
Claude Spawner MCP Server
Allows spawning Claude instances with -p flag for multi-agent problem solving
"""

import asyncio
import json
import subprocess
import sys
import yaml
import os
import time
from typing import Any, Dict, List, Optional
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ClaudeSpawnerMCP:
    def __init__(self):
        self.name = "claude-spawner"
        self.version = "1.0.0"
        self.templates_dir = os.path.join(os.path.dirname(__file__), "agent-templates")
        self.templates = self.load_templates()
        
        # Safety limits
        self.max_spawn_depth = int(os.environ.get("CLAUDE_MAX_SPAWN_DEPTH", "2"))
        self.max_concurrent_spawns = int(os.environ.get("CLAUDE_MAX_CONCURRENT", "3"))
        self.max_ttl_minutes = int(os.environ.get("CLAUDE_MAX_TTL_MINUTES", "10"))
        self.max_rounds = int(os.environ.get("CLAUDE_MAX_ROUNDS", "5"))
        
        # Tracking
        self.active_spawns = {}  # spawn_id -> start_time
        self.spawn_depth_counter = 0
        
    def load_templates(self) -> Dict[str, Any]:
        """Load agent templates from YAML files"""
        templates = {}
        if os.path.exists(self.templates_dir):
            for filename in os.listdir(self.templates_dir):
                if filename.endswith('.yaml') or filename.endswith('.yml'):
                    try:
                        with open(os.path.join(self.templates_dir, filename), 'r') as f:
                            template_name = os.path.splitext(filename)[0]
                            templates[template_name] = yaml.safe_load(f)
                    except Exception as e:
                        logger.error(f"Error loading template {filename}: {e}")
        return templates
    
    def check_safety_limits(self, spawn_type: str = "generic") -> Optional[str]:
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
            return f"Maximum concurrent spawns ({self.max_concurrent_spawns}) reached. Active: {list(self.active_spawns.keys())}"
        
        # Check depth limit (use environment variable if set)
        current_depth = int(os.environ.get("CLAUDE_SPAWN_DEPTH", "0"))
        if current_depth >= self.max_spawn_depth:
            return f"Maximum spawn depth ({self.max_spawn_depth}) reached. Current depth: {current_depth}"
        
        # Check rounds limit (use environment variable if set)
        current_round = int(os.environ.get("CLAUDE_SPAWN_ROUND", "0"))
        if current_round >= self.max_rounds:
            return f"Maximum rounds ({self.max_rounds}) reached. Current round: {current_round}"
        
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
                    "description": "Spawn a Claude instance with a specific prompt to solve a problem",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "prompt": {
                                "type": "string",
                                "description": "The prompt/problem to give to the spawned Claude instance"
                            },
                            "working_directory": {
                                "type": "string",
                                "description": "Working directory for the spawned Claude instance (optional)"
                            },
                            "timeout": {
                                "type": "number",
                                "description": "Timeout in seconds (default: 300)",
                                "default": 300
                            },
                            "additional_args": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "Additional arguments to pass to claude command (optional)"
                            }
                        },
                        "required": ["prompt"]
                    }
                },
                {
                    "name": "execute_work_packet",
                    "description": "Execute a well-defined work packet with high-confidence agent",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "work_packet": {
                                "type": "object",
                                "description": "Work packet definition following the schema",
                                "properties": {
                                    "id": {"type": "string"},
                                    "title": {"type": "string"},
                                    "description": {"type": "string"},
                                    "context": {"type": "object"},
                                    "success_criteria": {"type": "array"},
                                    "constraints": {"type": "object"}
                                },
                                "required": ["id", "title", "description", "success_criteria"]
                            },
                            "template": {
                                "type": "string",
                                "description": "Agent template to use (default: work-packet-executor)",
                                "default": "work-packet-executor"
                            }
                        },
                        "required": ["work_packet"]
                    }
                },
                {
                    "name": "spawn_claude_with_mcp",
                    "description": "Spawn a Claude instance with MCP tools enabled",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "prompt": {
                                "type": "string",
                                "description": "The prompt/problem to give to the spawned Claude instance"
                            },
                            "mcp_servers": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "List of MCP servers to enable (e.g., ['claude-code'])"
                            },
                            "working_directory": {
                                "type": "string",
                                "description": "Working directory for the spawned Claude instance (optional)"
                            },
                            "timeout": {
                                "type": "number",
                                "description": "Timeout in seconds (default: 300)",
                                "default": 300
                            }
                        },
                        "required": ["prompt"]
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
        elif tool_name == "spawn_claude_with_mcp":
            return await self.spawn_claude_with_mcp(arguments)
        elif tool_name == "execute_work_packet":
            return await self.execute_work_packet(arguments)
        else:
            return {
                "error": {
                    "code": -32602,
                    "message": f"Unknown tool: {tool_name}"
                }
            }
    
    async def spawn_claude(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Spawn a Claude instance with the given prompt"""
        # Check safety limits first
        safety_error = self.check_safety_limits("claude")
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
        working_dir = args.get("working_directory")
        timeout = args.get("timeout", 300)
        additional_args = args.get("additional_args", [])
        
        # Generate spawn ID and register it
        spawn_id = f"claude_{int(time.time() * 1000)}"
        self.register_spawn(spawn_id)
        
        try:
            # Build the claude command with depth tracking
            current_depth = int(os.environ.get("CLAUDE_SPAWN_DEPTH", "0"))
            current_round = int(os.environ.get("CLAUDE_SPAWN_ROUND", "0"))
            
            cmd = ["claude", "-p", prompt] + additional_args
            
            # Set environment variables for the spawned process
            spawn_env = os.environ.copy()
            spawn_env["CLAUDE_SPAWN_DEPTH"] = str(current_depth + 1)
            spawn_env["CLAUDE_SPAWN_ROUND"] = str(current_round)
            spawn_env["CLAUDE_SPAWN_ID"] = spawn_id
            spawn_env["CLAUDE_SPAWN_TTL"] = str(int(time.time()) + (self.max_ttl_minutes * 60))
            
            logger.info(f"Spawning Claude {spawn_id} at depth {current_depth + 1}, round {current_round}")
            
            # Run the command
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=working_dir,
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
                            "text": f"Claude instance {spawn_id} completed successfully.\n\nSpawn Info: Depth {current_depth + 1}, Round {current_round}\n\nOutput:\n{stdout.decode('utf-8')}\n\nErrors (if any):\n{stderr.decode('utf-8')}"
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
                            "text": f"Claude instance {spawn_id} timed out after {timeout} seconds"
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
                        "text": f"Error spawning Claude instance {spawn_id}: {str(e)}"
                    }
                ]
            }
    
    async def spawn_claude_with_mcp(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Spawn a Claude instance with MCP servers enabled"""
        prompt = args["prompt"]
        mcp_servers = args.get("mcp_servers", [])
        working_dir = args.get("working_directory")
        timeout = args.get("timeout", 300)
        
        try:
            # Build the claude command with MCP
            cmd = ["claude", "-p", prompt]
            
            # Add MCP servers
            for server in mcp_servers:
                cmd.extend(["--mcp", server])
            
            logger.info(f"Spawning Claude with MCP: {' '.join(cmd)}")
            
            # Run the command
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=working_dir
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(), 
                    timeout=timeout
                )
                
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"Claude instance with MCP completed successfully.\n\nOutput:\n{stdout.decode('utf-8')}\n\nErrors (if any):\n{stderr.decode('utf-8')}"
                        }
                    ]
                }
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"Claude instance timed out after {timeout} seconds"
                        }
                    ]
                }
                
        except Exception as e:
            logger.error(f"Error spawning Claude with MCP: {e}")
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"Error spawning Claude instance with MCP: {str(e)}"
                    }
                ]
            }
    
    async def execute_work_packet(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a work packet using the configured template"""
        work_packet = args["work_packet"]
        template_name = args.get("template", "work-packet-executor")
        
        try:
            # Get the template
            if template_name not in self.templates:
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"Error: Template '{template_name}' not found. Available templates: {list(self.templates.keys())}"
                        }
                    ]
                }
            
            template = self.templates[template_name]
            
            # Build the context for the work packet
            context_files = []
            if "context" in work_packet and "files" in work_packet["context"]:
                files_config = work_packet["context"]["files"]
                
                # Read required files
                if "required" in files_config:
                    for file_info in files_config["required"]:
                        file_path = file_info["path"]
                        try:
                            with open(file_path, 'r') as f:
                                content = f.read()
                                context_files.append(f"=== {file_path} ===\n{content}\n")
                        except Exception as e:
                            return {
                                "content": [
                                    {
                                        "type": "text",
                                        "text": f"Error reading required file {file_path}: {e}"
                                    }
                                ]
                            }
                
                # Read reference files (non-blocking)
                if "reference" in files_config:
                    for file_info in files_config["reference"]:
                        file_path = file_info["path"]
                        try:
                            with open(file_path, 'r') as f:
                                content = f.read()[:2000]  # Limit reference file size
                                context_files.append(f"=== {file_path} (reference) ===\n{content}...\n")
                        except Exception as e:
                            logger.warning(f"Could not read reference file {file_path}: {e}")
            
            # Build the complete prompt
            system_prompt = template.get("system_prompt", "")
            
            work_packet_json = json.dumps(work_packet, indent=2)
            context_content = "\n".join(context_files)
            
            full_prompt = f"""{system_prompt}

=== WORK PACKET ===
{work_packet_json}

=== CONTEXT FILES ===
{context_content}

=== INSTRUCTIONS ===
Analyze the work packet above. If you meet ALL the execution criteria (90%+ confidence, <2min completion, clear requirements, etc.), proceed with the work. If not, return an ERROR status with specific missing requirements.

Follow the output format specified in the template exactly."""

            # Get working directory from work packet context
            working_dir = None
            if "context" in work_packet and "environment" in work_packet["context"]:
                working_dir = work_packet["context"]["environment"].get("working_directory")
            
            # Get time limit from constraints
            time_limit = 120  # default
            if "constraints" in work_packet and "time_limit" in work_packet["constraints"]:
                time_limit = work_packet["constraints"]["time_limit"]
            
            # Execute with claude-code MCP for file operations
            cmd = ["claude", "-p", full_prompt, "--mcp", "claude-code"]
            
            logger.info(f"Executing work packet {work_packet['id']} with time limit {time_limit}s")
            
            # Run the command
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=working_dir
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(), 
                    timeout=time_limit
                )
                
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"Work Packet Execution Results:\n\nWork Packet: {work_packet['id']}\nTitle: {work_packet['title']}\n\n=== AGENT OUTPUT ===\n{stdout.decode('utf-8')}\n\n=== ERRORS (if any) ===\n{stderr.decode('utf-8')}"
                        }
                    ]
                }
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"Work packet {work_packet['id']} timed out after {time_limit} seconds. This suggests the work packet was not properly scoped for quick execution."
                        }
                    ]
                }
                
        except Exception as e:
            logger.error(f"Error executing work packet: {e}")
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"Error executing work packet: {str(e)}"
                    }
                ]
            }

async def main():
    """Main function to run the MCP server"""
    server = ClaudeSpawnerMCP()
    
    logger.info("Claude Spawner MCP server starting...")
    
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