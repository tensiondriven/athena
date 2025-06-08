"""
API endpoint tests for PTZ REST API.

This module contains tests for the REST API endpoints.
"""

import pytest
import json
from unittest.mock import Mock, patch
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from src.ptz_rest_api.core.app import create_app
from src.ptz_rest_api.core.camera_manager import CameraManager


@pytest.fixture
def mock_camera_manager():
    """Create a mock camera manager for testing."""
    manager = Mock(spec=CameraManager)
    manager.get_cameras.return_value = [
        {
            'id': 'test_camera_1',
            'name': 'Test Logitech PTZ Pro 2',
            'type': 'Logitech PTZ Pro 2'
        }
    ]
    manager.pan_tilt.return_value = (True, "Pan/Tilt command executed successfully")
    manager.zoom.return_value = (True, "Zoom command executed successfully")
    manager.preset.return_value = (True, "Preset 1 command executed successfully")
    manager.capture_screenshot.return_value = (True, "test_screenshot.jpg")
    return manager


@pytest.fixture
def app(mock_camera_manager):
    """Create a test Flask application."""
    app = create_app(mock_camera_manager)
    app.config['TESTING'] = True
    return app


@pytest.fixture
def client(app):
    """Create a test client."""
    return app.test_client()


class TestAPIEndpoints:
    """Test class for API endpoints."""
    
    def test_get_cameras(self, client, mock_camera_manager):
        """Test GET /api/cameras endpoint."""
        response = client.get('/api/cameras')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['count'] == 1
        assert len(data['cameras']) == 1
        assert data['cameras'][0]['id'] == 'test_camera_1'
    
    def test_refresh_cameras(self, client, mock_camera_manager):
        """Test POST /api/cameras/refresh endpoint."""
        response = client.post('/api/cameras/refresh')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'message' in data
        mock_camera_manager.refresh_cameras.assert_called_once()
    
    def test_pan_tilt_control(self, client, mock_camera_manager):
        """Test POST /api/cameras/{id}/pan-tilt endpoint."""
        payload = {'pan': 50, 'tilt': -30}
        response = client.post('/api/cameras/test_camera_1/pan-tilt',
                             data=json.dumps(payload),
                             content_type='application/json')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['pan'] == 50
        assert data['tilt'] == -30
        
        mock_camera_manager.pan_tilt.assert_called_once_with('test_camera_1', 50, -30)
    
    def test_pan_tilt_invalid_values(self, client):
        """Test pan/tilt with invalid values."""
        payload = {'pan': 150, 'tilt': -200}  # Out of range
        response = client.post('/api/cameras/test_camera_1/pan-tilt',
                             data=json.dumps(payload),
                             content_type='application/json')
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_zoom_control(self, client, mock_camera_manager):
        """Test POST /api/cameras/{id}/zoom endpoint."""
        payload = {'zoom': 75}
        response = client.post('/api/cameras/test_camera_1/zoom',
                             data=json.dumps(payload),
                             content_type='application/json')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['zoom'] == 75
        
        mock_camera_manager.zoom.assert_called_once_with('test_camera_1', 75)
    
    def test_preset_control(self, client, mock_camera_manager):
        """Test POST /api/cameras/{id}/preset endpoint."""
        payload = {'preset': 3}
        response = client.post('/api/cameras/test_camera_1/preset',
                             data=json.dumps(payload),
                             content_type='application/json')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['preset'] == 3
        
        mock_camera_manager.preset.assert_called_once_with('test_camera_1', 3)
    
    def test_screenshot_capture(self, client, mock_camera_manager):
        """Test POST /api/cameras/{id}/screenshot endpoint."""
        response = client.post('/api/cameras/test_camera_1/screenshot',
                             data=json.dumps({}),
                             content_type='application/json')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'filename' in data
        
        mock_camera_manager.capture_screenshot.assert_called_once()
    
    def test_api_status(self, client, mock_camera_manager):
        """Test GET /api/status endpoint."""
        response = client.get('/api/status')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['status'] == 'running'
        assert 'version' in data
        assert 'cameras_detected' in data