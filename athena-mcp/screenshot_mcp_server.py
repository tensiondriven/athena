#!/usr/bin/env python3
"""
Screenshot MCP Server
Hardware-agnostic camera screenshot server.

This MCP server ONLY handles screenshot operations and delegates to collector daemons
that support screenshot capabilities. Works with both PTZ and non-PTZ cameras.

Architecture:
[Screenshot MCP Server] → [Screenshot-capable Collector Daemons]
   take_screenshot           All camera types (PTZ, USB webcam, IP cam, etc.)
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

class ScreenshotCameraRegistry:
    """Manages screenshot-capable cameras from collector daemons"""
    
    def __init__(self):
        self.screenshot_cameras = {}
        
    async def discover_screenshot_cameras(self) -> List[Dict[str, Any]]:
        """Discover screenshot-capable cameras"""
        screenshot_cameras = []
        
        daemon_configs = await self._load_daemon_configs()
        
        for daemon_config in daemon_configs:
            # Only query daemons that support screenshot operations
            if self._supports_screenshot(daemon_config):
                try:
                    daemon_cameras = await self._query_daemon(daemon_config)
                    # Filter to only screenshot-capable cameras
                    screenshot_capable = [cam for cam in daemon_cameras 
                                        if self._camera_supports_screenshot(cam)]
                    screenshot_cameras.extend(screenshot_capable)
                except Exception as e:
                    logger.warning(f"Failed to query screenshot daemon {daemon_config.get('name')}: {e}")
        
        self.screenshot_cameras = {cam["id"]: cam for cam in screenshot_cameras}
        return screenshot_cameras
    
    def _supports_screenshot(self, daemon_config: Dict[str, Any]) -> bool:
        """Check if daemon supports screenshot operations"""
        supports = daemon_config.get("supports", [])
        return "screenshot" in supports
    
    def _camera_supports_screenshot(self, camera: Dict[str, Any]) -> bool:
        """Check if individual camera supports screenshot"""
        supports = camera.get("supports", [])
        return "screenshot" in supports
    
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
    
    def get_screenshot_camera(self, camera_id: str) -> Optional[Dict[str, Any]]:
        """Get screenshot camera info by ID"""
        return self.screenshot_cameras.get(camera_id)

class ScreenshotManager:
    """Screenshot-specific camera operations manager"""
    
    def __init__(self):
        self.registry = ScreenshotCameraRegistry()
    
    async def list_screenshot_cameras(self) -> Dict[str, Any]:
        """List all screenshot-capable cameras"""
        try:
            cameras = await self.registry.discover_screenshot_cameras()
            return {
                "success": True,
                "cameras": cameras,
                "count": len(cameras),
                "capabilities": ["screenshot"]
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "cameras": [],
                "count": 0
            }
    
    async def take_screenshot(self, camera_id: str, output_path: Optional[str] = None) -> Dict[str, Any]:
        """Take screenshot from camera"""
        try:
            camera = self.registry.get_screenshot_camera(camera_id)
            if not camera:
                return {
                    "success": False,
                    "error": f"Screenshot camera not found: {camera_id}"
                }
            
            # Check if camera supports screenshot
            if "screenshot" not in camera.get("supports", []):
                return {
                    "success": False,
                    "error": f"Camera {camera_id} does not support screenshot"
                }
            
            # Delegate to daemon
            return await self._execute_screenshot_command(camera, output_path)
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    async def _execute_screenshot_command(self, camera: Dict[str, Any], output_path: Optional[str]) -> Dict[str, Any]:
        """Execute screenshot command via daemon"""
        daemon_path = camera.get("daemon_path")
        if not daemon_path:
            return {
                "success": False,
                "error": "No daemon path configured for screenshot camera"
            }
        
        try:
            cmd_args = ["python3", daemon_path, "screenshot", "--camera-id", camera["id"]]
            if output_path:
                cmd_args.extend(["--value", output_path])
            
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
                    "error": f"Screenshot command failed: {stderr.decode()}"
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": f"Failed to execute screenshot command: {e}"
            }

class ScreenshotMCPServer:
    """Screenshot-only MCP Server"""
    
    def __init__(self):
        self.screenshot_manager = ScreenshotManager()
    
    async def handle_mcp_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP protocol request"""
        try:
            method = request.get("method")
            params = request.get("params", {})
            
            if method == "list_screenshot_cameras":
                result = await self.screenshot_manager.list_screenshot_cameras()
                return {"result": result}
            
            elif method == "take_screenshot":
                camera_id = params.get("camera_id")
                output_path = params.get("output_path")
                
                if not camera_id:
                    return {
                        "error": {"code": -1, "message": "camera_id is required"}
                    }
                
                result = await self.screenshot_manager.take_screenshot(camera_id, output_path)
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
    """Main Screenshot MCP server loop"""
    server = ScreenshotMCPServer()
    
    print("Screenshot Camera MCP Server starting...", file=sys.stderr)
    print("Available methods: list_screenshot_cameras, take_screenshot", file=sys.stderr)
    
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