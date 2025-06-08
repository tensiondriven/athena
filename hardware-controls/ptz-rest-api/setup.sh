#!/bin/bash

# PTZ REST API - Setup Script
# This script sets up the Python virtual environment and installs dependencies

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"

echo "=========================================="
echo "PTZ Camera Control REST API - Setup"
echo "=========================================="
echo "Project directory: $PROJECT_DIR"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    echo "Please install Python 3.8 or later."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "Python version: $PYTHON_VERSION"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists."
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Check if webcam-ptz executable exists and is executable
WEBCAM_PTZ="$PROJECT_DIR/webcam-ptz"
if [ ! -f "$WEBCAM_PTZ" ]; then
    echo "Warning: webcam-ptz executable not found at $WEBCAM_PTZ"
    echo "Please ensure the executable is copied to the project directory."
elif [ ! -x "$WEBCAM_PTZ" ]; then
    echo "Making webcam-ptz executable..."
    chmod +x "$WEBCAM_PTZ"
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p screenshots
mkdir -p logs

# Create environment file template
ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Creating environment file template..."
    cat > "$ENV_FILE" << EOF
# PTZ REST API Environment Configuration
# Copy this to .env.production for production settings

# Application settings
FLASK_ENV=development
SECRET_KEY=your-secret-key-here

# Camera settings
WEBCAM_PTZ_EXECUTABLE=./webcam-ptz
CAMERA_DETECTION_TIMEOUT=10
SCREENSHOT_DIRECTORY=./screenshots

# API settings
API_RATE_LIMIT=100 per minute
CORS_ORIGINS=*

# Logging settings
LOG_LEVEL=INFO
LOG_FILE=./logs/ptz-api.log
EOF
    echo "Environment file created at $ENV_FILE"
    echo "Please review and modify the settings as needed."
fi

echo "=========================================="
echo "Setup completed successfully!"
echo "=========================================="
echo
echo "To start the development server:"
echo "  1. Activate the virtual environment: source venv/bin/activate"
echo "  2. Run the application: python run.py"
echo "  3. Open your browser to: http://localhost:5000"
echo
echo "To run tests:"
echo "  pytest tests/"
echo
echo "For production deployment:"
echo "  gunicorn -w 4 -b 0.0.0.0:5000 'src.ptz_rest_api.main:create_app()'"
echo