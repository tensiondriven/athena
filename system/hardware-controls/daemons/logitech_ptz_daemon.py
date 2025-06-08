#!/usr/bin/env python3
"""
Logitech PTZ Camera Daemon
Hardware-specific daemon for Logitech PTZ cameras.

This daemon handles all Logitech-specific operations:
- UVC PTZ control via webcam-ptz executable
- Camera discovery via system_profiler
- Screenshot capture via imagesnap
- Hardware quirks (killing cameracaptured process)

Commands:
  list                    - List available Logitech cameras
  pan --camera-id ID --value VALUE    - Pan camera 
  tilt --camera-id ID --value VALUE   - Tilt camera
  zoom --camera-id ID --value VALUE   - Zoom camera
  screenshot --camera-id ID [--value PATH] - Take screenshot
"""

import argparse
import asyncio
import json
import logging
import os
import subprocess
import sys
import tempfile
import base64
from datetime import datetime
from typing import Any, Dict, List, Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LogitechPTZDaemon:
    """Logitech PTZ Camera Hardware Daemon"""
    
    def __init__(self):
        self.webcam_ptz_path = "/Users/j/Code/logi-ptz/webcam-ptz/webcam-ptz"
        self.imagesnap_path = "/opt/homebrew/bin/imagesnap"
        
    async def list_cameras(self) -> Dict[str, Any]:
        """List all available Logitech PTZ cameras"""
        try:
            # Get USB camera info
            usb_result = await self._run_command([
                "system_profiler", "SPUSBDataType", "-json"
            ])
            
            # Get imagesnap camera list  
            imagesnap_result = await self._run_command([
                self.imagesnap_path, "-l"
            ])
            
            cameras = []
            
            # Parse USB devices for Logitech PTZ cameras
            if usb_result["success"]:
                try:
                    usb_data = json.loads(usb_result["stdout"])
                    for item in usb_data.get("SPUSBDataType", []):
                        for device in item.get("_items", []):
                            if self._is_logitech_ptz_camera(device):
                                camera_info = {
                                    "id": f"logitech-{device.get('serial_num', 'unknown')}",
                                    "name": device.get("_name", "Unknown Logitech Camera"),
                                    "vendor_id": device.get("vendor_id", ""),
                                    "product_id": device.get("product_id", ""),
                                    "serial": device.get("serial_num", ""),
                                    "type": "logitech-ptz",
                                    "supports": ["pan", "tilt", "zoom", "screenshot"]
                                }
                                cameras.append(camera_info)
                except json.JSONDecodeError as e:
                    logger.warning(f"Failed to parse USB data: {e}")
            
            # Cross-reference with imagesnap to ensure cameras are accessible
            accessible_cameras = []
            if imagesnap_result["success"]:
                imagesnap_cameras = [line.strip() for line in imagesnap_result["stdout"].split('\n') 
                                   if line.strip() and not line.startswith('Video Devices:')]
                
                for camera in cameras:
                    # Check if camera name appears in imagesnap output
                    if any(camera["name"] in imagesnap_cam for imagesnap_cam in imagesnap_cameras):
                        accessible_cameras.append(camera)
                    else:
                        logger.warning(f"Camera {camera['name']} found in USB but not accessible via imagesnap")
            
            return {
                "success": True,
                "cameras": accessible_cameras,
                "count": len(accessible_cameras)
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "cameras": [],
                "count": 0
            }
    
    def _is_logitech_ptz_camera(self, device: Dict) -> bool:
        """Check if USB device is a Logitech PTZ camera"""
        vendor_id = device.get("vendor_id", "")
        name = device.get("_name", "").lower()
        
        # Logitech vendor ID and PTZ camera patterns
        is_logitech = vendor_id == "0x046d"
        is_ptz_camera = any(keyword in name for keyword in ["ptz", "pro camera", "conference"])
        
        return is_logitech and is_ptz_camera
    
    async def control_camera(self, camera_id: str, command: str, value: str) -> Dict[str, Any]:
        """Control PTZ camera movement"""
        try:
            if not os.path.exists(self.webcam_ptz_path):
                return {
                    "success": False,
                    "error": f"webcam-ptz executable not found at {self.webcam_ptz_path}"
                }
            
            # Validate PTZ command
            valid_commands = ["pan", "tilt", "zoom"]
            if command not in valid_commands:
                return {
                    "success": False,
                    "error": f"Invalid PTZ command '{command}'. Must be one of: {valid_commands}"
                }
            
            # Validate value
            valid_values = ["min", "max", "middle"]
            if not (value in valid_values or self._is_valid_step_value(value)):
                return {
                    "success": False,
                    "error": f"Invalid value '{value}'. Must be min/max/middle or numeric steps (-1000 to 1000)"
                }
            
            # Kill blocking processes
            await self._kill_blocking_processes()
            
            # Execute PTZ command
            result = await self._run_command([
                self.webcam_ptz_path, command, value
            ], timeout=10)
            
            return {
                "success": result["success"],
                "command": command,
                "value": value,
                "camera_id": camera_id,
                "output": result.get("stdout", ""),
                "error": result.get("stderr", "") if not result["success"] else None
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "command": command,
                "value": value,
                "camera_id": camera_id
            }
    
    def _is_valid_step_value(self, value: str) -> bool:
        """Check if value is a valid step number"""
        try:
            steps = int(value)
            return -1000 <= steps <= 1000
        except ValueError:
            return False
    
    async def take_screenshot(self, camera_id: str, output_path: Optional[str] = None) -> Dict[str, Any]:
        """Take screenshot from camera"""
        try:
            if not os.path.exists(self.imagesnap_path):
                return {
                    "success": False,
                    "error": f"imagesnap not found at {self.imagesnap_path}"
                }
            
            # Generate output path if not provided
            if not output_path:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                output_path = f"/tmp/logitech_screenshot_{timestamp}.jpg"
            
            # Kill blocking processes
            await self._kill_blocking_processes()
            
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
        # For Logitech cameras, typically the name from system_profiler works
        # but we may need to map camera_id to the actual device name
        
        # Try to get current camera list and find the name
        cameras_result = await self.list_cameras()
        if cameras_result["success"]:
            for camera in cameras_result["cameras"]:
                if camera["id"] == camera_id:
                    return camera["name"]
        
        # Fallback for common Logitech camera names
        fallback_names = [
            "PTZ Pro Camera",
            "Logitech PTZ Pro Camera", 
            "Logi PTZ Pro Camera"
        ]
        
        # Test which name works with imagesnap
        for name in fallback_names:
            test_result = await self._run_command([
                self.imagesnap_path, "-l"
            ])
            if test_result["success"] and name in test_result["stdout"]:
                return name
        
        return None
    
    async def _kill_blocking_processes(self):
        """Kill processes that block camera access"""
        try:
            # Kill cameracaptured process that blocks camera access
            kill_result = await self._run_command([
                "sudo", "-S", "pkill", "cameracaptured"
            ], stdin_input="jjjj\n", timeout=5)
            
            if kill_result["success"]:
                logger.debug("Successfully killed blocking camera processes")
            else:
                logger.warning(f"Failed to kill blocking processes: {kill_result.get('stderr')}")
                
        except Exception as e:
            logger.warning(f"Error killing blocking processes: {e}")
    
    async def _run_command(self, command: List[str], timeout: int = 30, 
                          stdin_input: Optional[str] = None) -> Dict[str, Any]:
        """Execute command and return result"""
        try:
            process = await asyncio.create_subprocess_exec(
                *command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                stdin=asyncio.subprocess.PIPE if stdin_input else None
            )
            
            if stdin_input:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(input=stdin_input.encode()), timeout=timeout
                )
            else:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(), timeout=timeout
                )
            
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
    parser = argparse.ArgumentParser(description="Logitech PTZ Camera Daemon")
    parser.add_argument("command", choices=["list", "pan", "tilt", "zoom", "screenshot"],
                       help="Command to execute")
    parser.add_argument("--camera-id", help="Camera ID for control commands")
    parser.add_argument("--value", help="Value for control commands or output path for screenshot")
    
    args = parser.parse_args()
    
    daemon = LogitechPTZDaemon()
    
    try:
        if args.command == "list":
            result = await daemon.list_cameras()
        
        elif args.command in ["pan", "tilt", "zoom"]:
            if not args.camera_id or not args.value:
                result = {
                    "success": False,
                    "error": f"{args.command} command requires --camera-id and --value"
                }
            else:
                result = await daemon.control_camera(args.camera_id, args.command, args.value)
        
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