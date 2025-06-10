# PTZ Camera Project Context

**Session Date**: 2025-06-07  
**Working Directory**: `/Users/j/Code/logi-ptz/webcam-ptz`  
**Current Focus**: Integrating PTZ camera with athena-capture for still image capture

## Current Status

### Completed Tasks
- ✅ Reorganized AI collaboration docs into clean structure
- ✅ Autonomous shell execution enabled with builtin Bash tool
- ✅ Verified webcam-ptz executable exists and has permissions
- ✅ Established examples convention in `ai-collab/examples/`

### Active Todo List
- ✅ **COMPLETED**: Check if Logitech PTZ camera is attached - CAMERA IS WORKING!
- 🔄 **IN PROGRESS**: Document camera troubleshooting and commit status
- ⏳ **PENDING**: Examine athena-capture codebase to understand integration points
- ⏳ **PENDING**: Design integration approach for athena-capture to pull stills from PTZ camera  
- ⏳ **PENDING**: Implement still capture integration

### Technical Context

**PTZ Camera Setup**:
- Executable: `/Users/j/Code/logi-ptz/webcam-ptz/webcam-ptz` 
- ✅ **CONFIRMED WORKING**: Camera responds to `./webcam-ptz pan middle`
- **Troubleshooting**: Camera gets blocked by `cameracaptured` process after ~30 seconds
- **Solution**: Kill blocking process: `echo "jjjj" | sudo -S pkill cameracaptured`
- **USB Detection**: Shows as "PTZ Pro Camera" (Vendor ID: 0x046d) in system_profiler

**Project Structure**:
```
logi-ptz/
├── ptz-rest-api/          # Flask REST API and web interface
│   ├── src/ptz_rest_api/
│   ├── templates/
│   └── static/
└── webcam-ptz/            # C-based command-line tool
    ├── webcam-ptz         # Executable (UVC camera control)
    └── README.md
```

**Integration Goal**: Enable athena-capture to pull still images from PTZ camera on request

### Next Actions on Resume
1. **Use builtin Bash tool** for all commands (autonomous execution enabled)
2. **Test camera connectivity**: `./webcam-ptz pan middle`
3. **Find athena-capture codebase** and examine integration points
4. **Design still capture integration** approach

### Session Notes
- User prefers autonomous flow language and practical solutions
- Apply Integration Pause Protocol before implementing
- All collaboration examples go in `ai-collab/examples/`
- Builtin Bash tool provides autonomous execution capability

---
*Resume file for maintaining context across Claude Code sessions*