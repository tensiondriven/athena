"""
Main application entry point for PTZ REST API service.

This module initializes and runs the REST API server for PTZ camera control.
"""

import logging
import sys
from pathlib import Path

# Add the project root to Python path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from src.ptz_rest_api.core.app import create_app
from src.ptz_rest_api.core.camera_manager import CameraManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('ptz-api.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)


def main():
    """Main application entry point."""
    try:
        logger.info("Starting PTZ REST API service...")
        
        # Initialize camera manager
        camera_manager = CameraManager()
        
        # Create Flask application
        app = create_app(camera_manager)
        
        # Run the application
        app.run(
            host='0.0.0.0',
            port=5000,
            debug=False,
            threaded=True
        )
        
    except Exception as e:
        logger.error(f"Failed to start PTZ REST API service: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()