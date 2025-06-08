"""
Camera management and control logic.

This module handles PTZ camera detection, control operations,
and interaction with the webcam-ptz executable.
"""

import logging
import subprocess
import json
import os
from pathlib import Path
from typing import List, Dict, Optional, Tuple

logger = logging.getLogger(__name__)


class CameraManager:
    """Manages PTZ camera detection and control operations."""
    
    def __init__(self):
        """Initialize camera manager."""
        self.executable_path = self._find_executable()
        self.detected_cameras = []
        self._detect_cameras()
    
    def _find_executable(self) -> str:
        """Find the webcam-ptz executable path."""
        # Try current directory first
        current_dir = Path(__file__).parent.parent.parent.parent
        exe_path = current_dir / "webcam-ptz"
        
        if exe_path.exists() and os.access(exe_path, os.X_OK):
            return str(exe_path)
        
        # Try system PATH
        try:
            result = subprocess.run(['which', 'webcam-ptz'], 
                                  capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            logger.warning("webcam-ptz executable not found in PATH")
            return str(exe_path)  # Return default path even if not found
    
    def _detect_cameras(self) -> None:
        """Detect available PTZ cameras."""
        try:
            logger.info("Detecting PTZ cameras...")
            result = subprocess.run([self.executable_path, '--list-devices'], 
                                  capture_output=True, text=True, check=True)
            
            # Parse the output to extract camera information
            cameras = []
            for line in result.stdout.split('\n'):
                line = line.strip()
                if line and 'Logitech' in line and 'PTZ' in line:
                    # Extract device ID and name
                    parts = line.split(':')
                    if len(parts) >= 2:
                        device_id = parts[0].strip()
                        name = parts[1].strip()
                        cameras.append({
                            'id': device_id,
                            'name': name,
                            'type': 'Logitech PTZ Pro 2'
                        })
            
            self.detected_cameras = cameras
            logger.info(f"Detected {len(cameras)} PTZ cameras")
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to detect cameras: {e}")
            self.detected_cameras = []
        except FileNotFoundError:
            logger.error(f"webcam-ptz executable not found at {self.executable_path}")
            self.detected_cameras = []
    
    def get_cameras(self) -> List[Dict]:
        """Get list of detected cameras."""
        return self.detected_cameras
    
    def pan_tilt(self, device_id: str, pan: int, tilt: int) -> Tuple[bool, str]:
        """
        Control camera pan and tilt.
        
        Args:
            device_id: Camera device identifier
            pan: Pan value (-100 to 100)
            tilt: Tilt value (-100 to 100)
            
        Returns:
            Tuple of (success, message)
        """
        try:
            # Validate parameters
            if not (-100 <= pan <= 100):
                return False, "Pan value must be between -100 and 100"
            if not (-100 <= tilt <= 100):
                return False, "Tilt value must be between -100 and 100"
            
            cmd = [self.executable_path, '--device', device_id, 
                   '--pan', str(pan), '--tilt', str(tilt)]
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info(f"Pan/Tilt command executed for device {device_id}: pan={pan}, tilt={tilt}")
            return True, "Pan/Tilt command executed successfully"
            
        except subprocess.CalledProcessError as e:
            error_msg = f"Failed to execute pan/tilt command: {e.stderr}"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Unexpected error during pan/tilt: {str(e)}"
            logger.error(error_msg)
            return False, error_msg
    
    def zoom(self, device_id: str, zoom_level: int) -> Tuple[bool, str]:
        """
        Control camera zoom.
        
        Args:
            device_id: Camera device identifier
            zoom_level: Zoom level (0 to 100)
            
        Returns:
            Tuple of (success, message)
        """
        try:
            # Validate parameters
            if not (0 <= zoom_level <= 100):
                return False, "Zoom level must be between 0 and 100"
            
            cmd = [self.executable_path, '--device', device_id, '--zoom', str(zoom_level)]
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info(f"Zoom command executed for device {device_id}: zoom={zoom_level}")
            return True, "Zoom command executed successfully"
            
        except subprocess.CalledProcessError as e:
            error_msg = f"Failed to execute zoom command: {e.stderr}"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Unexpected error during zoom: {str(e)}"
            logger.error(error_msg)
            return False, error_msg
    
    def preset(self, device_id: str, preset_id: int) -> Tuple[bool, str]:
        """
        Set or recall camera preset.
        
        Args:
            device_id: Camera device identifier
            preset_id: Preset identifier (1-8)
            
        Returns:
            Tuple of (success, message)
        """
        try:
            # Validate parameters
            if not (1 <= preset_id <= 8):
                return False, "Preset ID must be between 1 and 8"
            
            cmd = [self.executable_path, '--device', device_id, '--preset', str(preset_id)]
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info(f"Preset command executed for device {device_id}: preset={preset_id}")
            return True, f"Preset {preset_id} command executed successfully"
            
        except subprocess.CalledProcessError as e:
            error_msg = f"Failed to execute preset command: {e.stderr}"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Unexpected error during preset: {str(e)}"
            logger.error(error_msg)
            return False, error_msg
    
    def capture_screenshot(self, device_id: str, filename: Optional[str] = None) -> Tuple[bool, str]:
        """
        Capture screenshot from camera.
        
        Args:
            device_id: Camera device identifier
            filename: Optional filename for the screenshot
            
        Returns:
            Tuple of (success, message/filename)
        """
        try:
            if not filename:
                from datetime import datetime
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"screenshot_{device_id}_{timestamp}.jpg"
            
            cmd = [self.executable_path, '--device', device_id, '--screenshot', filename]
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info(f"Screenshot captured for device {device_id}: {filename}")
            return True, filename
            
        except subprocess.CalledProcessError as e:
            error_msg = f"Failed to capture screenshot: {e.stderr}"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Unexpected error during screenshot: {str(e)}"
            logger.error(error_msg)
            return False, error_msg
    
    def refresh_cameras(self) -> None:
        """Refresh the list of detected cameras."""
        self._detect_cameras()