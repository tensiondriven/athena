# Logitech PTZ Pro 2 Camera Control Interface Guide

## Overview

The Logitech PTZ Pro 2 is a professional video conferencing camera that supports pan, tilt, and zoom operations through USB Video Class (UVC) control interfaces. This guide covers the technical details, power requirements, multiple device handling, and provides setup instructions for both macOS and Linux systems.

## Camera Specifications

### Physical Specifications
- **Model**: Logitech PTZ Pro 2 (Model 960-001184)
- **Video Resolution**: Full HD 1080p at 30fps
- **Optical Zoom**: 10x optical zoom
- **Pan Range**: ±170° horizontal
- **Tilt Range**: +90° to -30° vertical
- **Field of View**: 90° diagonal (varies with zoom)

### Power Requirements
- **Power Supply**: USB Bus-powered OR external power adapter
- **USB Power**: 5V DC via USB 3.0 (500-900mA typical)
- **External Power**: 12V DC, 1A (optional for extended operation)
- **Power Consumption**: ~5-10 watts during operation
- **Startup Current**: Brief spike to ~1.5A during initialization

⚠️ **Important**: For reliable PTZ operation, especially with multiple cameras, external 12V power adapters are strongly recommended to avoid USB power limitations.

## Interface Technology

### UVC (USB Video Class) Control
The camera uses the USB Video Class (UVC) standard for video streaming and control. However, PTZ controls are handled through UVC extension units that are vendor-specific.

### Control Mechanisms
1. **UVC Extension Units**: Pan/tilt/zoom controls
2. **Video Stream Interface**: Standard UVC video capture
3. **Audio Interface**: USB Audio Class for microphone array

### Key Technical Points
- Uses **libuvc** library for low-level UVC control access
- PTZ controls are separate from video streaming interface
- Camera exposes multiple USB interfaces simultaneously

## Multiple Device Conflict Issue

### The Problem
The Logitech PTZ Pro 2 camera exposes multiple USB video devices:
1. **Video Stream Device** (`/dev/video0`, `/dev/video1`, etc.)
2. **PTZ Control Interface** (UVC extension unit)

When a video application (like OBS, Zoom, or ffmpeg) opens the video stream, it can lock the video device and prevent PTZ control applications from accessing the UVC control interface.

### Technical Explanation
```bash
# Camera typically appears as multiple devices:
/dev/video0    # Main video stream (1080p)
/dev/video1    # Secondary stream (720p/480p)
# Plus UVC control interface accessible via libuvc
```

### Solutions
1. **Exclusive Access Management**: Ensure only one application accesses video stream at a time
2. **Service-Based Architecture**: Use a central PTZ service that manages camera access
3. **Video Stream Sharing**: Use GStreamer or similar for stream multiplexing
4. **Camera Recognition**: Handle different camera identification strings ("PTZ Pro 2" vs "Logi Group Camera")

## Linux Setup Instructions

### Prerequisites
```bash
# Install required packages (Ubuntu/Debian)
sudo apt update
sudo apt install build-essential cmake pkg-config
sudo apt install libusb-1.0-0-dev libuvc-dev
sudo apt install v4l-utils uvcdynctrl

# For CentOS/RHEL/Fedora
sudo dnf install gcc cmake pkgconfig
sudo dnf install libusb1-devel libuvc-devel
sudo dnf install v4l-utils uvcdynctrl
```

### Build libuvc from Source (if needed)
```bash
git clone https://github.com/libuvc/libuvc.git
cd libuvc
mkdir build && cd build
cmake ..
make -j4
sudo make install
sudo ldconfig
```

### Compile PTZ Control Program
```bash
gcc -I/usr/include/libuvc -o webcam-ptz webcam-ptz.c -luvc -lusb-1.0
```

### USB Permissions Setup
```bash
# Add user to video group
sudo usermod -a -G video $USER

# Create udev rule for PTZ camera access
sudo tee /etc/udev/rules.d/99-logitech-ptz.rules << EOF
# Logitech PTZ Pro 2 Camera
SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="085e", MODE="0666", GROUP="video"
# Logitech PTZ Pro (original)
SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="085d", MODE="0666", GROUP="video"
EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Logout and login for group changes to take effect
```

### Camera Detection and Testing
```bash
# List USB video devices
v4l2-ctl --list-devices

# Check UVC controls available
uvcdynctrl -d /dev/video0 -c

# Test camera detection
lsusb | grep -i logitech

# Test PTZ functionality
./webcam-ptz pan middle
./webcam-ptz tilt middle  
./webcam-ptz zoom min
```

## macOS Setup Instructions

### Prerequisites
```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required libraries
brew install libusb libuvc cmake pkg-config
```

### Compile PTZ Control Program
```bash
gcc -I/opt/homebrew/include -L/opt/homebrew/lib -o webcam-ptz webcam-ptz.c -luvc
```

### Testing
```bash
# Test camera detection and basic PTZ
./webcam-ptz pan middle
./webcam-ptz tilt middle
./webcam-ptz zoom min
```

## Usage Examples

### Basic PTZ Control
```bash
# Center camera position
./webcam-ptz pan middle
./webcam-ptz tilt middle

# Move camera to extremes
./webcam-ptz pan min      # Full left
./webcam-ptz pan max      # Full right
./webcam-ptz tilt min     # Full down
./webcam-ptz tilt max     # Full up

# Incremental movements
./webcam-ptz pan 5        # Move right 5 steps
./webcam-ptz pan -3       # Move left 3 steps
./webcam-ptz tilt 2       # Move up 2 steps

# Zoom control
./webcam-ptz zoom min     # Wide angle
./webcam-ptz zoom max     # Full zoom in
./webcam-ptz zoom 3       # Zoom in 3 steps
```

### Scripted Camera Presets
```bash
#!/bin/bash
# Camera preset positions

# Preset 1: Wide shot, centered
./webcam-ptz pan middle
./webcam-ptz tilt middle  
./webcam-ptz zoom min

# Preset 2: Close-up, slight right
./webcam-ptz pan 10
./webcam-ptz tilt 5
./webcam-ptz zoom 15
```

## Troubleshooting

### Common Issues

1. **"No camera found" error**
   - Check USB connection and power
   - Verify camera appears in `lsusb` (Linux) or `system_profiler SPUSBDataType` (macOS)
   - Check if another application is using the camera

2. **Permission denied errors (Linux)**
   - Add user to video group: `sudo usermod -a -G video $USER`
   - Check udev rules are properly configured
   - Try running with sudo (temporary test)

3. **"Unable to access camera" errors**
   - Close all video applications (Zoom, OBS, etc.)
   - Unplug and reconnect camera
   - Check if multiple applications are competing for access

4. **PTZ commands not working**
   - Verify this is a PTZ-capable camera model
   - Check if camera firmware is up to date
   - Try power cycling the camera

### Camera Recognition Issues
Some cameras may appear with different names:
- "PTZ Pro 2" (expected)
- "Logi Group Camera" (alternative identification)
- "USB Camera" (generic fallback)

## Claude Code Autonomous Execution

### Enabling Autonomous Mode
To run Claude Code in fully autonomous mode without user interruption prompts:

```bash
# Enable autonomous mode with permission skipping
claude --dangerously-skip-permissions

# Configure allowed tools for automatic execution
claude --allowedTools="bash,edit,read,write"

# Limit autonomous execution turns
claude --max-turns=50
```

### MCP Server Configuration
For seamless command execution, configure the Claude Executive Command Server (CASH MCP):

```json
{
  "mcpServers": {
    "claude_exec_mcp": {
      "command": "python3",
      "args": ["/path/to/cash_server.py"],
      "description": "Claude Executive Command Server - Autonomous shell execution"
    }
  }
}
```

## Security and Safety Notes

- Always use external power for production deployments
- USB bus power may be insufficient for reliable PTZ operation
- Multiple camera setups require careful power and bandwidth management
- UVC control conflicts can cause system instability
- Test thoroughly before production use

## Next Steps

This documentation provides the foundation for building automated PTZ camera control systems. The next logical step is implementing a REST API service that manages camera access and provides a web interface for remote control.