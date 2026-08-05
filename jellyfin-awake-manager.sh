#!/bin/bash

# Jellyfin Awake Manager
# This script keeps the Mac awake while Jellyfin is active and allows sleep when inactive

LOG_FILE="/tmp/jellyfin-awake.log"
CAFFEINATE_PID_FILE="/tmp/caffeinate.pid"
JELLYFIN_URL="http://192.168.0.113:8096"
CHECK_INTERVAL=60  # Check every minute
IDLE_TIMEOUT=300   # Allow sleep after 5 minutes of inactivity

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check if Jellyfin is active
is_jellyfin_active() {
    # Try to get active sessions from Jellyfin API
    ACTIVE_SESSIONS=$(curl -s "$JELLYFIN_URL/Sessions?api_key=your_api_key" | grep -c "ActiveSession")
    
    if [ "$ACTIVE_SESSIONS" -gt 0 ]; then
        log "Jellyfin has active sessions"
        return 0
    else
        log "No active Jellyfin sessions"
        return 1
    fi
}

# Function to start caffeinate
start_caffeinate() {
    if [ ! -f "$CAFFEINATE_PID_FILE" ]; then
        log "Starting caffeinate to prevent sleep"
        caffeinate -i -w -d -s &
        CAFFEINATE_PID=$!
        echo $CAFFEINATE_PID > "$CAFFEINATE_PID_FILE"
        log "Caffeinate started with PID: $CAFFEINATE_PID"
    fi
}

# Function to stop caffeinate
stop_caffeinate() {
    if [ -f "$CAFFEINATE_PID_FILE" ]; then
        CAFFEINATE_PID=$(cat "$CAFFEINATE_PID_FILE")
        log "Stopping caffeinate (PID: $CAFFEINATE_PID)"
        kill $CAFFEINATE_PID
        rm "$CAFFEINATE_PID_FILE"
        log "Caffeinate stopped - Mac can now sleep"
    fi
}

# Main loop
log "Jellyfin Awake Manager started"
LAST_ACTIVITY=$(date +%s)

while true; do
    if is_jellyfin_active; then
        start_caffeinate
        LAST_ACTIVITY=$(date +%s)
    else
        CURRENT_TIME=$(date +%s)
        IDLE_TIME=$((CURRENT_TIME - LAST_ACTIVITY))
        
        if [ $IDLE_TIME -gt $IDLE_TIMEOUT ]; then
            stop_caffeinate
        fi
    fi
    
    sleep $CHECK_INTERVAL
done