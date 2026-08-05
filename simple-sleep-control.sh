#!/bin/bash

# Simple Sleep Control HTTP Server
# Lightweight bash HTTP server for sleep control

MAC_ADDRESS="1a:29:89:7:5b:98"
SERVER_PORT=8099
LOG_FILE="/tmp/sleep-control.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

disable_sleep() {
    log "🔒 Disabling sleep mode"
    
    # Check if caffeinate is already running
    if pgrep caffeinate > /dev/null; then
        echo '{"success": true, "message": "Sleep already disabled - caffeinate running"}'
        return
    fi
    
    # Start caffeinate to prevent sleep
    caffeinate -i -d -s &
    CAFFEINATE_PID=$!
    echo $CAFFEINATE_PID > /tmp/caffeinate.pid
    
    log "✅ Sleep disabled - caffeinate started (PID: $CAFFEINATE_PID)"
    echo '{"success": true, "message": "Sleep disabled - Mac will stay awake"}'
}

enable_sleep() {
    log "🔓 Enabling sleep mode"
    
    # Kill caffeinate processes
    pkill caffeinate
    rm -f /tmp/caffeinate.pid
    
    log "✅ Sleep enabled - caffeinate stopped"
    echo '{"success": true, "message": "Sleep enabled - Mac can sleep normally"}'
}

get_status() {
    log "📊 Checking sleep status"
    
    if pgrep caffeinate > /dev/null; then
        CAFFEINATE_PID=$(cat /tmp/caffeinate.pid 2>/dev/null || echo "unknown")
        echo "{\"success\": true, \"sleep_disabled\": true, \"status\": \"disabled\", \"message\": \"Sleep disabled - caffeinate active (PID: $CAFFEINATE_PID)\"}"
    else
        echo '{"success": true, "sleep_disabled": false, "status": "enabled", "message": "Sleep enabled - Mac can sleep normally"}'
    fi
}

# Simple HTTP server using netcat
start_server() {
    log "🚀 Sleep Control Server starting on port $SERVER_PORT"
    
    while true; do
        # Listen for HTTP requests
        REQUEST=$(echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n" | nc -l -p $SERVER_PORT)
        
        if [ -n "$REQUEST" ]; then
            # Parse the request path
            PATH=$(echo "$REQUEST" | grep GET | head -1 | cut -d' ' -f2)
            
            log "📨 Request: $PATH"
            
            case "$PATH" in
                /status)
                    get_status
                    ;;
                /disable)
                    disable_sleep
                    ;;
                /enable)
                    enable_sleep
                    ;;
                /)
                    echo '{"success": true, "message": "Sleep Control Server", "endpoints": {"/status": "Check sleep status", "/disable": "Disable sleep", "/enable": "Enable sleep"}}'
                    ;;
                *)
                    echo '{"success": false, "message": "Invalid endpoint"}'
                    ;;
            esac
        fi
    done
}

# Start the server
start_server