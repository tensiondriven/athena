#!/usr/bin/env python3
"""
Generic Camera MCP Server
Hardware-agnostic camera control server that communicates with camera daemons.

This MCP server provides a standardized interface for camera operations
and delegates hardware-specific operations to dedicated camera daemons.

Architecture:
[MCP Server] → [Camera Management Service] → [Hardware Daemons]
   Generic         Discovery & Routing        Device Specific
"""

import asyncio
import json
import logging
import sys
import os
from typing import Any, Dict, List, Optional
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stderr)]
)
logger = logging.getLogger(__name__)

class CameraRegistry:
    """Manages discovered cameras and their daemon connections"""
    
    def __init__(self):
        self.cameras = {}
        self.daemons = {}
        
    async def discover_cameras(self) -> List[Dict[str, Any]]:
        """Discover all available cameras from registered daemons"""
        cameras = []
        
        # For now, we'll implement a simple file-based daemon discovery
        # Later this could be extended to network discovery, etc.
        daemon_configs = await self._load_daemon_configs()
        
        for daemon_config in daemon_configs:
            try:
                daemon_cameras = await self._query_daemon(daemon_config)
                cameras.extend(daemon_cameras)
            except Exception as e:
                logger.warning(f"Failed to query daemon {daemon_config.get('name')}: {e}")
        
        self.cameras = {cam["id"]: cam for cam in cameras}
        return cameras
    
    async def _load_daemon_configs(self) -> List[Dict[str, Any]]:
        """Load daemon configurations"""
        # Check for daemon configs in standard locations
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
        
        # Default fallback - look for Logitech daemon
        return [{
            "name": "logitech-ptz",
            "type": "executable",
            "path": "/Users/j/Code/logi-ptz/daemons/logitech_ptz_daemon.py",
            "supports": ["pan", "tilt", "zoom", "screenshot"]
        }]
    
    async def _query_daemon(self, daemon_config: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Query a daemon for its available cameras"""
        daemon_type = daemon_config.get("type", "executable")
        
        if daemon_type == "executable":
            return await self._query_executable_daemon(daemon_config)
        else:
            logger.warning(f"Unsupported daemon type: {daemon_type}")
            return []
    
    async def _query_executable_daemon(self, daemon_config: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Query an executable daemon for cameras"""
        daemon_path = daemon_config.get("path")
        if not daemon_path or not os.path.exists(daemon_path):
            logger.warning(f"Daemon executable not found: {daemon_path}")
            return []
        
        try:
            # Query daemon for available cameras
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
                    camera["supports"] = daemon_config.get("supports", [])
                
                return cameras
            else:
                logger.warning(f"Daemon query failed: {stderr.decode()}")
                return []
                
        except Exception as e:
            logger.warning(f"Failed to query daemon {daemon_path}: {e}")
            return []
    
    def get_camera(self, camera_id: str) -> Optional[Dict[str, Any]]:
        """Get camera info by ID"""
        return self.cameras.get(camera_id)

class GenericCameraManager:
    """Generic camera operations manager"""
    
    def __init__(self):
        self.registry = CameraRegistry()
    
    async def list_cameras(self) -> Dict[str, Any]:
        """List all available cameras"""
        try:
            cameras = await self.registry.discover_cameras()
            return {
                "success": True,
                "cameras": cameras,
                "count": len(cameras)
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "cameras": [],
                "count": 0
            }
    
    async def control_camera(self, camera_id: str, command: str, value: Optional[str] = None) -> Dict[str, Any]:
        """Send control command to specific camera"""
        try:
            camera = self.registry.get_camera(camera_id)
            if not camera:
                return {
                    "success": False,
                    "error": f"Camera not found: {camera_id}"
                }
            
            # Validate command is supported
            if command not in camera.get("supports", []):
                return {
                    "success": False,
                    "error": f"Command '{command}' not supported by camera {camera_id}"
                }
            
            # Delegate to daemon
            return await self._execute_daemon_command(camera, command, value)
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    async def take_screenshot(self, camera_id: str, output_path: Optional[str] = None) -> Dict[str, Any]:
        """Take screenshot from specific camera"""
        try:
            camera = self.registry.get_camera(camera_id)
            if not camera:
                return {
                    "success": False,
                    "error": f"Camera not found: {camera_id}"
                }
            
            if "screenshot" not in camera.get("supports", []):
                return {
                    "success": False,
                    "error": f"Screenshot not supported by camera {camera_id}"
                }
            
            # Delegate to daemon
            return await self._execute_daemon_command(camera, "screenshot", output_path)
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    async def _execute_daemon_command(self, camera: Dict[str, Any], command: str, value: Optional[str] = None) -> Dict[str, Any]:
        """Execute command via camera daemon"""
        daemon_path = camera.get("daemon_path")
        if not daemon_path:
            return {
                "success": False,
                "error": "No daemon path configured for camera"
            }
        
        try:
            # Build command for daemon
            cmd_args = ["python3", daemon_path, command, "--camera-id", camera["id"]]
            if value:
                cmd_args.extend(["--value", value])
            
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
                    "error": f"Daemon command failed: {stderr.decode()}"
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": f"Failed to execute daemon command: {e}"
            }

class CameraMCPServer:
    """Generic Camera MCP Server"""
    
    def __init__(self):
        self.camera_manager = GenericCameraManager()
    
    async def handle_mcp_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP protocol request"""
        try:
            method = request.get("method")
            params = request.get("params", {})
            
            if method == "list_cameras":
                result = await self.camera_manager.list_cameras()
                return {"result": result}
            
            elif method == "camera_control":
                camera_id = params.get("camera_id")
                command = params.get("command")
                value = params.get("value")
                
                if not camera_id or not command:
                    return {
                        "error": {"code": -1, "message": "camera_id and command are required"}
                    }
                
                result = await self.camera_manager.control_camera(camera_id, command, value)
                return {"result": result}
            
            elif method == "take_screenshot":
                camera_id = params.get("camera_id")
                output_path = params.get("output_path")
                
                if not camera_id:
                    return {
                        "error": {"code": -1, "message": "camera_id is required"}
                    }
                
                result = await self.camera_manager.take_screenshot(camera_id, output_path)
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
    """Main Camera MCP server loop"""
    server = CameraMCPServer()
    
    print("Generic Camera MCP Server starting...", file=sys.stderr)
    print("Available methods: list_cameras, camera_control, take_screenshot", file=sys.stderr)
    
    # Read JSON-RPC messages from stdin
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