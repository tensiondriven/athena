#!/usr/bin/env python3
"""
Camera MQTT Connector
Bridges MQTT commands to Camera MCP Server for distributed PTZ control.

This connector allows remote PTZ control via MQTT while keeping all camera
logic in the dedicated MCP server. Perfect for multi-camera deployments
with USB and WiFi cameras.

Topic Structure:
- camera/{camera_id}/ptz/command -> PTZ commands
- camera/{camera_id}/ptz/response -> PTZ responses  
- camera/{camera_id}/screenshot/command -> Screenshot requests
- camera/{camera_id}/screenshot/response -> Screenshot data
- camera/{camera_id}/status/request -> Status queries
- camera/{camera_id}/status/response -> Status responses
"""

import asyncio
import json
import logging
import signal
import sys
from typing import Any, Dict, Optional
from datetime import datetime

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

class CameraMCPClient:
    """Client for communicating with Camera MCP Server"""
    
    def __init__(self, mcp_server_path: str = "/Users/j/Code/mcp/camera_mcp_server.py"):
        self.mcp_server_path = mcp_server_path
        self.process = None
        
    async def start_mcp_server(self):
        """Start the Camera MCP Server process"""
        try:
            self.process = await asyncio.create_subprocess_exec(
                "python3", self.mcp_server_path,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            logger.info("Camera MCP Server started")
            return True
        except Exception as e:
            logger.error(f"Failed to start MCP server: {e}")
            return False
    
    async def send_command(self, method: str, params: Dict = None, command_id: int = None) -> Dict[str, Any]:
        """Send command to MCP server and get response"""
        if not self.process:
            return {"error": "MCP server not running"}
        
        try:
            # Build JSON-RPC request
            request = {
                "method": method,
                "params": params or {},
                "id": command_id or int(datetime.now().timestamp() * 1000)
            }
            
            # Send to MCP server
            request_json = json.dumps(request) + "\n"
            self.process.stdin.write(request_json.encode())
            await self.process.stdin.drain()
            
            # Read response
            response_line = await self.process.stdout.readline()
            response = json.loads(response_line.decode().strip())
            
            return response
            
        except Exception as e:
            logger.error(f"MCP command failed: {e}")
            return {"error": str(e)}
    
    async def stop(self):
        """Stop the MCP server process"""
        if self.process:
            self.process.terminate()
            await self.process.wait()
            logger.info("Camera MCP Server stopped")

class CameraMQTTConnector:
    """MQTT connector for Camera MCP Server"""
    
    def __init__(self, broker_host: str = "localhost", broker_port: int = 1883, 
                 camera_id: str = "camera1"):
        self.broker_host = broker_host
        self.broker_port = broker_port
        self.camera_id = camera_id
        self.client = None
        self.mcp_client = CameraMCPClient()
        self.running = False
        
    def setup_mqtt(self):
        """Setup MQTT client and callbacks"""
        self.client = mqtt.Client(client_id=f"camera_connector_{self.camera_id}")
        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message
        self.client.on_disconnect = self._on_disconnect
        
    def _on_connect(self, client, userdata, flags, rc):
        """Callback for MQTT connection"""
        if rc == 0:
            logger.info(f"Connected to MQTT broker at {self.broker_host}:{self.broker_port}")
            
            # Subscribe to command topics
            topics = [
                f"camera/{self.camera_id}/ptz/command",
                f"camera/{self.camera_id}/screenshot/command", 
                f"camera/{self.camera_id}/status/request"
            ]
            
            for topic in topics:
                client.subscribe(topic)
                logger.info(f"Subscribed to {topic}")
        else:
            logger.error(f"Failed to connect to MQTT broker: {rc}")
    
    def _on_disconnect(self, client, userdata, rc):
        """Callback for MQTT disconnection"""
        logger.warning(f"Disconnected from MQTT broker: {rc}")
    
    def _on_message(self, client, userdata, msg):
        """Callback for MQTT message received"""
        try:
            topic = msg.topic
            payload = json.loads(msg.payload.decode())
            
            logger.info(f"Received command on {topic}: {payload}")
            
            # Handle different command types
            if "/ptz/command" in topic:
                asyncio.create_task(self._handle_ptz_command(payload))
            elif "/screenshot/command" in topic:
                asyncio.create_task(self._handle_screenshot_command(payload))
            elif "/status/request" in topic:
                asyncio.create_task(self._handle_status_request(payload))
                
        except Exception as e:
            logger.error(f"Error processing MQTT message: {e}")
    
    async def _handle_ptz_command(self, payload: Dict):
        """Handle PTZ command from MQTT"""
        try:
            # Extract PTZ parameters
            command = payload.get("command")
            value = payload.get("value")
            request_id = payload.get("id")
            
            # Send to MCP server
            response = await self.mcp_client.send_command(
                method="ptz_control",
                params={"command": command, "value": value},
                command_id=request_id
            )
            
            # Publish response
            response_topic = f"camera/{self.camera_id}/ptz/response"
            self.client.publish(response_topic, json.dumps(response))
            
        except Exception as e:
            logger.error(f"PTZ command error: {e}")
            error_response = {"error": str(e), "id": payload.get("id")}
            response_topic = f"camera/{self.camera_id}/ptz/response"
            self.client.publish(response_topic, json.dumps(error_response))
    
    async def _handle_screenshot_command(self, payload: Dict):
        """Handle screenshot command from MQTT"""
        try:
            camera_name = payload.get("camera_name", "PTZ Pro Camera")
            output_path = payload.get("output_path")
            request_id = payload.get("id")
            
            # Send to MCP server
            response = await self.mcp_client.send_command(
                method="take_screenshot",
                params={"camera_name": camera_name, "output_path": output_path},
                command_id=request_id
            )
            
            # Publish response
            response_topic = f"camera/{self.camera_id}/screenshot/response"
            self.client.publish(response_topic, json.dumps(response))
            
        except Exception as e:
            logger.error(f"Screenshot command error: {e}")
            error_response = {"error": str(e), "id": payload.get("id")}
            response_topic = f"camera/{self.camera_id}/screenshot/response"
            self.client.publish(response_topic, json.dumps(error_response))
    
    async def _handle_status_request(self, payload: Dict):
        """Handle status request from MQTT"""
        try:
            request_id = payload.get("id")
            
            # Get camera status from MCP server
            response = await self.mcp_client.send_command(
                method="get_camera_status",
                command_id=request_id
            )
            
            # Add connector info
            if "result" in response:
                response["result"]["connector"] = {
                    "camera_id": self.camera_id,
                    "mqtt_broker": f"{self.broker_host}:{self.broker_port}",
                    "timestamp": datetime.now().isoformat()
                }
            
            # Publish response
            response_topic = f"camera/{self.camera_id}/status/response"
            self.client.publish(response_topic, json.dumps(response))
            
        except Exception as e:
            logger.error(f"Status request error: {e}")
            error_response = {"error": str(e), "id": payload.get("id")}
            response_topic = f"camera/{self.camera_id}/status/response"
            self.client.publish(response_topic, json.dumps(error_response))
    
    async def start(self):
        """Start the MQTT connector"""
        logger.info(f"Starting Camera MQTT Connector for {self.camera_id}")
        
        # Start MCP server
        if not await self.mcp_client.start_mcp_server():
            logger.error("Failed to start MCP server")
            return False
        
        # Setup and connect MQTT
        self.setup_mqtt()
        
        try:
            self.client.connect(self.broker_host, self.broker_port, 60)
            self.client.loop_start()
            self.running = True
            
            logger.info("Camera MQTT Connector started successfully")
            
            # Keep running
            while self.running:
                await asyncio.sleep(1)
                
        except Exception as e:
            logger.error(f"MQTT connector error: {e}")
            return False
    
    async def stop(self):
        """Stop the MQTT connector"""
        logger.info("Stopping Camera MQTT Connector")
        self.running = False
        
        if self.client:
            self.client.loop_stop()
            self.client.disconnect()
        
        await self.mcp_client.stop()

async def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Camera MQTT Connector")
    parser.add_argument("--broker", default="localhost", help="MQTT broker host")
    parser.add_argument("--port", type=int, default=1883, help="MQTT broker port")
    parser.add_argument("--camera-id", default="camera1", help="Camera ID for MQTT topics")
    
    args = parser.parse_args()
    
    # Create connector
    connector = CameraMQTTConnector(
        broker_host=args.broker,
        broker_port=args.port,
        camera_id=args.camera_id
    )
    
    # Handle shutdown gracefully
    def signal_handler(signum, frame):
        logger.info("Received shutdown signal")
        asyncio.create_task(connector.stop())
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Start connector
    try:
        await connector.start()
    except KeyboardInterrupt:
        logger.info("Shutting down...")
    finally:
        await connector.stop()

if __name__ == "__main__":
    asyncio.run(main())