"""
REST API routes for PTZ camera control.

This module defines all the REST API endpoints for camera operations
including camera discovery, pan/tilt/zoom control, and screenshot capture.
"""

from flask import Blueprint, jsonify, request, send_file
import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)


def create_api_blueprint(camera_manager):
    """Create and configure the API blueprint."""
    
    api = Blueprint('api', __name__)
    
    @api.route('/cameras', methods=['GET'])
    def get_cameras():
        """Get list of available PTZ cameras."""
        try:
            cameras = camera_manager.get_cameras()
            return jsonify({
                'success': True,
                'cameras': cameras,
                'count': len(cameras)
            })
        except Exception as e:
            logger.error(f"Error getting cameras: {e}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
    @api.route('/cameras/refresh', methods=['POST'])
    def refresh_cameras():
        """Refresh the list of available cameras."""
        try:
            camera_manager.refresh_cameras()
            cameras = camera_manager.get_cameras()
            return jsonify({
                'success': True,
                'message': 'Cameras refreshed successfully',
                'cameras': cameras,
                'count': len(cameras)
            })
        except Exception as e:
            logger.error(f"Error refreshing cameras: {e}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
    @api.route('/cameras/<device_id>/pan-tilt', methods=['POST'])
    def control_pan_tilt(device_id):
        """Control camera pan and tilt."""
        try:
            data = request.get_json()
            if not data:
                return jsonify({
                    'success': False,
                    'error': 'JSON data required'
                }), 400
            
            pan = data.get('pan', 0)
            tilt = data.get('tilt', 0)
            
            # Validate input types
            try:
                pan = int(pan)
                tilt = int(tilt)
            except (ValueError, TypeError):
                return jsonify({
                    'success': False,
                    'error': 'Pan and tilt values must be integers'
                }), 400
            
            success, message = camera_manager.pan_tilt(device_id, pan, tilt)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': message,
                    'pan': pan,
                    'tilt': tilt
                })
            else:
                return jsonify({
                    'success': False,
                    'error': message
                }), 400
                
        except Exception as e:
            logger.error(f"Error controlling pan/tilt: {e}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
    @api.route('/cameras/<device_id>/zoom', methods=['POST'])
    def control_zoom(device_id):
        """Control camera zoom."""
        try:
            data = request.get_json()
            if not data:
                return jsonify({
                    'success': False,
                    'error': 'JSON data required'
                }), 400
            
            zoom_level = data.get('zoom', 0)
            
            # Validate input type
            try:
                zoom_level = int(zoom_level)
            except (ValueError, TypeError):
                return jsonify({
                    'success': False,
                    'error': 'Zoom level must be an integer'
                }), 400
            
            success, message = camera_manager.zoom(device_id, zoom_level)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': message,
                    'zoom': zoom_level
                })
            else:
                return jsonify({
                    'success': False,
                    'error': message
                }), 400
                
        except Exception as e:
            logger.error(f"Error controlling zoom: {e}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
    @api.route('/cameras/<device_id>/preset', methods=['POST'])
    def control_preset(device_id):
        """Set or recall camera preset."""
        try:
            data = request.get_json()
            if not data:
                return jsonify({
                    'success': False,
                    'error': 'JSON data required'
                }), 400
            
            preset_id = data.get('preset', 1)
            
            # Validate input type
            try:
                preset_id = int(preset_id)
            except (ValueError, TypeError):
                return jsonify({
                    'success': False,
                    'error': 'Preset ID must be an integer'
                }), 400
            
            success, message = camera_manager.preset(device_id, preset_id)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': message,
                    'preset': preset_id
                })
            else:
                return jsonify({
                    'success': False,
                    'error': message
                }), 400
                
        except Exception as e:
            logger.error(f"Error controlling preset: {e}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
    @api.route('/cameras/<device_id>/screenshot', methods=['POST'])
    def capture_screenshot(device_id):
        """Capture screenshot from camera."""
        try:
            data = request.get_json() if request.is_json else {}
            filename = data.get('filename') if data else None
            
            success, result = camera_manager.capture_screenshot(device_id, filename)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Screenshot captured successfully',
                    'filename': result
                })
            else:
                return jsonify({
                    'success': False,
                    'error': result
                }), 400
                
        except Exception as e:
            logger.error(f"Error capturing screenshot: {e}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
    @api.route('/cameras/<device_id>/screenshot/<filename>', methods=['GET'])
    def get_screenshot(device_id, filename):
        """Download captured screenshot."""
        try:
            # Construct the file path (assuming screenshots are saved in current directory)
            filepath = Path(filename)
            
            if not filepath.exists():
                return jsonify({
                    'success': False,
                    'error': 'Screenshot file not found'
                }), 404
            
            return send_file(filepath, as_attachment=True)
            
        except Exception as e:
            logger.error(f"Error serving screenshot: {e}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
    @api.route('/status', methods=['GET'])
    def get_status():
        """Get API status and health check."""
        try:
            cameras = camera_manager.get_cameras()
            return jsonify({
                'success': True,
                'status': 'running',
                'version': '1.0.0',
                'cameras_detected': len(cameras),
                'executable_path': camera_manager.executable_path
            })
        except Exception as e:
            logger.error(f"Error getting status: {e}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
    return api