#!/usr/bin/env python3
"""
USB Webcam Collector Daemon
Hardware-specific daemon for basic USB webcams (screenshot only, no PTZ).

This daemon handles non-PTZ USB webcams that only support screenshot capture.
Perfect for standard USB webcams, built-in laptop cameras, etc.

Commands:
  list                    - List available USB webcams
  screenshot --camera-id ID [--value PATH] - Take screenshot
"""

import argparse
import asyncio
import json
import logging
import os
import sys
import base64
from datetime import datetime
from typing import Any, Dict, List, Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class USBWebcamDaemon:
    """USB Webcam Hardware Daemon (Screenshot only)"""
    
    def __init__(self):
        self.imagesnap_path = "/opt/homebrew/bin/imagesnap"
        
    async def list_cameras(self) -> Dict[str, Any]:
        """List all available USB webcams (non-PTZ)"""
        try:
            # Get imagesnap camera list  
            imagesnap_result = await self._run_command([
                self.imagesnap_path, "-l"
            ])
            
            cameras = []
            
            if imagesnap_result["success"]:
                imagesnap_cameras = [line.strip() for line in imagesnap_result["stdout"].split('\n') 
                                   if line.strip() and not line.startswith('Video Devices:')]
                
                for i, camera_name in enumerate(imagesnap_cameras):
                    # Filter out PTZ cameras (they're handled by logitech daemon)
                    if not self._is_ptz_camera(camera_name):
                        camera_info = {
                            "id": f"usb-webcam-{i}",
                            "name": camera_name,
                            "type": "usb-webcam",
                            "supports": ["screenshot"]  # No PTZ support
                        }
                        cameras.append(camera_info)
            
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
    
    def _is_ptz_camera(self, camera_name: str) -> bool:
        """Check if camera is PTZ (should be handled by PTZ daemon)"""
        name_lower = camera_name.lower()
        ptz_indicators = ["ptz", "pro camera", "conference", "logitech ptz"]
        return any(indicator in name_lower for indicator in ptz_indicators)
    
    async def take_screenshot(self, camera_id: str, output_path: Optional[str] = None) -> Dict[str, Any]:
        """Take screenshot from USB webcam"""
        try:
            if not os.path.exists(self.imagesnap_path):
                return {
                    "success": False,
                    "error": f"imagesnap not found at {self.imagesnap_path}"
                }
            
            # Generate output path if not provided
            if not output_path:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                output_path = f"/tmp/usb_webcam_screenshot_{timestamp}.jpg"
            
            # Get camera name for imagesnap
            camera_name = await self._get_camera_name_for_imagesnap(camera_id)
            if not camera_name:
                return {
                    "success": False,
                    "error": f"Could not find camera name for ID: {camera_id}"
                }
            
            # Take screenshot
            result = await self._run_command([
                self.imagesnap_path, "-d", camera_name, output_path
            ], timeout=15)
            
            if result["success"] and os.path.exists(output_path):
                # Read and encode image
                try:
                    with open(output_path, "rb") as f:
                        image_data = base64.b64encode(f.read()).decode('utf-8')
                    
                    return {
                        "success": True,
                        "camera_id": camera_id,
                        "output_path": output_path,
                        "image_data": image_data,
                        "timestamp": datetime.now().isoformat()
                    }
                except Exception as e:
                    return {
                        "success": False,
                        "error": f"Failed to read screenshot file: {e}",
                        "output_path": output_path
                    }
            else:
                return {
                    "success": False,
                    "error": f"Screenshot failed: {result.get('stderr', 'Unknown error')}",
                    "output_path": output_path
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "camera_id": camera_id,
                "output_path": output_path or ""
            }
    
    async def _get_camera_name_for_imagesnap(self, camera_id: str) -> Optional[str]:
        """Get the camera name that imagesnap expects"""
        # Get current camera list and find the name
        cameras_result = await self.list_cameras()
        if cameras_result["success"]:
            for camera in cameras_result["cameras"]:
                if camera["id"] == camera_id:
                    return camera["name"]
        
        return None
    
    async def _run_command(self, command: List[str], timeout: int = 30) -> Dict[str, Any]:
        """Execute command and return result"""
        try:
            process = await asyncio.create_subprocess_exec(
                *command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=timeout)
            
            return {
                "success": process.returncode == 0,
                "stdout": stdout.decode('utf-8', errors='replace'),
                "stderr": stderr.decode('utf-8', errors='replace'),
                "exit_code": process.returncode
            }
            
        except asyncio.TimeoutError:
            process.kill()
            await process.wait()
            return {
                "success": False,
                "error": f"Command timed out after {timeout}s",
                "stdout": "",
                "stderr": "",
                "exit_code": -1
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "stdout": "",
                "stderr": "",
                "exit_code": -1
            }

async def main():
    """Main daemon entry point"""
    parser = argparse.ArgumentParser(description="USB Webcam Collector Daemon")
    parser.add_argument("command", choices=["list", "screenshot"],
                       help="Command to execute")
    parser.add_argument("--camera-id", help="Camera ID for screenshot command")
    parser.add_argument("--value", help="Output path for screenshot")
    
    args = parser.parse_args()
    
    daemon = USBWebcamDaemon()
    
    try:
        if args.command == "list":
            result = await daemon.list_cameras()
        
        elif args.command == "screenshot":
            if not args.camera_id:
                result = {
                    "success": False,
                    "error": "screenshot command requires --camera-id"
                }
            else:
                result = await daemon.take_screenshot(args.camera_id, args.value)
        
        else:
            result = {
                "success": False,
                "error": f"Unknown command: {args.command}"
            }
        
        # Output result as JSON
        print(json.dumps(result))
        
        # Exit with appropriate code
        sys.exit(0 if result.get("success", False) else 1)
        
    except Exception as e:
        error_result = {
            "success": False,
            "error": str(e)
        }
        print(json.dumps(error_result))
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())