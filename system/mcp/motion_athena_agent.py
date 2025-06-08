#!/usr/bin/env python3
"""
Motion Athena Agent
Integrates Motion detection container with the athena distributed agent system.

This agent runs inside the Motion container and:
1. Registers as an athena agent with motion detection capabilities
2. Sends heartbeat messages to maintain agent status
3. Forwards motion events to the central athena event system
4. Responds to agent discovery and status requests

Architecture Integration:
- Registers to athena/agents/register with capabilities
- Sends heartbeats to athena/agents/{agent_id}/heartbeat
- Forwards motion events to athena/events/motion/{agent_id}/{event_type}
- Listens for commands on athena/agents/{agent_id}/commands
"""

import asyncio
import json
import logging
import signal
import sys
import os
import time
import uuid
from typing import Dict, Any, Optional
from datetime import datetime, timezone
import threading

try:
    import paho.mqtt.client as mqtt
except ImportError:
    print("Error: paho-mqtt not installed. Run: pip install paho-mqtt", file=sys.stderr)
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MotionAthenaAgent:
    """Athena agent for Motion detection container"""
    
    def __init__(self, 
                 mqtt_broker: str = "localhost",
                 mqtt_port: int = 1883,
                 mqtt_username: str = None,
                 mqtt_password: str = None,
                 agent_id: str = None,
                 camera_id: str = "motion_cam_01"):
        """
        Initialize the Motion Athena Agent
        
        Args:
            mqtt_broker: MQTT broker hostname/IP
            mqtt_port: MQTT broker port
            mqtt_username: MQTT username (optional)
            mqtt_password: MQTT password (optional)
            agent_id: Unique agent identifier (auto-generated if None)
            camera_id: Camera identifier for motion events
        """
        self.mqtt_broker = mqtt_broker
        self.mqtt_port = mqtt_port
        self.mqtt_username = mqtt_username
        self.mqtt_password = mqtt_password
        self.agent_id = agent_id or f"motion_agent_{uuid.uuid4().hex[:8]}"
        self.camera_id = camera_id
        
        # Agent configuration
        self.agent_capabilities = [
            "motion_detection",
            "video_recording", 
            "image_capture",
            "event_streaming"
        ]
        
        self.agent_metadata = {
            "type": "motion_detector",
            "version": "1.0.0",
            "camera_id": self.camera_id,
            "location": os.environ.get("AGENT_LOCATION", "unknown"),
            "description": "Motion detection and video recording agent"
        }
        
        # MQTT client
        self.client = None
        self.connected = False
        self.running = False
        
        # Registration and heartbeat
        self.registered = False
        self.heartbeat_interval = 30  # seconds
        self.heartbeat_task = None
        
        # Motion event monitoring
        self.motion_monitor_task = None
        self.last_motion_check = time.time()
        
    def setup_mqtt(self):
        """Setup MQTT client and callbacks"""
        self.client = mqtt.Client(client_id=f"athena_agent_{self.agent_id}")
        
        # Set credentials if provided
        if self.mqtt_username and self.mqtt_password:
            self.client.username_pw_set(self.mqtt_username, self.mqtt_password)
        
        # Set callbacks
        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message
        self.client.on_disconnect = self._on_disconnect
        
    def _on_connect(self, client, userdata, flags, rc):
        """Callback for MQTT connection"""
        if rc == 0:
            logger.info(f"Connected to athena MQTT broker at {self.mqtt_broker}:{self.mqtt_port}")
            self.connected = True
            
            # Subscribe to agent command topic
            command_topic = f"athena/agents/{self.agent_id}/commands"
            client.subscribe(command_topic)
            logger.info(f"Subscribed to {command_topic}")
            
            # Subscribe to discovery requests
            client.subscribe("athena/agents/discovery")
            
            # Register as athena agent
            self._register_agent()
            
        else:
            logger.error(f"Failed to connect to athena MQTT broker: {rc}")
            self.connected = False
    
    def _on_disconnect(self, client, userdata, rc):
        """Callback for MQTT disconnection"""
        logger.warning(f"Disconnected from athena MQTT broker: {rc}")
        self.connected = False
        self.registered = False
    
    def _on_message(self, client, userdata, msg):
        """Callback for MQTT message received"""
        try:
            topic = msg.topic
            payload = json.loads(msg.payload.decode())
            
            logger.debug(f"Received message on {topic}: {payload}")
            
            # Handle different message types
            if topic == f"athena/agents/{self.agent_id}/commands":
                self._handle_agent_command(payload)
            elif topic == "athena/agents/discovery":
                self._handle_discovery_request(payload)
                
        except Exception as e:
            logger.error(f"Error processing athena MQTT message: {e}")
    
    def _register_agent(self):
        """Register this agent with the athena system"""
        try:
            registration_data = {
                "agent_id": self.agent_id,
                "capabilities": self.agent_capabilities,
                "metadata": self.agent_metadata,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "status": "online"
            }
            
            # Publish registration
            topic = "athena/agents/register"
            self.client.publish(topic, json.dumps(registration_data))
            
            logger.info(f"Registered athena agent {self.agent_id} with capabilities: {self.agent_capabilities}")
            self.registered = True
            
            # Start heartbeat
            if not self.heartbeat_task:
                self.heartbeat_task = threading.Thread(target=self._heartbeat_loop, daemon=True)
                self.heartbeat_task.start()
                
        except Exception as e:
            logger.error(f"Failed to register athena agent: {e}")
    
    def _handle_agent_command(self, payload: Dict[str, Any]):
        """Handle commands sent to this agent"""
        try:
            command = payload.get("command")
            command_id = payload.get("id")
            params = payload.get("params", {})
            
            logger.info(f"Received agent command: {command}")
            
            response = {"id": command_id, "agent_id": self.agent_id}
            
            if command == "get_status":
                response["result"] = self._get_agent_status()
            elif command == "get_capabilities":
                response["result"] = {
                    "capabilities": self.agent_capabilities,
                    "metadata": self.agent_metadata
                }
            elif command == "force_motion_check":
                response["result"] = self._check_motion_events()
            else:
                response["error"] = f"Unknown command: {command}"
            
            # Send response
            response_topic = f"athena/agents/{self.agent_id}/responses"
            self.client.publish(response_topic, json.dumps(response))
            
        except Exception as e:
            logger.error(f"Error handling agent command: {e}")
    
    def _handle_discovery_request(self, payload: Dict[str, Any]):
        """Handle agent discovery requests"""
        try:
            request_id = payload.get("id")
            
            discovery_response = {
                "id": request_id,
                "agent_id": self.agent_id,
                "capabilities": self.agent_capabilities,
                "metadata": self.agent_metadata,
                "status": "online" if self.connected else "offline",
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            # Send discovery response
            topic = "athena/agents/discovered"
            self.client.publish(topic, json.dumps(discovery_response))
            
        except Exception as e:
            logger.error(f"Error handling discovery request: {e}")
    
    def _get_agent_status(self) -> Dict[str, Any]:
        """Get current agent status"""
        return {
            "agent_id": self.agent_id,
            "status": "online" if self.connected else "offline",
            "capabilities": self.agent_capabilities,
            "metadata": self.agent_metadata,
            "uptime": time.time() - self.start_time if hasattr(self, 'start_time') else 0,
            "last_heartbeat": datetime.now(timezone.utc).isoformat(),
            "motion_status": self._check_motion_status()
        }
    
    def _check_motion_status(self) -> Dict[str, Any]:
        """Check current motion detection status"""
        # Check if motion daemon is running
        motion_running = os.system("pgrep -x motion > /dev/null 2>&1") == 0
        
        # Check motion log for recent activity
        recent_activity = False
        try:
            motion_log = "/var/log/motion/motion.log"
            if os.path.exists(motion_log):
                # Check if motion log has been updated recently (last 5 minutes)
                log_mtime = os.path.getmtime(motion_log)
                recent_activity = (time.time() - log_mtime) < 300
        except:
            pass
        
        return {
            "motion_daemon_running": motion_running,
            "recent_activity": recent_activity,
            "camera_id": self.camera_id,
            "last_check": datetime.now(timezone.utc).isoformat()
        }
    
    def _heartbeat_loop(self):
        """Send periodic heartbeat messages"""
        while self.running and self.connected:
            try:
                heartbeat_data = {
                    "agent_id": self.agent_id,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "status": "online",
                    "capabilities": self.agent_capabilities
                }
                
                topic = f"athena/agents/{self.agent_id}/heartbeat"
                self.client.publish(topic, json.dumps(heartbeat_data))
                
                logger.debug(f"Sent heartbeat for agent {self.agent_id}")
                
            except Exception as e:
                logger.error(f"Error sending heartbeat: {e}")
            
            time.sleep(self.heartbeat_interval)
    
    def _check_motion_events(self) -> Dict[str, Any]:
        """Check for new motion events to forward"""
        try:
            # This would normally check motion's event files or logs
            # For now, return a status check
            motion_status = self._check_motion_status()
            
            # In a real implementation, this would:
            # 1. Check motion's event directory for new files
            # 2. Parse motion.log for new events  
            # 3. Monitor motion's MQTT output if configured
            # 4. Forward any new events to athena/events/motion/{agent_id}/{event_type}
            
            return {
                "checked_at": datetime.now(timezone.utc).isoformat(),
                "motion_status": motion_status,
                "events_found": 0  # Placeholder
            }
            
        except Exception as e:
            logger.error(f"Error checking motion events: {e}")
            return {"error": str(e)}
    
    def forward_motion_event(self, event_type: str, event_data: Dict[str, Any]):
        """Forward a motion event to the athena system"""
        try:
            if not self.connected:
                logger.warning("Cannot forward motion event: not connected to athena MQTT")
                return
            
            # Prepare event for athena system
            athena_event = {
                "agent_id": self.agent_id,
                "camera_id": self.camera_id,
                "event_type": event_type,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "data": event_data,
                "source": "motion_detector"
            }
            
            # Publish to athena event stream
            topic = f"athena/events/motion/{self.agent_id}/{event_type}"
            self.client.publish(topic, json.dumps(athena_event))
            
            logger.info(f"Forwarded motion event {event_type} to athena system")
            
        except Exception as e:
            logger.error(f"Error forwarding motion event: {e}")
    
    def monitor_motion_events(self):
        """Monitor motion events and forward to athena system"""
        """
        This method would implement real-time monitoring of motion events.
        Implementation options:
        1. Monitor motion's output directory for new files
        2. Parse motion.log in real-time 
        3. Hook into motion's event system
        4. Monitor motion's own MQTT output if configured
        """
        logger.info("Motion event monitoring started (placeholder implementation)")
        
        # Placeholder implementation - would be replaced with real monitoring
        while self.running:
            try:
                # Example: forward a test event every 60 seconds if motion is running
                if self._check_motion_status()["motion_daemon_running"]:
                    test_event = {
                        "message": "Motion daemon status check",
                        "daemon_running": True
                    }
                    # Don't actually send test events in production
                    # self.forward_motion_event("status_check", test_event)
                
                time.sleep(60)  # Check every minute
                
            except Exception as e:
                logger.error(f"Error in motion event monitoring: {e}")
                time.sleep(10)
    
    async def start(self):
        """Start the athena agent"""
        logger.info(f"Starting Motion Athena Agent {self.agent_id}")
        self.start_time = time.time()
        self.running = True
        
        # Setup and connect MQTT
        self.setup_mqtt()
        
        try:
            self.client.connect(self.mqtt_broker, self.mqtt_port, 60)
            self.client.loop_start()
            
            # Start motion event monitoring
            self.motion_monitor_task = threading.Thread(target=self.monitor_motion_events, daemon=True)
            self.motion_monitor_task.start()
            
            logger.info("Motion Athena Agent started successfully")
            
            # Keep running
            while self.running:
                await asyncio.sleep(1)
                
        except Exception as e:
            logger.error(f"Motion Athena Agent error: {e}")
            raise
    
    async def stop(self):
        """Stop the athena agent"""
        logger.info(f"Stopping Motion Athena Agent {self.agent_id}")
        self.running = False
        
        # Send deregistration
        if self.connected and self.client:
            try:
                deregister_data = {
                    "agent_id": self.agent_id,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "status": "offline"
                }
                topic = "athena/agents/deregister"
                self.client.publish(topic, json.dumps(deregister_data))
            except:
                pass
        
        # Cleanup MQTT
        if self.client:
            self.client.loop_stop()
            self.client.disconnect()
        
        logger.info("Motion Athena Agent stopped")

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Motion Athena Agent")
    parser.add_argument("--mqtt-broker", default=os.environ.get("MQTT_BROKER", "localhost"),
                        help="MQTT broker hostname/IP")
    parser.add_argument("--mqtt-port", type=int, default=int(os.environ.get("MQTT_PORT", "1883")),
                        help="MQTT broker port")
    parser.add_argument("--mqtt-username", default=os.environ.get("MQTT_USERNAME"),
                        help="MQTT username")
    parser.add_argument("--mqtt-password", default=os.environ.get("MQTT_PASSWORD"),
                        help="MQTT password")
    parser.add_argument("--agent-id", default=os.environ.get("AGENT_ID"),
                        help="Unique agent identifier")
    parser.add_argument("--camera-id", default=os.environ.get("CAMERA_ID", "motion_cam_01"),
                        help="Camera identifier")
    
    args = parser.parse_args()
    
    # Create agent
    agent = MotionAthenaAgent(
        mqtt_broker=args.mqtt_broker,
        mqtt_port=args.mqtt_port,
        mqtt_username=args.mqtt_username,
        mqtt_password=args.mqtt_password,
        agent_id=args.agent_id,
        camera_id=args.camera_id
    )
    
    # Handle shutdown gracefully
    def signal_handler(signum, frame):
        logger.info("Received shutdown signal")
        asyncio.create_task(agent.stop())
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Start agent
    try:
        asyncio.run(agent.start())
    except KeyboardInterrupt:
        logger.info("Shutting down Motion Athena Agent...")
    except Exception as e:
        logger.error(f"Motion Athena Agent failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()