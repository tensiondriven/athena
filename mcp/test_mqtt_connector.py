#!/usr/bin/env python3
"""
Test script for Camera MQTT Connector
Tests the MQTT bridge to Camera MCP Server functionality.
"""

import asyncio
import json
import time
from typing import Dict, Any

try:
    import paho.mqtt.client as mqtt
except ImportError:
    print("Error: paho-mqtt not installed. Run: pip install paho-mqtt")
    exit(1)

class MQTTTester:
    def __init__(self, broker_host="localhost", broker_port=1883, camera_id="camera1"):
        self.broker_host = broker_host
        self.broker_port = broker_port
        self.camera_id = camera_id
        self.client = mqtt.Client(client_id="camera_tester")
        self.responses = {}
        
    def setup(self):
        """Setup MQTT client"""
        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message
        
    def _on_connect(self, client, userdata, flags, rc):
        print(f"Connected to MQTT broker: {rc}")
        # Subscribe to response topics
        topics = [
            f"camera/{self.camera_id}/ptz/response",
            f"camera/{self.camera_id}/screenshot/response",
            f"camera/{self.camera_id}/status/response"
        ]
        for topic in topics:
            client.subscribe(topic)
            print(f"Subscribed to {topic}")
    
    def _on_message(self, client, userdata, msg):
        """Handle response messages"""
        try:
            topic = msg.topic
            payload = json.loads(msg.payload.decode())
            print(f"Response on {topic}: {payload}")
            
            # Store response by ID for verification
            if "id" in payload:
                self.responses[payload["id"]] = payload
                
        except Exception as e:
            print(f"Error processing response: {e}")
    
    async def send_command(self, topic_suffix: str, command: Dict[str, Any], wait_for_response=True):
        """Send command and optionally wait for response"""
        topic = f"camera/{self.camera_id}/{topic_suffix}"
        command_id = int(time.time() * 1000)
        command["id"] = command_id
        
        print(f"Sending command to {topic}: {command}")
        self.client.publish(topic, json.dumps(command))
        
        if wait_for_response:
            # Wait for response
            for _ in range(50):  # 5 second timeout
                if command_id in self.responses:
                    response = self.responses[command_id]
                    del self.responses[command_id]
                    return response
                await asyncio.sleep(0.1)
            
            print(f"Timeout waiting for response to command {command_id}")
            return None
        
        return {"sent": True}
    
    async def test_ptz_commands(self):
        """Test PTZ commands"""
        print("\n=== Testing PTZ Commands ===")
        
        commands = [
            {"command": "pan", "value": "middle"},
            {"command": "tilt", "value": "middle"},
            {"command": "zoom", "value": "min"},
            {"command": "pan", "value": "10"},
            {"command": "tilt", "value": "-5"}
        ]
        
        for cmd in commands:
            response = await self.send_command("ptz/command", cmd)
            if response:
                success = response.get("result", {}).get("success", False)
                print(f"  PTZ {cmd}: {'✅ SUCCESS' if success else '❌ FAILED'}")
            else:
                print(f"  PTZ {cmd}: ❌ NO RESPONSE")
    
    async def test_screenshot(self):
        """Test screenshot command"""
        print("\n=== Testing Screenshot ===")
        
        cmd = {"camera_name": "PTZ Pro Camera"}
        response = await self.send_command("screenshot/command", cmd)
        
        if response:
            result = response.get("result", {})
            success = result.get("success", False)
            output_path = result.get("output_path", "")
            print(f"  Screenshot: {'✅ SUCCESS' if success else '❌ FAILED'}")
            if success:
                print(f"    Saved to: {output_path}")
        else:
            print("  Screenshot: ❌ NO RESPONSE")
    
    async def test_status(self):
        """Test status request"""
        print("\n=== Testing Status ===")
        
        cmd = {}
        response = await self.send_command("status/request", cmd)
        
        if response:
            result = response.get("result", {})
            success = result.get("success", False)
            print(f"  Status: {'✅ SUCCESS' if success else '❌ FAILED'}")
            if success:
                print(f"    PTZ Available: {result.get('ptz_available', False)}")
                print(f"    Imagesnap Available: {result.get('imagesnap_available', False)}")
                print(f"    Cached Cameras: {result.get('cached_cameras', 0)}")
        else:
            print("  Status: ❌ NO RESPONSE")
    
    async def run_tests(self):
        """Run all tests"""
        print(f"Starting MQTT tests for camera {self.camera_id}")
        print(f"Broker: {self.broker_host}:{self.broker_port}")
        
        # Connect to MQTT
        self.client.connect(self.broker_host, self.broker_port, 60)
        self.client.loop_start()
        
        # Wait for connection
        await asyncio.sleep(1)
        
        try:
            # Run tests
            await self.test_status()
            await self.test_ptz_commands()
            await self.test_screenshot()
            
            print("\n=== Test Summary ===")
            print("Tests completed. Check output above for results.")
            
        finally:
            self.client.loop_stop()
            self.client.disconnect()

async def main():
    """Main test function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Test Camera MQTT Connector")
    parser.add_argument("--broker", default="localhost", help="MQTT broker host")
    parser.add_argument("--port", type=int, default=1883, help="MQTT broker port")
    parser.add_argument("--camera-id", default="camera1", help="Camera ID")
    
    args = parser.parse_args()
    
    tester = MQTTTester(args.broker, args.port, args.camera_id)
    tester.setup()
    
    await tester.run_tests()

if __name__ == "__main__":
    asyncio.run(main())