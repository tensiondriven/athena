# PTZ Camera Control REST API Documentation

## Base URL
All API endpoints are prefixed with `/api`

## Authentication
Currently no authentication is required. For production use, implement authentication as needed.

## Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {...}
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error description"
}
```

## Endpoints

### 1. System Status

#### GET /api/status
Get API status and health information.

**Response:**
```json
{
  "success": true,
  "status": "running",
  "version": "1.0.0",
  "cameras_detected": 2,
  "executable_path": "/path/to/webcam-ptz"
}
```

---

### 2. Camera Management

#### GET /api/cameras
List all detected PTZ cameras.

**Response:**
```json
{
  "success": true,
  "cameras": [
    {
      "id": "/dev/video0",
      "name": "Logitech PTZ Pro 2",
      "type": "Logitech PTZ Pro 2"
    }
  ],
  "count": 1
}
```

#### POST /api/cameras/refresh
Refresh the list of detected cameras.

**Response:**
```json
{
  "success": true,
  "message": "Cameras refreshed successfully",
  "cameras": [...],
  "count": 1
}
```

---

### 3. Camera Control

#### POST /api/cameras/{device_id}/pan-tilt
Control camera pan and tilt position.

**Parameters:**
- `device_id` (path): Camera device identifier

**Request Body:**
```json
{
  "pan": 50,    // Integer: -100 to 100
  "tilt": -30   // Integer: -100 to 100
}
```

**Response:**
```json
{
  "success": true,
  "message": "Pan/Tilt command executed successfully",
  "pan": 50,
  "tilt": -30
}
```

**Error Codes:**
- `400`: Invalid pan/tilt values (outside -100 to 100 range)
- `500`: Camera communication error

#### POST /api/cameras/{device_id}/zoom
Control camera zoom level.

**Parameters:**
- `device_id` (path): Camera device identifier

**Request Body:**
```json
{
  "zoom": 75    // Integer: 0 to 100
}
```

**Response:**
```json
{
  "success": true,
  "message": "Zoom command executed successfully",
  "zoom": 75
}
```

**Error Codes:**
- `400`: Invalid zoom value (outside 0 to 100 range)
- `500`: Camera communication error

#### POST /api/cameras/{device_id}/preset
Set or recall a camera preset position.

**Parameters:**
- `device_id` (path): Camera device identifier

**Request Body:**
```json
{
  "preset": 3   // Integer: 1 to 8
}
```

**Response:**
```json
{
  "success": true,
  "message": "Preset 3 command executed successfully",
  "preset": 3
}
```

**Error Codes:**
- `400`: Invalid preset ID (outside 1 to 8 range)
- `500`: Camera communication error

---

### 4. Screenshot Capture

#### POST /api/cameras/{device_id}/screenshot
Capture a screenshot from the camera.

**Parameters:**
- `device_id` (path): Camera device identifier

**Request Body (Optional):**
```json
{
  "filename": "custom_screenshot.jpg"  // Optional custom filename
}
```

**Response:**
```json
{
  "success": true,
  "message": "Screenshot captured successfully",
  "filename": "screenshot_device_20240606_142530.jpg"
}
```

**Error Codes:**
- `400`: Camera communication error
- `500`: File system error

#### GET /api/cameras/{device_id}/screenshot/{filename}
Download a captured screenshot.

**Parameters:**
- `device_id` (path): Camera device identifier
- `filename` (path): Screenshot filename

**Response:**
- **Success**: Binary image file download
- **404**: Screenshot file not found

---

## Error Handling

### HTTP Status Codes
- `200`: Success
- `400`: Bad Request (invalid parameters)
- `404`: Not Found (camera or file not found)
- `500`: Internal Server Error

### Common Error Messages
- `"JSON data required"`: Request missing JSON body
- `"Pan value must be between -100 and 100"`: Invalid pan parameter
- `"Tilt value must be between -100 and 100"`: Invalid tilt parameter
- `"Zoom level must be between 0 and 100"`: Invalid zoom parameter
- `"Preset ID must be between 1 and 8"`: Invalid preset parameter
- `"Camera {device_id} not found"`: Invalid device ID
- `"Screenshot file not found"`: Requested screenshot doesn't exist

---

## Rate Limiting
Default rate limit: 100 requests per minute per IP address.

Rate limit headers are included in responses:
- `X-RateLimit-Limit`: Maximum requests per window
- `X-RateLimit-Remaining`: Remaining requests in current window
- `X-RateLimit-Reset`: Time when rate limit resets

---

## CORS
Cross-Origin Resource Sharing (CORS) is enabled for all API endpoints with:
- Allowed Origins: `*` (configurable)
- Allowed Methods: `GET, POST, OPTIONS`
- Allowed Headers: `Content-Type, Authorization`

---

## Examples

### Using curl

```bash
# Get camera list
curl -X GET http://localhost:5000/api/cameras

# Control pan/tilt
curl -X POST http://localhost:5000/api/cameras/video0/pan-tilt \
  -H "Content-Type: application/json" \
  -d '{"pan": 50, "tilt": -30}'

# Set zoom
curl -X POST http://localhost:5000/api/cameras/video0/zoom \
  -H "Content-Type: application/json" \
  -d '{"zoom": 75}'

# Recall preset
curl -X POST http://localhost:5000/api/cameras/video0/preset \
  -H "Content-Type: application/json" \
  -d '{"preset": 3}'

# Capture screenshot
curl -X POST http://localhost:5000/api/cameras/video0/screenshot \
  -H "Content-Type: application/json" \
  -d '{}'

# Download screenshot
curl -X GET http://localhost:5000/api/cameras/video0/screenshot/screenshot.jpg \
  --output screenshot.jpg
```

### Using JavaScript (fetch)

```javascript
// Get cameras
const cameras = await fetch('/api/cameras').then(r => r.json());

// Control pan/tilt
const response = await fetch('/api/cameras/video0/pan-tilt', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ pan: 50, tilt: -30 })
});

// Capture screenshot
const screenshot = await fetch('/api/cameras/video0/screenshot', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({})
}).then(r => r.json());
```

### Using Python (requests)

```python
import requests

# Get cameras
response = requests.get('http://localhost:5000/api/cameras')
cameras = response.json()

# Control pan/tilt
response = requests.post(
    'http://localhost:5000/api/cameras/video0/pan-tilt',
    json={'pan': 50, 'tilt': -30}
)

# Capture screenshot
response = requests.post(
    'http://localhost:5000/api/cameras/video0/screenshot',
    json={}
)
```