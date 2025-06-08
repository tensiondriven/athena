# PTZ Camera Control REST API

A professional REST API service for controlling Logitech PTZ Pro 2 cameras with a clean web interface.

## Features

- **Camera Detection**: Automatically detect Logitech PTZ Pro 2 cameras on startup
- **REST API**: Complete REST endpoints for camera control
- **Web Interface**: Clean, responsive web interface for browser-based control
- **Pan/Tilt Control**: Precise pan (-100 to 100) and tilt (-100 to 100) control
- **Zoom Control**: Zoom control (0 to 100)
- **Preset Management**: 8 preset positions for quick camera positioning
- **Screenshot Capture**: Capture and download screenshots from cameras
- **Cross-Platform**: Works on Linux systems with USB camera support
- **Professional Structure**: Clean Python package structure with proper separation of concerns

## Project Structure

```
ptz-rest-api/
├── src/ptz_rest_api/           # Main application package
│   ├── __init__.py
│   ├── main.py                 # Application entry point
│   ├── api/                    # REST API endpoints
│   │   ├── __init__.py
│   │   └── routes.py
│   ├── core/                   # Core application logic
│   │   ├── __init__.py
│   │   ├── app.py              # Flask app factory
│   │   └── camera_manager.py   # Camera control logic
│   └── web/                    # Web interface
│       ├── __init__.py
│       └── routes.py
├── templates/                  # HTML templates
│   ├── base.html
│   ├── index.html
│   ├── camera_control.html
│   └── error.html
├── static/                     # Static assets
│   ├── css/style.css
│   └── js/app.js
├── config/                     # Configuration files
│   ├── __init__.py
│   └── app_config.py
├── tests/                      # Test suite
│   ├── __init__.py
│   └── test_api.py
├── docs/                       # Documentation
├── screenshots/                # Screenshot storage
├── logs/                       # Log files
├── webcam-ptz                  # PTZ control executable
├── requirements.txt            # Python dependencies
├── setup.sh                    # Setup script
├── run.py                      # Development server
└── README.md
```

## Quick Start

### 1. Setup

Run the setup script to configure the environment:

```bash
./setup.sh
```

This will:
- Create a Python virtual environment
- Install dependencies
- Set up directories
- Create environment configuration

### 2. Start Development Server

```bash
# Activate virtual environment
source venv/bin/activate

# Start the server
python run.py
```

The server will start on `http://localhost:5000`

### 3. Access the Interface

- **Web Interface**: `http://localhost:5000`
- **API Status**: `http://localhost:5000/api/status`
- **Camera List**: `http://localhost:5000/api/cameras`

## API Endpoints

### Camera Management

- `GET /api/cameras` - List all detected cameras
- `POST /api/cameras/refresh` - Refresh camera detection
- `GET /api/status` - API health check and status

### Camera Control

- `POST /api/cameras/{device_id}/pan-tilt` - Control pan and tilt
  ```json
  {"pan": 50, "tilt": -30}
  ```

- `POST /api/cameras/{device_id}/zoom` - Control zoom
  ```json
  {"zoom": 75}
  ```

- `POST /api/cameras/{device_id}/preset` - Set/recall preset
  ```json
  {"preset": 3}
  ```

- `POST /api/cameras/{device_id}/screenshot` - Capture screenshot
  ```json
  {"filename": "optional_filename.jpg"}
  ```

- `GET /api/cameras/{device_id}/screenshot/{filename}` - Download screenshot

### Response Format

All API responses follow this format:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {...}
}
```

Error responses:

```json
{
  "success": false,
  "error": "Error description"
}
```

## Web Interface Features

### Home Page
- Camera detection and listing
- Quick access to camera controls
- System information and API documentation

### Camera Control Page
- Interactive pan/tilt sliders
- Zoom control
- 8 preset buttons
- Screenshot capture
- Real-time status updates
- Keyboard shortcuts

### Keyboard Shortcuts
- `1-8`: Set presets
- `Arrow keys`: Pan/tilt control
- `Home`: Reset position

## Configuration

### Environment Variables

Create a `.env` file or set environment variables:

```bash
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
```

### Production Configuration

For production deployment:

1. Set `FLASK_ENV=production`
2. Use a strong `SECRET_KEY`
3. Configure proper logging
4. Use a WSGI server like gunicorn

## Production Deployment

### Using Gunicorn

```bash
# Install gunicorn
pip install gunicorn

# Start with 4 workers
gunicorn -w 4 -b 0.0.0.0:5000 'src.ptz_rest_api.main:create_app()'
```

### Linux Systemd Service

Create `/etc/systemd/system/ptz-api.service`:

```ini
[Unit]
Description=PTZ Camera Control REST API
After=network.target

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/opt/ptz-rest-api
Environment=PATH=/opt/ptz-rest-api/venv/bin
ExecStart=/opt/ptz-rest-api/venv/bin/gunicorn -w 4 -b 0.0.0.0:5000 'src.ptz_rest_api.main:create_app()'
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable ptz-api
sudo systemctl start ptz-api
```

### Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Development

### Running Tests

```bash
# Activate virtual environment
source venv/bin/activate

# Run tests
pytest tests/

# Run with coverage
pytest --cov=src tests/
```

### Project Structure Guidelines

- `src/ptz_rest_api/`: Main application code
- `api/`: REST API endpoints and logic
- `core/`: Core business logic and application setup
- `web/`: Web interface routes and handlers
- `config/`: Configuration management
- `tests/`: Test suite
- `templates/`: Jinja2 HTML templates
- `static/`: CSS, JavaScript, images

### Adding New Features

1. Add API endpoints in `src/ptz_rest_api/api/routes.py`
2. Add business logic in `src/ptz_rest_api/core/camera_manager.py`
3. Add web interface in `src/ptz_rest_api/web/routes.py`
4. Add templates in `templates/`
5. Add tests in `tests/`

## Requirements

### Hardware
- Logitech PTZ Pro 2 camera
- USB connection
- Linux system with USB support

### Software
- Python 3.8+
- USB camera drivers
- webcam-ptz executable (included)

### Python Dependencies
- Flask 2.3.3
- Flask-CORS 4.0.0
- gunicorn 21.2.0 (for production)
- pytest 7.4.2 (for testing)

## Troubleshooting

### Camera Not Detected

1. Check USB connection
2. Verify camera power
3. Check executable permissions:
   ```bash
   chmod +x webcam-ptz
   ```
4. Test executable directly:
   ```bash
   ./webcam-ptz --list-devices
   ```

### Permission Errors

Ensure the user running the service has:
- Execute permission on `webcam-ptz`
- Read/write access to screenshot directory
- USB device access (add to `video` group)

### Log Files

Check logs for detailed error information:
- Application logs: `logs/ptz-api.log`
- System logs: `journalctl -u ptz-api`

## Security Considerations

- Change default `SECRET_KEY` in production
- Use HTTPS in production
- Implement authentication if needed
- Restrict CORS origins in production
- Run with minimal privileges
- Keep dependencies updated

## License

This project is provided as-is for camera control purposes. Ensure compliance with your organization's security and usage policies.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review log files
3. Test the webcam-ptz executable directly
4. Verify camera connectivity and permissions