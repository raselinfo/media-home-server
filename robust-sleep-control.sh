#!/bin/bash

# Robust Sleep Control Server
# Uses nohup to ensure caffeinate stays running

disable_sleep() {
    echo '{"success": true, "message": "Sleep disabled - caffeinate started"}'
    
    # Kill any existing caffeinate
    pkill -9 caffeinate 2>/dev/null
    
    # Start caffeinate with nohup to keep it running
    nohup caffeinate -i -d -s > /dev/null 2>&1 &
    
    # Save the PID
    echo $! > /tmp/caffeinate.pid
    
    # Verify it's running
    sleep 1
    if pgrep caffeinate > /dev/null; then
        echo "Status: Caffeinate started successfully"
    else
        echo "Error: Caffeinate failed to start"
    fi
}

enable_sleep() {
    echo '{"success": true, "message": "Sleep enabled - caffeinate stopped"}'
    
    # Kill caffeinate
    pkill -9 caffeinate 2>/dev/null
    rm -f /tmp/caffeinate.pid
    
    echo "Status: Sleep enabled"
}

get_status() {
    if pgrep caffeinate > /dev/null; then
        PID=$(cat /tmp/caffeinate.pid 2>/dev/null || echo "unknown")
        echo "{\"success\": true, \"sleep_disabled\": true, \"status\": \"disabled\", \"message\": \"Sleep disabled - caffeinate running (PID: $PID)\"}"
    else
        echo '{"success": true, "sleep_disabled": false, "status": "enabled", "message": "Sleep enabled"}'
    fi
}

# Simple HTTP server
while true; do
    REQUEST=$(echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n" | nc -l -p 8099)
    
    if [ -n "$REQUEST" ]; then
        # Extract the path from GET request
        PATH=$(echo "$REQUEST" | grep "GET" | head -1 | cut -d' ' -f2)
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Request: $PATH" >> /tmp/sleep-control.log
        
        case "$PATH" in
            /disable)
                disable_sleep
                ;;
            /enable)
                enable_sleep
                ;;
            /status)
                get_status
                ;;
            *)
                echo '{"success": true, "message": "Sleep Control Server", "endpoints": {"/status": "Check status", "/disable": "Disable sleep", "/enable": "Enable sleep"}}'
                ;;
        esac
    fi
done