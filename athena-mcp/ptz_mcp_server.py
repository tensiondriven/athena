#!/usr/bin/env python3
"""
PTZ MCP Server
Hardware-agnostic pan/tilt/zoom camera control server.

This MCP server ONLY handles PTZ operations and delegates to collector daemons
that support PTZ capabilities. Cameras without PTZ support are ignored.

Architecture:
[PTZ MCP Server] → [PTZ-capable Collector Daemons]
   pan/tilt/zoom       Logitech PTZ, ONVIF PTZ, etc.
"""

import asyncio
import json
import logging
import sys
import os
from typing import Any, Dict, List, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stderr)]
)
logger = logging.getLogger(__name__)

class PTZCameraRegistry:
    """Manages PTZ-capable cameras from collector daemons"""
    
    def __init__(self):
        self.ptz_cameras = {}
        
    async def discover_ptz_cameras(self) -> List[Dict[str, Any]]:
        """Discover PTZ-capable cameras only"""
        ptz_cameras = []
        
        daemon_configs = await self._load_daemon_configs()
        
        for daemon_config in daemon_configs:
            # Only query daemons that support PTZ operations
            if self._supports_ptz(daemon_config):
                try:
                    daemon_cameras = await self._query_daemon(daemon_config)
                    # Filter to only PTZ-capable cameras
                    ptz_capable = [cam for cam in daemon_cameras 
                                 if self._camera_supports_ptz(cam)]
                    ptz_cameras.extend(ptz_capable)
                except Exception as e:
                    logger.warning(f"Failed to query PTZ daemon {daemon_config.get('name')}: {e}")
        
        self.ptz_cameras = {cam["id"]: cam for cam in ptz_cameras}
        return ptz_cameras
    
    def _supports_ptz(self, daemon_config: Dict[str, Any]) -> bool:
        """Check if daemon supports PTZ operations"""
        supports = daemon_config.get("supports", [])
        ptz_commands = ["pan", "tilt", "zoom"]
        return any(cmd in supports for cmd in ptz_commands)
    
    def _camera_supports_ptz(self, camera: Dict[str, Any]) -> bool:
        """Check if individual camera supports PTZ"""
        supports = camera.get("supports", [])
        ptz_commands = ["pan", "tilt", "zoom"]
        return any(cmd in supports for cmd in ptz_commands)
    
    async def _load_daemon_configs(self) -> List[Dict[str, Any]]:
        """Load daemon configurations"""
        config_paths = [
            "/Users/j/Code/logi-ptz/daemons/config.json",
            "/Users/j/Code/mcp/camera_daemons.json"
        ]
        
        for config_path in config_paths:
            if os.path.exists(config_path):
                try:
                    with open(config_path, 'r') as f:
                        return json.load(f).get("daemons", [])
                except Exception as e:
                    logger.warning(f"Failed to load daemon config {config_path}: {e}")
        
        return []
    
    async def _query_daemon(self, daemon_config: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Query a daemon for its cameras"""
        daemon_path = daemon_config.get("path")
        if not daemon_path or not os.path.exists(daemon_path):
            return []
        
        try:
            process = await asyncio.create_subprocess_exec(
                "python3", daemon_path, "list",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=10)
            
            if process.returncode == 0:
                daemon_response = json.loads(stdout.decode())
                cameras = daemon_response.get("cameras", [])
                
                # Add daemon info to each camera
                for camera in cameras:
                    camera["daemon"] = daemon_config["name"]
                    camera["daemon_path"] = daemon_path
                
                return cameras
            else:
                return []
                
        except Exception as e:
            logger.warning(f"Failed to query daemon {daemon_path}: {e}")
            return []
    
    def get_ptz_camera(self, camera_id: str) -> Optional[Dict[str, Any]]:
        """Get PTZ camera info by ID"""
        return self.ptz_cameras.get(camera_id)

class PTZManager:
    """PTZ-specific camera operations manager"""
    
    def __init__(self):
        self.registry = PTZCameraRegistry()
    
    async def list_ptz_cameras(self) -> Dict[str, Any]:
        """List all PTZ-capable cameras"""
        try:
            cameras = await self.registry.discover_ptz_cameras()
            return {
                "success": True,
                "cameras": cameras,
                "count": len(cameras),
                "capabilities": ["pan", "tilt", "zoom"]
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "cameras": [],
                "count": 0
            }
    
    async def control_ptz(self, camera_id: str, command: str, value: str) -> Dict[str, Any]:
        """Execute PTZ control command"""
        try:
            # Validate PTZ command
            if command not in ["pan", "tilt", "zoom"]:
                return {
                    "success": False,
                    "error": f"Invalid PTZ command '{command}'. Must be pan, tilt, or zoom"
                }
            
            camera = self.registry.get_ptz_camera(camera_id)
            if not camera:
                return {
                    "success": False,
                    "error": f"PTZ camera not found: {camera_id}"
                }
            
            # Check if camera supports this specific command
            if command not in camera.get("supports", []):
                return {
                    "success": False,
                    "error": f"Camera {camera_id} does not support {command}"
                }
            
            # Delegate to daemon
            return await self._execute_ptz_command(camera, command, value)
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    async def _execute_ptz_command(self, camera: Dict[str, Any], command: str, value: str) -> Dict[str, Any]:
        """Execute PTZ command via daemon"""
        daemon_path = camera.get("daemon_path")
        if not daemon_path:
            return {
                "success": False,
                "error": "No daemon path configured for PTZ camera"
            }
        
        try:
            cmd_args = ["python3", daemon_path, command, "--camera-id", camera["id"], "--value", value]
            
            process = await asyncio.create_subprocess_exec(
                *cmd_args,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=30)
            
            if process.returncode == 0:
                return json.loads(stdout.decode())
            else:
                return {
                    "success": False,
                    "error": f"PTZ command failed: {stderr.decode()}"
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": f"Failed to execute PTZ command: {e}"
            }

class PTZMCPServer:
    """PTZ-only MCP Server"""
    
    def __init__(self):
        self.ptz_manager = PTZManager()
    
    async def handle_mcp_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP protocol request"""
        try:
            method = request.get("method")
            params = request.get("params", {})
            
            if method == "list_ptz_cameras":
                result = await self.ptz_manager.list_ptz_cameras()
                return {"result": result}
            
            elif method == "ptz_control":
                camera_id = params.get("camera_id")
                command = params.get("command")
                value = params.get("value")
                
                if not all([camera_id, command, value]):
                    return {
                        "error": {"code": -1, "message": "camera_id, command, and value are required"}
                    }
                
                result = await self.ptz_manager.control_ptz(camera_id, command, value)
                return {"result": result}
            
            else:
                return {
                    "error": {"code": -1, "message": f"Unknown method: {method}"}
                }
                
        except Exception as e:
            return {
                "error": {"code": -1, "message": str(e)}
            }

async def main():
    """Main PTZ MCP server loop"""
    server = PTZMCPServer()
    
    print("PTZ Camera MCP Server starting...", file=sys.stderr)
    print("Available methods: list_ptz_cameras, ptz_control", file=sys.stderr)
    
    while True:
        try:
            line = await asyncio.get_event_loop().run_in_executor(
                None, sys.stdin.readline
            )
            
            if not line:
                break
                
            request = json.loads(line.strip())
            response = await server.handle_mcp_request(request)
            
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