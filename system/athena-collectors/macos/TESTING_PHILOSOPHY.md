# Testing Philosophy for Athena Distributed System

## Core Principle: Fail Fast and Loud

This distributed system has collectors, APIs, databases, file watchers, Docker containers, and network services. Components fail in predictable ways (missing directories) and subtle ways (permissions, configs, resource limits). Our testing philosophy: **catch failures at the earliest possible moment with maximum clarity about what's wrong and how to fix it**.

Testing strategy prioritizes:
1. **Early detection** over comprehensive coverage
2. **Clear diagnostics** over silent failures  
3. **Actionable errors** over vague messages
4. **Real functionality** over mock success

## Three-Layer Testing Strategy

### 1. Startup Validation (Non-Negotiable)
Every component validates its universe before accepting any work:

**Environment checks**:
- Paths exist and are writable (create test file, verify, delete)
- Environment variables present with valid values (not just set)
- Required external tools available (screencapture, etc.)

**Dependency validation**:
- Database: Connect AND execute test query
- APIs: Actually call endpoints, verify responses
- File systems: Test read/write permissions on target directories
- Hardware: Verify camera access, screenshot capability

**Configuration sanity**:
- Port numbers in valid range and available
- File size limits reasonable (not 0, not 10TB)
- Timeouts and intervals make sense

**Exit rule**: Any validation failure = immediate exit with specific fix instructions. No "best effort" operation.

### 2. Runtime Health Monitoring  
Ongoing verification that everything still works:

**Functional health checks**:
- `/health` endpoints test the full stack (not just "HTTP 200")
- Periodic smoke tests: collect file, take screenshot, query database
- Resource monitoring: disk space, memory, open files
- Performance baselines: detect when operations get slow

**Auto-recovery attempts**:
- Restart file watchers if they stop responding
- Reconnect to databases after network blips
- Clear temp files if disk space low
- Graceful degradation when resources constrained

### 3. Integration Verification
End-to-end flows proving components work together:

**Critical paths**:
- File lifecycle: Create test file → Watcher detects → Store in DB → Query via API
- Screenshot flow: API request → Capture → Encode → Return data
- Event propagation: Generate event → Process → Store → Query
- Cross-service: Collector → Database → API → Client

**Integration alerts**:
- Data flow interruptions
- API response time degradation  
- Database replication lag
- Service communication failures

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