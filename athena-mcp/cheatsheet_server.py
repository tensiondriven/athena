#!/usr/bin/env python3
"""
AI Collaboration Cheatsheet MCP Server
Simple context injection server that provides the AI collaboration protocols.

This server exposes the cheatsheet content for automatic context injection
in Claude sessions, ensuring consistent collaboration patterns.

Usage: Register as MCP server to get instant access to collaboration protocols
"""

import asyncio
import json
import logging
import sys
from pathlib import Path
from typing import Any, Dict

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CheatsheetServer:
    def __init__(self):
        self.cheatsheet_path = Path("/Users/j/Code/AI_CHEATSHEET.md")
        
    async def get_cheatsheet(self) -> Dict[str, Any]:
        """Return the AI collaboration cheatsheet content"""
        try:
            if not self.cheatsheet_path.exists():
                return {
                    "content": "Cheatsheet file not found at /Users/j/Code/AI_CHEATSHEET.md",
                    "success": False
                }
            
            with open(self.cheatsheet_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            return {
                "content": content,
                "success": True,
                "file_path": str(self.cheatsheet_path)
            }
            
        except Exception as e:
            logger.error(f"Error reading cheatsheet: {e}")
            return {
                "content": f"Error reading cheatsheet: {str(e)}",
                "success": False
            }

    async def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP requests"""
        method = request.get("method")
        
        if method == "tools/list":
            return {
                "tools": [
                    {
                        "name": "get_cheatsheet",
                        "description": "Get the AI collaboration cheatsheet content for context injection",
                        "inputSchema": {
                            "type": "object",
                            "properties": {},
                            "required": []
                        }
                    }
                ]
            }
        
        elif method == "tools/call":
            tool_name = request.get("params", {}).get("name")
            
            if tool_name == "get_cheatsheet":
                result = await self.get_cheatsheet()
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": result["content"]
                        }
                    ]
                }
            else:
                return {"error": f"Unknown tool: {tool_name}"}
        
        elif method == "initialize":
            return {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {}
                }
            }
        
        else:
            return {"error": f"Unknown method: {method}"}

async def main():
    """Main server loop"""
    server = CheatsheetServer()
    
    while True:
        try:
            line = await asyncio.get_event_loop().run_in_executor(None, sys.stdin.readline)
            if not line:
                break
                
            request = json.loads(line.strip())
            response = await server.handle_request(request)
            
            print(json.dumps(response))
            sys.stdout.flush()
            
        except json.JSONDecodeError:
            print(json.dumps({"error": "Invalid JSON"}))
            sys.stdout.flush()
        except Exception as e:
            logger.error(f"Server error: {e}")
            print(json.dumps({"error": str(e)}))
            sys.stdout.flush()

if __name__ == "__main__":
    asyncio.run(main())