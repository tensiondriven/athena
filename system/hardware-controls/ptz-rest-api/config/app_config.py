"""
Application configuration settings.

This module contains configuration classes for different environments
(development, production, testing).
"""

import os
from pathlib import Path


class Config:
    """Base configuration class."""
    
    # Application settings
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'ptz-camera-api-secret-key-change-in-production'
    JSON_SORT_KEYS = False
    JSONIFY_PRETTYPRINT_REGULAR = True
    
    # Camera settings
    WEBCAM_PTZ_EXECUTABLE = os.environ.get('WEBCAM_PTZ_EXECUTABLE') or './webcam-ptz'
    CAMERA_DETECTION_TIMEOUT = int(os.environ.get('CAMERA_DETECTION_TIMEOUT', '10'))
    SCREENSHOT_DIRECTORY = os.environ.get('SCREENSHOT_DIRECTORY') or './screenshots'
    
    # API settings
    API_RATE_LIMIT = os.environ.get('API_RATE_LIMIT') or '100 per minute'
    CORS_ORIGINS = os.environ.get('CORS_ORIGINS', '*').split(',')
    
    # Logging settings
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    LOG_FILE = os.environ.get('LOG_FILE', 'ptz-api.log')
    
    @staticmethod
    def init_app(app):
        """Initialize application with this configuration."""
        # Ensure screenshot directory exists
        screenshot_dir = Path(Config.SCREENSHOT_DIRECTORY)
        screenshot_dir.mkdir(exist_ok=True)


class DevelopmentConfig(Config):
    """Development configuration."""
    
    DEBUG = True
    LOG_LEVEL = 'DEBUG'
    
    # Development-specific settings
    CAMERA_DETECTION_TIMEOUT = 5  # Shorter timeout for development


class ProductionConfig(Config):
    """Production configuration."""
    
    DEBUG = False
    
    # Production-specific settings
    SECRET_KEY = os.environ.get('SECRET_KEY') or None
    
    @staticmethod
    def init_app(app):
        Config.init_app(app)
        
        # Production-specific initialization
        if not ProductionConfig.SECRET_KEY:
            raise ValueError("SECRET_KEY environment variable must be set in production")


class TestingConfig(Config):
    """Testing configuration."""
    
    TESTING = True
    DEBUG = True
    
    # Testing-specific settings
    SCREENSHOT_DIRECTORY = './test_screenshots'
    WEBCAM_PTZ_EXECUTABLE = './mock_webcam_ptz'  # Use mock for testing


# Configuration mapping
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}