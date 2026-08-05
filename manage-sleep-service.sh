#!/bin/bash

# Background Service Startup Script
# Ensures sleep control service runs continuously

SERVICE_SCRIPT="/Users/raselhossain/projects/jellyfin/simple-sleep-control.py"
PID_FILE="/tmp/sleep-control.pid"
LOG_FILE="/tmp/sleep-control.log"
SERVICE_PORT=8099

# Function to check if service is running
is_service_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Function to start service
start_service() {
    if is_service_running; then
        echo "✅ Service already running"
        return 0
    fi
    
    echo "🚀 Starting Sleep Control Service in background..."
    
    # Start service with nohup for background persistence
    nohup python3 "$SERVICE_SCRIPT" > "$LOG_FILE" 2>&1 &
    SERVICE_PID=$!
    echo $SERVICE_PID > "$PID_FILE"
    
    # Wait for service to start
    sleep 3
    
    # Verify service is running
    if is_service_running && curl -s "http://localhost:$SERVICE_PORT/status" > /dev/null 2>&1; then
        echo "✅ Sleep Control Service started successfully!"
        echo "📍 PID: $SERVICE_PID"
        echo "🌐 Port: $SERVICE_PORT"
        echo "📊 Status: http://localhost:$SERVICE_PORT/status"
        return 0
    else
        echo "❌ Failed to start service"
        echo "📋 Check logs: cat $LOG_FILE"
        return 1
    fi
}

# Function to stop service
stop_service() {
    if is_service_running; then
        PID=$(cat "$PID_FILE")
        echo "🛑 Stopping Sleep Control Service (PID: $PID)..."
        kill "$PID"
        rm -f "$PID_FILE"
        echo "✅ Service stopped"
    else
        echo "ℹ️  Service not running"
    fi
}

# Function to restart service
restart_service() {
    echo "🔄 Restarting Sleep Control Service..."
    stop_service
    sleep 2
    start_service
}

# Function to show status
show_status() {
    echo "📊 Sleep Control Service Status:"
    
    if is_service_running; then
        PID=$(cat "$PID_FILE")
        echo "✅ Service RUNNING (PID: $PID)"
        
        # Test HTTP endpoint
        if curl -s "http://localhost:$SERVICE_PORT/status" > /dev/null 2>&1; then
            echo "✅ HTTP endpoint responding"
            echo ""
            echo "📊 Current Status:"
            curl -s "http://localhost:$SERVICE_PORT/status" | python3 -m json.tool
        else
            echo "⚠️  Process running but HTTP not responding"
        fi
    else
        echo "❌ Service NOT running"
        echo "💡 Start with: $0 start"
    fi
}

# Main logic
case "${1:-status}" in
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
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the service in background"
        echo "  stop    - Stop the service"
        echo "  restart - Restart the service"
        echo "  status  - Show service status"
        exit 1
        ;;
esac