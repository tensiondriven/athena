# Motion Detection Athena Agent Integration

This document explains how Motion detection containers integrate with the existing athena distributed agent system, providing a seamless bridge between motion detection capabilities and the central athena knowledge graph.

## Overview

The athena integration transforms the Motion detection container from a standalone system into a distributed agent that participates in the broader athena surveillance and intelligence ecosystem.

### Key Components

1. **Motion Detection Container** - Core motion detection using Motion daemon
2. **Athena Agent** - Python service that registers and communicates with athena system  
3. **MQTT Communication** - Message bus for agent discovery, commands, and events
4. **Central Athena System** - Collects events and builds knowledge graph

## Architecture Integration

### Athena Agent Model

The athena system uses a distributed agent architecture where:

- **Agents register** with capabilities to central collector
- **MQTT communication** handles agent discovery, commands, and events  
- **Agent registration** includes capabilities and heartbeat monitoring
- **Event streaming** feeds central knowledge graph

### Motion Agent Integration

```
┌─────────────────────────────────────────┐
│           Motion Container              │
├─────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────────┐   │
│  │   Motion    │  │  Athena Agent   │   │
│  │   Daemon    │  │                 │   │
│  │             │  │ - Registration  │   │
│  │ - Detection │  │ - Heartbeat     │   │
│  │ - Recording │  │ - Event Forward │   │
│  │ - Streaming │  │ - Command Resp  │   │
│  └─────────────┘  └─────────────────┘   │
│         │                   │           │
│         │              MQTT │           │
│         └─────── Events ────┘           │
└─────────────────────────────────────────┘
                      │
                   MQTT │
                      │
┌─────────────────────────────────────────┐
│         Central Athena System           │
├─────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────────┐   │
│  │   Agent     │  │   Knowledge     │   │
│  │ Discovery   │  │    Graph        │   │
│  │             │  │                 │   │
│  │ - Registry  │  │ - Event Store   │   │
│  │ - Heartbeat │  │ - Relationships │   │
│  │ - Commands  │  │ - Inference     │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
```

## MQTT Topic Structure

The athena integration uses a structured MQTT topic hierarchy:

### Agent Registration and Discovery
```
athena/agents/register              # Agent registration
athena/agents/discovery             # Discovery requests  
athena/agents/discovered            # Discovery responses
athena/agents/deregister            # Agent deregistration
```

### Agent Communication
```
athena/agents/{agent_id}/heartbeat    # Heartbeat messages
athena/agents/{agent_id}/commands     # Commands to agent
athena/agents/{agent_id}/responses    # Command responses
```

### Event Streaming
```
athena/events/motion/{agent_id}/detected       # Motion detected
athena/events/motion/{agent_id}/ended          # Motion ended
athena/events/motion/{agent_id}/recording      # Recording started
athena/events/motion/{agent_id}/image_saved    # Image captured
```

## Agent Capabilities

The Motion Athena Agent registers with these capabilities:

- **motion_detection** - Real-time motion detection
- **video_recording** - Video recording on motion events
- **image_capture** - Still image capture
- **event_streaming** - Real-time event notifications

## Implementation Files

### Core Integration Files

- **`motion_athena_agent.py`** - Main athena agent implementation
- **`Dockerfile.motion`** - Updated container with athena integration
- **`docker-compose.macos.yml`** - Development configuration for macOS M4

### Configuration Files

- **`mosquitto.conf`** - MQTT broker configuration for testing
- **`motion.conf`** - Motion detection configuration

## Local Development and Testing

### Prerequisites

1. **macOS M4 System** with Docker Desktop
2. **PTZ Pro Camera** or compatible USB camera
3. **Python 3.8+** for development
4. **MQTT Client Tools** for testing (mosquitto-clients)

### Quick Start

1. **Prepare the environment**:
   ```bash
   cd /Users/j/Code/mcp
   
   # Create data directories
   mkdir -p data/motion
   ```

2. **Start the services**:
   ```bash
   # Build and start all services
   docker-compose -f docker-compose.macos.yml up -d
   
   # View logs
   docker-compose -f docker-compose.macos.yml logs -f
   ```

3. **Verify camera access**:
   ```bash
   # Check if camera is detected
   ls -la /dev/video*
   
   # Test camera in container
   docker exec motion-athena-macos v4l2-ctl --device=/dev/video0 --list-formats-ext
   ```

4. **Test athena agent registration**:
   ```bash
   # Send discovery request
   mosquitto_pub -h localhost -t athena/agents/discovery -m '{"id":"test_discovery"}'
   
   # Listen for agent responses
   mosquitto_sub -h localhost -t 'athena/agents/+' -v
   ```

### Development Workflow

1. **Modify agent code**: Edit `motion_athena_agent.py`
2. **Restart container**: 
   ```bash
   docker-compose -f docker-compose.macos.yml restart motion-detector
   ```
3. **Check logs**: 
   ```bash
   docker logs motion-athena-macos
   ```
4. **Test MQTT communication**:
   ```bash
   # Monitor all athena topics
   mosquitto_sub -h localhost -t 'athena/#' -v
   ```

## Production Deployment

### Raspberry Pi Deployment

For production deployment on Raspberry Pi:

1. **Use the original docker-compose.motion.yml**:
   ```bash
   # Update environment variables
   export MQTT_BROKER=your-central-mqtt-broker
   export AGENT_ID=rpi_motion_agent_01
   export CAMERA_ID=rpi_cam_front_door
   
   # Deploy
   docker-compose -f docker-compose.motion.yml up -d
   ```

2. **Configure central MQTT broker**:
   - Point all agents to central MQTT broker
   - Set up authentication and SSL for security
   - Configure topic permissions

### Multi-Camera Deployment

For multiple cameras with athena integration:

```bash
# Camera 1 - Front Door
CAMERA_ID=front_door AGENT_ID=motion_agent_front docker-compose up -d

# Camera 2 - Back Yard  
CAMERA_ID=back_yard AGENT_ID=motion_agent_back docker-compose up -d

# Camera 3 - Garage
CAMERA_ID=garage AGENT_ID=motion_agent_garage docker-compose up -d
```

## Integration Testing

### Test Agent Registration

```bash
# 1. Start the motion container
docker-compose -f docker-compose.macos.yml up -d motion-detector

# 2. Monitor agent registration
mosquitto_sub -h localhost -t 'athena/agents/register' -v

# 3. Send discovery request
mosquitto_pub -h localhost -t athena/agents/discovery -m '{"id":"test_discovery"}'

# 4. Check for discovery response
mosquitto_sub -h localhost -t 'athena/agents/discovered' -v
```

### Test Event Forwarding

```bash
# 1. Monitor motion events
mosquitto_sub -h localhost -t 'athena/events/motion/+/+' -v

# 2. Trigger motion detection
# - Move in front of camera
# - Or simulate motion event

# 3. Verify events are forwarded to athena topics
```

### Test Agent Commands

```bash
# 1. Send status request to agent
mosquitto_pub -h localhost -t 'athena/agents/motion_agent_macos_ptz/commands' \
  -m '{"command":"get_status","id":"test_status"}'

# 2. Listen for response
mosquitto_sub -h localhost -t 'athena/agents/motion_agent_macos_ptz/responses' -v

# 3. Test capabilities request
mosquitto_pub -h localhost -t 'athena/agents/motion_agent_macos_ptz/commands' \
  -m '{"command":"get_capabilities","id":"test_capabilities"}'
```

## Monitoring and Debugging

### Container Logs

```bash
# View all logs
docker-compose -f docker-compose.macos.yml logs

# Motion daemon logs
docker exec motion-athena-macos tail -f /var/log/motion/motion.log

# Athena agent logs  
docker exec motion-athena-macos tail -f /var/log/motion/athena_agent.out.log

# Error logs
docker exec motion-athena-macos tail -f /var/log/motion/athena_agent.err.log
```

### MQTT Monitoring

```bash
# Monitor all athena traffic
mosquitto_sub -h localhost -t 'athena/#' -v

# Monitor specific agent
mosquitto_sub -h localhost -t 'athena/agents/motion_agent_macos_ptz/#' -v

# Monitor motion events only
mosquitto_sub -h localhost -t 'athena/events/motion/+/+' -v
```

### Health Checks

```bash
# Container health
docker ps --filter "name=motion-athena-macos"

# Service status inside container
docker exec motion-athena-macos supervisorctl status

# Camera access
docker exec motion-athena-macos v4l2-ctl --list-devices
```

## Integration with Existing Athena Components

### Athena-Capture Integration

The Motion Athena Agent complements the existing athena-capture system:

- **Motion Agent**: Provides distributed motion detection
- **Athena-Capture**: Provides PTZ control and screenshot capture
- **Combined**: Complete surveillance system with both detection and control

### Event Flow Integration

```
Motion Detection → Motion Agent → MQTT → Athena-Capture → Knowledge Graph
      ↓                                        ↓
   Recording                                PTZ Control
      ↓                                        ↓  
   File Events → Motion Agent → MQTT → Central System → Actions
```

### BigPlan Integration

The motion events can integrate with the existing BigPlan surveillance system:

1. **Motion events** trigger SAM analysis
2. **SAM analysis** feeds CLIP encoding
3. **CLIP vectors** enable semantic search
4. **Rules engine** processes events for actions

## Troubleshooting

### Common Issues

1. **Camera not detected**:
   ```bash
   # Check USB camera connection
   lsusb
   ls -la /dev/video*
   
   # Verify container has device access
   docker exec motion-athena-macos ls -la /dev/video*
   ```

2. **MQTT connection failed**:
   ```bash
   # Check MQTT broker is running
   docker ps | grep mosquitto
   
   # Test MQTT connectivity
   mosquitto_pub -h localhost -t test -m hello
   ```

3. **Agent not registering**:
   ```bash
   # Check athena agent logs
   docker logs motion-athena-macos
   
   # Verify MQTT topics
   mosquitto_sub -h localhost -t 'athena/agents/register' -v
   ```

4. **Motion daemon not starting**:
   ```bash
   # Check motion configuration
   docker exec motion-athena-macos motion -t -c /etc/motion/motion.conf
   
   # Check camera permissions
   docker exec motion-athena-macos v4l2-ctl --device=/dev/video0 --list-formats-ext
   ```

### Debug Mode

Enable debug logging by setting environment variables:

```yaml
environment:
  - LOG_LEVEL=DEBUG
  - PYTHONUNBUFFERED=1
```

## Next Steps

### Integration Enhancements

1. **Real-time event monitoring** - Implement proper motion event file monitoring
2. **Central agent management** - Build web interface for agent management
3. **Event aggregation** - Combine motion events with other athena data sources
4. **Automated responses** - Trigger PTZ movements based on motion detection

### Scaling Considerations

1. **Multi-node deployment** - Deploy agents across multiple Raspberry Pi devices
2. **Load balancing** - Distribute MQTT load across multiple brokers
3. **Event storage** - Integrate with time-series database for event history
4. **Monitoring** - Add Prometheus metrics and Grafana dashboards

## File Locations

All integration files are located in `/Users/j/Code/mcp/`:

- **`motion_athena_agent.py`** - Athena agent implementation
- **`Dockerfile.motion`** - Updated motion container
- **`docker-compose.macos.yml`** - macOS development configuration
- **`mosquitto.conf`** - MQTT broker configuration
- **`README_ATHENA_INTEGRATION.md`** - This documentation

## Support and Contributing

For issues, questions, or contributions:

1. **Check logs** first using the debugging procedures above
2. **Test MQTT connectivity** to isolate networking issues
3. **Verify camera access** to ensure hardware is properly configured
4. **Review athena agent registration** to confirm integration is working

The integration follows the established athena architecture patterns and can be extended to support additional motion detection features and integrations.