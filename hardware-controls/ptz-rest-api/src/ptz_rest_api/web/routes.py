"""
Web interface routes for PTZ camera control.

This module provides the web interface routes for browser-based
camera control and monitoring.
"""

from flask import Blueprint, render_template, jsonify
import logging

logger = logging.getLogger(__name__)


def create_web_blueprint(camera_manager):
    """Create and configure the web interface blueprint."""
    
    web = Blueprint('web', __name__)
    
    @web.route('/')
    def index():
        """Main web interface page."""
        try:
            cameras = camera_manager.get_cameras()
            return render_template('index.html', cameras=cameras)
        except Exception as e:
            logger.error(f"Error loading web interface: {e}")
            return render_template('error.html', error=str(e)), 500
    
    @web.route('/camera/<device_id>')
    def camera_control(device_id):
        """Camera control page for specific device."""
        try:
            cameras = camera_manager.get_cameras()
            camera = next((cam for cam in cameras if cam['id'] == device_id), None)
            
            if not camera:
                return render_template('error.html', 
                                     error=f'Camera {device_id} not found'), 404
            
            return render_template('camera_control.html', camera=camera)
        except Exception as e:
            logger.error(f"Error loading camera control: {e}")
            return render_template('error.html', error=str(e)), 500
    
    return web