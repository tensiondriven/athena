#!/bin/bash

# AshChat Server Management Script

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

PORT=4000
PID_FILE="$SCRIPT_DIR/tmp/server.pid"
ERROR_LOG="$SCRIPT_DIR/tmp/error.log"

# Load environment variables if .env exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

check_server() {
    if lsof -i :$PORT -t >/dev/null 2>&1; then
        PID=$(lsof -i :$PORT -t)
        echo -e "${GREEN}✓ Server is running${NC} (PID: $PID on port $PORT)"
        
        # Check for errors
        if [ -f "$ERROR_LOG" ] && [ -s "$ERROR_LOG" ]; then
            ERROR_COUNT=$(grep -c "\\[error\\]" "$ERROR_LOG" 2>/dev/null || echo 0)
            if [ "$ERROR_COUNT" -gt 0 ]; then
                echo -e "${RED}⚠ $ERROR_COUNT errors in error log${NC} - Check: $ERROR_LOG"
            fi
        fi
        
        return 0
    else
        echo -e "${RED}✗ Server is not running${NC}"
        return 1
    fi
}

start_server() {
    if check_server >/dev/null 2>&1; then
        echo -e "${YELLOW}Server already running${NC}"
        check_server
        return 1
    fi
    
    # Check for OPENROUTER_API_KEY if using OpenRouter
    if [ "$USE_OPENROUTER" = "true" ] && [ -z "$OPENROUTER_API_KEY" ]; then
        echo -e "${YELLOW}Warning: OPENROUTER_API_KEY not set. Using Ollama instead.${NC}"
        export USE_OPENROUTER=false
    fi
    
    echo -e "${GREEN}Starting server...${NC}"
    mkdir -p tmp
    MIX_ENV=dev mix phx.server > tmp/server.log 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    
    # Wait for server to start
    echo -n "Waiting for server to start"
    for i in {1..10}; do
        sleep 1
        echo -n "."
        if lsof -i :$PORT -t >/dev/null 2>&1; then
            echo -e "\n${GREEN}✓ Server started successfully${NC}"
            echo "View logs: tail -f $SCRIPT_DIR/tmp/server.log"
            echo "Access at: http://localhost:$PORT"
            return 0
        fi
    done
    
    echo -e "\n${RED}Failed to start server${NC}"
    echo "Check logs: $SCRIPT_DIR/tmp/server.log"
    return 1
}

stop_server() {
    if ! check_server >/dev/null 2>&1; then
        echo -e "${YELLOW}Server not running${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Stopping server...${NC}"
    PID=$(lsof -i :$PORT -t)
    kill $PID 2>/dev/null
    
    # Wait for server to stop
    for i in {1..5}; do
        sleep 1
        if ! lsof -i :$PORT -t >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Server stopped${NC}"
            rm -f "$PID_FILE"
            return 0
        fi
    done
    
    echo -e "${RED}Server didn't stop gracefully, forcing...${NC}"
    kill -9 $PID 2>/dev/null
    rm -f "$PID_FILE"
}

restart_server() {
    stop_server
    sleep 2
    start_server
}

logs() {
    if [ -f "$SCRIPT_DIR/tmp/server.log" ]; then
        tail -f "$SCRIPT_DIR/tmp/server.log"
    else
        echo -e "${RED}No log file found${NC}"
    fi
}

errors() {
    if [ -f "$ERROR_LOG" ] && [ -s "$ERROR_LOG" ]; then
        echo -e "${YELLOW}=== Error Log ===${NC}"
        cat "$ERROR_LOG"
        echo ""
        ERROR_COUNT=$(grep -c "\\[error\\]" "$ERROR_LOG" 2>/dev/null || echo 0)
        echo -e "Total errors: ${RED}$ERROR_COUNT${NC}"
    else
        echo -e "${GREEN}✓ No errors logged${NC}"
    fi
}

reset_db() {
    echo -e "${YELLOW}Resetting database...${NC}"
    rm -f ash_chat.db ash_chat.db-journal
    echo -e "${GREEN}✓ Database reset complete${NC}"
    echo "Database will be recreated on next server start"
}

demo() {
    echo -e "${GREEN}Running demo setup...${NC}"
    if ! check_server >/dev/null 2>&1; then
        echo "Starting server first..."
        start_server
        sleep 3
    fi
    mix run demo_retrigger_features.exs
}

case "$1" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        check_server
        ;;
    logs)
        logs
        ;;
    errors)
        errors
        ;;
    reset-db)
        reset_db
        ;;
    demo)
        demo
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|errors|reset-db|demo}"
        echo ""
        echo "  start    - Start the Phoenix server"
        echo "  stop     - Stop the Phoenix server"
        echo "  restart  - Restart the Phoenix server"
        echo "  status   - Check if server is running"
        echo "  logs     - Tail the server logs"
        echo "  errors   - Show error log"
        echo "  reset-db - Reset the SQLite database"
        echo "  demo     - Run demo setup with test data"
        exit 1
        ;;
esac