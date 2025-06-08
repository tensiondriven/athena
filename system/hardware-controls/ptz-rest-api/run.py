#!/usr/bin/env python3
"""
PTZ REST API - Application Entry Point

This script starts the PTZ camera control REST API server.
Use this for development and testing. For production, use a WSGI server like gunicorn.
"""

import os
import sys
import logging
from pathlib import Path

# Add the project root to Python path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from src.ptz_rest_api.main import main


if __name__ == "__main__":
    # Set environment to development if not specified
    os.environ.setdefault('FLASK_ENV', 'development')
    
    print("=" * 60)
    print("PTZ Camera Control REST API")
    print("=" * 60)
    print(f"Project Root: {project_root}")
    print(f"Python Path: {sys.executable}")
    print(f"Environment: {os.environ.get('FLASK_ENV', 'development')}")
    print("=" * 60)
    
    try:
        main()
    except KeyboardInterrupt:
        print("\nShutting down PTZ REST API server...")
        sys.exit(0)
    except Exception as e:
        print(f"\nFailed to start server: {e}")
        sys.exit(1)