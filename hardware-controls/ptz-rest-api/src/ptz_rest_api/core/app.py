"""
Flask application factory and configuration.

This module provides the Flask application setup and configuration
for the PTZ REST API service.
"""

from flask import Flask
from flask_cors import CORS

from ..api.routes import create_api_blueprint
from ..web.routes import create_web_blueprint


def create_app(camera_manager):
    """
    Create and configure the Flask application.
    
    Args:
        camera_manager: CameraManager instance for handling camera operations
        
    Returns:
        Flask: Configured Flask application instance
    """
    app = Flask(__name__, 
                static_folder='../../../static',
                template_folder='../../../templates')
    
    # Enable CORS for API endpoints
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    
    # Application configuration
    app.config.update(
        SECRET_KEY='ptz-camera-api-secret-key-change-in-production',
        JSON_SORT_KEYS=False,
        JSONIFY_PRETTYPRINT_REGULAR=True
    )
    
    # Register blueprints
    api_bp = create_api_blueprint(camera_manager)
    web_bp = create_web_blueprint(camera_manager)
    
    app.register_blueprint(api_bp, url_prefix='/api')
    app.register_blueprint(web_bp, url_prefix='/')
    
    return app