# Motion Detection Docker for Raspberry Pi

This Docker setup provides a complete motion detection system optimized for Raspberry Pi deployment with USB camera support and MQTT integration for distributed camera architectures.

## Features

- **Motion Detection**: Full-featured motion detection using the Motion daemon
- **USB Camera Support**: Optimized for USB cameras with V4L2 support
- **Web Interface**: Browser-based configuration and live streaming
- **MQTT Integration**: Real-time event notifications to central system
- **ARM Optimization**: Built specifically for Raspberry Pi ARM architecture
- **Health Monitoring**: Built-in health checks and logging
- **Persistent Storage**: Configurable storage for recordings and configuration

## Quick Start

### Prerequisites

1. Raspberry Pi with Docker installed
2. USB camera connected
3. MQTT broker accessible on your network

### Installation

1. **Clone or copy the files**:
   ```bash
   # Copy these files to your Raspberry Pi:
   # - Dockerfile.motion
   # - motion.conf  
   # - docker-compose.motion.yml
   ```

2. **Configure your environment**:
   Edit `docker-compose.motion.yml` and update:
   ```yaml
   environment:
     - CAMERA_ID=rpi_cam_01              # Unique ID for this camera
     - MQTT_BROKER=192.168.1.100         # Your MQTT broker IP
     - MQTT_PORT=1883
     - MQTT_USERNAME=your_username       # Optional
     - MQTT_PASSWORD=your_password       # Optional
   ```

3. **Build and start the container**:
   ```bash
   docker-compose -f docker-compose.motion.yml up -d
   ```

4. **Access the web interface**:
   - Configuration: `http://your-pi-ip:8080`
   - Live stream: `http://your-pi-ip:8081`

### Camera Setup

1. **Check connected cameras**:
   ```bash
   # List available video devices
   ls -la /dev/video*
   
   # Check camera capabilities
   v4l2-ctl --device=/dev/video0 --list-formats-ext
   ```

2. **Test camera before Docker**:
   ```bash
   # Simple camera test
   ffmpeg -f v4l2 -i /dev/video0 -frames 1 test.jpg
   ```

## Configuration

### Motion Configuration

The `motion.conf` file includes optimized settings for Raspberry Pi:

- **Resolution**: 640x480 @ 15fps (adjustable)
- **Motion Sensitivity**: Threshold of 1500 (adjustable)
- **Storage**: Images and videos saved to `/var/lib/motion`
- **Web Interface**: Port 8080 for configuration
- **Streaming**: Port 8081 for live video

### MQTT Events

The system sends MQTT notifications for:

- `motion_start`: When motion is first detected
- `motion_end`: When motion event ends
- `picture_saved`: When a motion picture is saved
- `movie_saved`: When a motion video is saved

#### MQTT Message Format

```json
{
  "camera_id": "rpi_cam_01",
  "event_type": "motion_start",
  "timestamp": "2024-01-15T10:30:00.123456",
  "filename": "/var/lib/motion/20240115_103000-01.jpg"
}
```

#### MQTT Topics

- `motion/{camera_id}/motion_start`
- `motion/{camera_id}/motion_end`  
- `motion/{camera_id}/picture_saved`
- `motion/{camera_id}/movie_saved`

## Deployment Options

### Single Camera Deployment

```bash
# Simple single camera setup
docker-compose -f docker-compose.motion.yml up -d
```

### Multiple Camera Deployment

For multiple cameras, create separate compose files or modify the existing one:

```yaml
# Example for second camera
motion-detector-cam2:
  # ... same configuration
  environment:
    - CAMERA_ID=rpi_cam_02
  devices:
    - /dev/video1:/dev/video0  # Map second camera to primary
  ports:
    - "8082:8080"  # Different web port
    - "8083:8081"  # Different stream port
```

### Production Deployment

1. **Use external volumes**:
   ```bash
   # Create external volumes for better management
   docker volume create motion_recordings
   docker volume create motion_config
   ```

2. **Configure log rotation**:
   ```bash
   # Add to crontab for log cleanup
   0 2 * * * docker exec motion-rpi-camera find /var/log/motion -name "*.log" -mtime +7 -delete
   ```

3. **Set up monitoring**:
   ```bash
   # Monitor container health
   docker ps --filter "label=motion.type=security-camera"
   ```

## Troubleshooting

### Camera Issues

1. **Camera not detected**:
   ```bash
   # Check USB connections
   lsusb
   
   # Check video devices
   ls -la /dev/video*
   
   # Test camera permissions
   docker run --rm --device=/dev/video0 -it arm64v8/debian:bullseye-slim v4l2-ctl --device=/dev/video0 --list-formats
   ```

2. **Permission denied**:
   ```bash
   # Add user to video group (host system)
   sudo usermod -a -G video $USER
   
   # Or run container with privileged mode (already enabled in compose)
   ```

### MQTT Issues

1. **Connection problems**:
   ```bash
   # Test MQTT connectivity from container
   docker exec motion-rpi-camera mosquitto_pub -h MQTT_BROKER -t test -m "hello"
   ```

2. **Check logs**:
   ```bash
   # View container logs
   docker logs motion-rpi-camera
   
   # View motion logs
   docker exec motion-rpi-camera tail -f /var/log/motion/motion.log
   ```

### Performance Issues

1. **High CPU usage**:
   - Reduce framerate in `motion.conf`
   - Lower resolution (width/height)
   - Increase motion threshold
   - Disable unnecessary features

2. **Storage issues**:
   - Configure automatic cleanup in `motion.conf`
   - Set `movie_max_files` and `picture_max_files`
   - Use external storage volume

## Security Considerations

1. **Network Security**:
   - Use MQTT authentication
   - Limit web interface access by IP
   - Use reverse proxy with SSL

2. **Container Security**:
   - Consider running without privileged mode if possible
   - Use specific device mounts instead of full privileged access
   - Regular security updates

## Integration Examples

### Home Assistant Integration

```yaml
# configuration.yaml
mqtt:
  sensor:
    - name: "Front Door Motion"
      state_topic: "motion/rpi_cam_01/motion_start"
      value_template: "{{ value_json.timestamp }}"
      device_class: motion
```

### Node-RED Integration

Use MQTT In nodes to receive motion events and trigger automations.

### Central Monitoring System

Create a central service that subscribes to all camera MQTT topics for unified monitoring and alerting.

## File Locations

- **Dockerfile**: `/Users/j/Code/mcp/Dockerfile.motion`
- **Configuration**: `/Users/j/Code/mcp/motion.conf`
- **Docker Compose**: `/Users/j/Code/mcp/docker-compose.motion.yml`
- **This README**: `/Users/j/Code/mcp/README_Motion_Docker.md`

## Support

For issues and questions:
1. Check container logs: `docker logs motion-rpi-camera`
2. Verify camera connectivity: `v4l2-ctl --list-devices`
3. Test MQTT connectivity: `mosquitto_pub -h broker -t test -m hello`
4. Review Motion documentation: https://motion-project.github.io/