#!/bin/bash

# Sleep Control Service Manager
# Start/stop/restart the background sleep control service

SERVICE_SCRIPT="/Users/raselhossain/projects/jellyfin/simple-sleep-control.py"
PID_FILE="/tmp/sleep-control.pid"
LOG_FILE="/tmp/sleep-control.log"
SERVICE_PORT=8099

start_service() {
    echo "🚀 Starting Sleep Control Service..."
    
    # Check if already running
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ Service already running (PID: $PID)"
            return 0
        else
            rm -f "$PID_FILE"
        fi
    fi
    
    # Start service in background
    nohup python3 "$SERVICE_SCRIPT" > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    
    sleep 2
    
    # Verify it started
    if curl -s "http://localhost:$SERVICE_PORT/status" > /dev/null 2>&1; then
        echo "✅ Sleep Control Service started successfully!"
        echo "📍 Running on port: $SERVICE_PORT"
        echo "📊 Endpoints:"
        echo "   http://localhost:$SERVICE_PORT/status"
        echo "   http://localhost:$SERVICE_PORT/disable" 
        echo "   http://localhost:$SERVICE_PORT/enable"
    else
        echo "❌ Failed to start service"
        cat "$LOG_FILE"
        return 1
    fi
}

stop_service() {
    echo "🛑 Stopping Sleep Control Service..."
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill "$PID" 2>/dev/null
        rm -f "$PID_FILE"
        echo "✅ Service stopped"
    else
        # Try to find and kill the process
        pkill -f "simple-sleep-control.py"
        echo "✅ Service stopped (killed by name)"
    fi
}

restart_service() {
    echo "🔄 Restarting Sleep Control Service..."
    stop_service
    sleep 1
    start_service
}

status_service() {
    echo "📊 Sleep Control Service Status:"
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ Service running (PID: $PID)"
            
            # Test the endpoint
            if curl -s "http://localhost:$SERVICE_PORT/status" > /dev/null 2>&1; then
                echo "✅ HTTP endpoint responding"
                curl -s "http://localhost:$SERVICE_PORT/status" | python3 -m json.tool
            else
                echo "⚠️  Process running but HTTP not responding"
            fi
        else
            echo "❌ Service not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "❌ Service not running"
    fi
}

# Main command handling
case "${1:-start}" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        status_service
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac