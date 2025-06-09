#!/bin/bash
# Athena Centralized Logger
# Simple log aggregation that all components can use

ATHENA_LOG_DIR="${ATHENA_LOG_DIR:-/Users/j/Code/athena/logs}"
LOG_FILE="$ATHENA_LOG_DIR/athena.log"

# Ensure log directory exists
mkdir -p "$ATHENA_LOG_DIR"

# Log function
athena_log() {
    local level="$1"
    local component="$2" 
    local message="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    echo "[$timestamp] [$level] [$component] $message" | tee -a "$LOG_FILE"
}

# Convenience functions
log_info() { athena_log "INFO" "$1" "$2"; }
log_warn() { athena_log "WARN" "$1" "$2"; }
log_error() { athena_log "ERROR" "$1" "$2"; }
log_debug() { athena_log "DEBUG" "$1" "$2"; }

# If called directly, log the message
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    athena_log "${1:-INFO}" "${2:-athena}" "${3:-No message provided}"
fi