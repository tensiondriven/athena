#!/usr/bin/env python3
"""
Test script for Final Camera Architecture
PTZ MCP Server + Screenshot MCP Server + Collector Daemons
"""

import asyncio
import json
import subprocess

async def test_final_architecture():
    """Test the final separated architecture"""
    print("=== Testing Final Camera Architecture ===")
    print("PTZ MCP Server + Screenshot MCP Server + Collector Daemons")
    
    # Test PTZ MCP Server
    print("\n🎯 Testing PTZ MCP Server...")
    result = subprocess.run([
        "python3", "/Users/j/Code/mcp/ptz_mcp_server.py"
    ], input='{"method": "list_ptz_cameras", "id": 1}\n', 
       capture_output=True, text=True, timeout=10)
    
    if result.returncode == 0:
        response = json.loads(result.stdout.strip())
        cameras = response.get("result", {}).get("cameras", [])
        print(f"✅ PTZ Server: Found {len(cameras)} PTZ camera(s)")
    else:
        print(f"❌ PTZ Server failed: {result.stderr}")
    
    # Test Screenshot MCP Server  
    print("\n📷 Testing Screenshot MCP Server...")
    result = subprocess.run([
        "python3", "/Users/j/Code/mcp/screenshot_mcp_server.py"
    ], input='{"method": "list_screenshot_cameras", "id": 2}\n',
       capture_output=True, text=True, timeout=10)
    
    if result.returncode == 0:
        response = json.loads(result.stdout.strip())
        cameras = response.get("result", {}).get("cameras", [])
        print(f"✅ Screenshot Server: Found {len(cameras)} screenshot camera(s)")
    else:
        print(f"❌ Screenshot Server failed: {result.stderr}")
    
    # Test Collector Daemons directly
    print("\n🔧 Testing Collector Daemons...")
    
    # Test Logitech PTZ Collector
    result = subprocess.run([
        "python3", "/Users/j/Code/logi-ptz/daemons/logitech_ptz_daemon.py", "list"
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        daemon_result = json.loads(result.stdout)
        cameras = daemon_result.get("cameras", [])
        print(f"✅ Logitech PTZ Collector: {len(cameras)} camera(s)")
    else:
        print(f"❌ Logitech PTZ Collector failed: {result.stderr}")
    
    # Test USB Webcam Collector
    result = subprocess.run([
        "python3", "/Users/j/Code/logi-ptz/daemons/usb_webcam_daemon.py", "list"
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        daemon_result = json.loads(result.stdout)
        cameras = daemon_result.get("cameras", [])
        print(f"✅ USB Webcam Collector: {len(cameras)} camera(s)")
    else:
        print(f"❌ USB Webcam Collector failed: {result.stderr}")
    
    print("\n=== Architecture Benefits ===")
    print("✅ Capability Separation: PTZ vs Screenshot operations cleanly separated")
    print("✅ Hardware Abstraction: MCP servers are hardware agnostic")
    print("✅ Extensible: Easy to add new camera types via collector daemons")
    print("✅ Composable: athena-capture can use PTZ + Screenshot servers as needed")

if __name__ == "__main__":
    asyncio.run(test_final_architecture())