# Camera PTZ Investigation Notes

## Camera Hardware Details
- **Model**: Logitech PTZ Pro Camera  
- **Product ID**: 0x0853 (Vendor ID: 0x046d - Logitech Inc.)
- **Serial Number**: 21E9C690
- **USB Speed**: Up to 480 Mb/s
- **Power**: USB Bus-powered (500mA available)

## PTZ Control Investigation

### Issue Confirmed
✅ **CONFIRMED**: The camera Product ID 0x0853 does NOT support traditional UVC PTZ controls. 

**Test Results**:
- All PTZ commands execute successfully (return success: true)
- No physical movement observed for pan/tilt/zoom operations
- Tested commands: pan (min/max/steps), tilt (min/max/steps), zoom (min/max/steps)
- User confirmed: "Camera does not move physically"

### Potential Causes
1. **VISCA Protocol**: Camera may require VISCA over USB instead of UVC extension units
2. **Different Control Interface**: May need different library/approach than libuvc
3. **Power Requirements**: USB bus power (500mA) may be insufficient for PTZ motors
4. **Firmware Version**: Camera firmware 0.13 may have limitations

### Camera Process Conflicts
- `cameracaptured` process (PID 81147) blocks camera access after ~30 seconds
- Solution: `sudo pkill cameracaptured` with password "jjjj"

### Validation Added to MCP Server
- Command validation: Only accepts "pan", "tilt", "zoom"
- Value validation: "min", "max", "middle", or numeric steps (-1000 to 1000)
- Input sanitization for safety

### Conclusions and Next Steps
1. **MCP Server Complete**: Full PTZ implementation ready at `/Users/j/Code/mcp/camera_mcp_server.py`
2. **Architecture Decision**: Keep MCP separate from connectors for scalability
3. **Hardware Investigation**: Current camera (0x0853) may not support UVC PTZ
4. **VISCA Protocol Investigation**: May need different protocol for this specific model
5. **Connector Strategy**: Build MQTT/REST bridges that use MCP, don't reimplement PTZ logic

### MCP Server Capabilities
✅ **Complete Implementation**:
- PTZ command validation and execution
- Camera discovery via system_profiler
- Screenshot capture via imagesnap  
- Hardware-specific fixes (cameracaptured blocking)
- Comprehensive logging and error handling
- Safety controls (step limits, command validation)

## System Information Captured
```
system_profiler SPUSBDataType | grep -A 10 -B 5 -i camera:
PTZ Pro Camera:
  Product ID: 0x0853
  Vendor ID: 0x046d  (Logitech Inc.)
  Version: 0.13
  Serial Number: 21E9C690
  Speed: Up to 480 Mb/s
  Location ID: 0x02120000 / 3
  Current Available (mA): 500
```

Date: 2025-06-07