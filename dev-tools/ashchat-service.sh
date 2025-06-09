#!/bin/bash

# AshChat Service Manager
# Usage: ./ashchat-service.sh {start|stop|restart|status|logs}

SERVICE_NAME="AshChat"
WORK_DIR="/Users/j/Code/athena/system/ash-ai/ash_chat"
PID_FILE="/tmp/ashchat.pid"
LOG_FILE="/Users/j/Code/athena/dev-tools/ashchat.log"
PORT=4000

start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "🟡 $SERVICE_NAME is already running (PID: $(cat "$PID_FILE"))"
        return 1
    fi

    echo "🚀 Starting $SERVICE_NAME..."
    
    # Kill any processes using our port
    lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
    
    cd "$WORK_DIR" || exit 1
    
    # Start in background and capture PID
    nohup mix phx.server > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    
    # Wait a moment and check if it started successfully
    sleep 3
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "✅ $SERVICE_NAME started successfully (PID: $(cat "$PID_FILE"))"
        echo "📊 Dashboard: http://localhost:$PORT/events"
        echo "🔍 API Health: http://localhost:$PORT/api/events/health"
    else
        echo "❌ $SERVICE_NAME failed to start"
        rm -f "$PID_FILE"
        return 1
    fi
}

stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo "🟡 $SERVICE_NAME is not running"
        return 1
    fi

    PID=$(cat "$PID_FILE")
    echo "🛑 Stopping $SERVICE_NAME (PID: $PID)..."
    
    if kill -TERM "$PID" 2>/dev/null; then
        # Wait for graceful shutdown
        for i in {1..10}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        
        # Force kill if still running
        if kill -0 "$PID" 2>/dev/null; then
            echo "⚠️  Forcing shutdown..."
            kill -KILL "$PID" 2>/dev/null
        fi
        
        rm -f "$PID_FILE"
        echo "✅ $SERVICE_NAME stopped"
    else
        echo "❌ Failed to stop $SERVICE_NAME"
        rm -f "$PID_FILE"
        return 1
    fi
}

status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        PID=$(cat "$PID_FILE")
        echo "🟢 $SERVICE_NAME is running (PID: $PID)"
        
        # Check if port is actually responding
        if curl -s http://localhost:$PORT/api/events/health >/dev/null 2>&1; then
            echo "🌐 API is responding on port $PORT"
        else
            echo "⚠️  Process running but API not responding"
        fi
    else
        echo "🔴 $SERVICE_NAME is not running"
        [ -f "$PID_FILE" ] && rm -f "$PID_FILE"
        return 1
    fi
}

logs() {
    echo "📋 Showing logs (Ctrl+C to exit):"
    tail -f "$LOG_FILE"
}

restart() {
    echo "🔄 Restarting $SERVICE_NAME..."
    stop
    sleep 2
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the AshChat server"
        echo "  stop    - Stop the AshChat server"
        echo "  restart - Restart the AshChat server"
        echo "  status  - Check if server is running"
        echo "  logs    - Show server logs (tail -f)"
        exit 1
        ;;
esac