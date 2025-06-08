# Testing Philosophy for Athena Distributed System

## Core Principle: Fail Fast and Loud

The system has many moving parts - collectors, APIs, databases, file systems, Docker containers, network connections. Each component can break in obvious ways (missing files) or subtle ways (wrong permissions, bad configs). Our testing strategy prioritizes early detection over comprehensive coverage.

## Three-Layer Testing Strategy

### 1. Startup Validation (Required)
Every component must validate its world before starting:
- **Paths exist and are writable**: Don't assume, verify
- **Environment variables present and sane**: Check ranges, formats, required values
- **Database connections work**: Actually query, don't just connect
- **External dependencies respond**: APIs, file systems, hardware
- **Permissions allow expected operations**: Test write, read, execute as needed

**Non-negotiable rule**: If any dependency is broken, exit with clear error message and fix instructions.

### 2. Runtime Health Monitoring
Continuous verification that the system is actually functioning:
- **Deep health checks**: `/health` endpoints that exercise real functionality
- **Functional smoke tests**: Actually collect a file, take a screenshot, write to database
- **Performance monitoring**: Detect when things get slow or stuck
- **Resource checks**: Disk space, memory, connection pools

### 3. Integration Proof Points
End-to-end flows that prove the system works as intended:
- **File lifecycle**: Create → Detect → Store → Query → Retrieve
- **API workflows**: Request → Process → Respond → Verify
- **Event flows**: Generate → Collect → Process → Store
- **Cross-service communication**: Verify actual data exchange

## Testing Implementation

### Immediate Feedback Tools
- `--verify`: Pre-flight checks only, report status, exit
- `--smoke-test`: Full functional verification in 30 seconds
- `--health-deep`: Comprehensive system check with timing data
- Real-time dashboard showing component status and last-known-good timestamps

### Error Strategy
- **Specific fix instructions**: "Directory /data missing. Run: mkdir /data"
- **Context in errors**: "Screenshot failed: screencapture not found. Install Xcode command line tools."
- **Progressive detail**: Summary first, full diagnostics on request
- **Machine-readable status**: JSON health reports for automation

### Development Integration
- Pre-commit hooks that run verification
- CI smoke tests on every change
- Local dev scripts that show system status
- Integration with existing monitoring tools

### Continuous Validation
- Health endpoints exercise actual functionality (not just "server alive")
- Scheduled self-tests detect degradation
- Resource monitoring with configurable thresholds
- Automatic alerts when components become unhealthy

**Success metric**: Zero-debug deployment. If verification passes, deployment works.