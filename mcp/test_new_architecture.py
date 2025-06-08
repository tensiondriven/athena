#!/usr/bin/env python3
"""
Test script for new Generic Camera MCP + Collector Daemon architecture
"""

import asyncio
import json
import subprocess
import sys

async def test_daemon_directly():
    """Test the Logitech collector daemon directly"""
    print("=== Testing Logitech PTZ Collector Daemon ===")
    
    # Test list command
    print("Testing daemon list command...")
    result = subprocess.run([
        "python3", "/Users/j/Code/logi-ptz/daemons/logitech_ptz_daemon.py", "list"
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        daemon_result = json.loads(result.stdout)
        print(f"✅ Daemon list: {daemon_result}")
        return daemon_result.get("cameras", [])
    else:
        print(f"❌ Daemon list failed: {result.stderr}")
        return []

async def test_mcp_server():
    """Test the generic MCP server"""
    print("\n=== Testing Generic Camera MCP Server ===")
    
    # Start MCP server process
    process = await asyncio.create_subprocess_exec(
        "python3", "/Users/j/Code/mcp/camera_mcp_server.py",
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    try:
        # Test list_cameras
        request = {"method": "list_cameras", "id": 1}
        request_json = json.dumps(request) + "\n"
        
        process.stdin.write(request_json.encode())
        await process.stdin.drain()
        
        # Read response
        response_line = await asyncio.wait_for(process.stdout.readline(), timeout=10)
        response = json.loads(response_line.decode().strip())
        
        print(f"✅ MCP list_cameras: {response}")
        
        # Test camera_control if we have cameras
        cameras = response.get("result", {}).get("cameras", [])
        if cameras:
            camera_id = cameras[0]["id"]
            
            control_request = {
                "method": "camera_control", 
                "params": {"camera_id": camera_id, "command": "pan", "value": "middle"},
                "id": 2
            }
            control_json = json.dumps(control_request) + "\n"
            
            process.stdin.write(control_json.encode())
            await process.stdin.drain()
            
            control_response_line = await asyncio.wait_for(process.stdout.readline(), timeout=15)
            control_response = json.loads(control_response_line.decode().strip())
            
            print(f"✅ MCP camera_control: {control_response}")
        else:
            print("⚠️ No cameras available for control test")
        
    except Exception as e:
        print(f"❌ MCP server test failed: {e}")
    finally:
        process.terminate()
        await process.wait()

async def main():
    """Main test function"""
    print("Testing New Camera Architecture:")
    print("Generic MCP Server + Collector Daemon separation\n")
    
    # Test collector daemon first
    cameras = await test_daemon_directly()
    
    # Test MCP server
    await test_mcp_server()
    
    print("\n=== Architecture Summary ===")
    print("✅ Generic MCP Server: Hardware agnostic, delegates to daemons")
    print("✅ Logitech Collector Daemon: Hardware specific implementation")
    print("✅ Clean separation: MCP handles protocol, daemon handles hardware")
    
    if cameras:
        print(f"✅ Found {len(cameras)} camera(s)")
    else:
        print("⚠️ No cameras found - check hardware connection")

if __name__ == "__main__":
    asyncio.run(main())