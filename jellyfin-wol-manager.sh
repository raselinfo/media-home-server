#!/bin/bash

# Jellyfin WoL Manager
# This script handles Wake-on-LAN for your Jellyfin server

MAC_ADDRESS="1a:29:89:7:5b:98"
TARGET_IP="192.168.0.113"
TARGET_PORT=8096
LOG_FILE="/Users/raselhossain/projects/jellyfin/wol.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_jellyfin() {
    curl -s --connect-timeout 2 "http://$TARGET_IP:$TARGET_PORT/health" > /dev/null 2>&1
    return $?
}

send_wol() {
    log "🔔 Sending WoL packet to $MAC_ADDRESS"
    
    # Method 1: Use wakeonlan if available
    if command -v wakeonlan &> /dev/null; then
        wakeonlan "$MAC_ADDRESS" && log "✅ WoL sent using wakeonlan" && return 0
    fi
    
    # Method 2: Use ether-wake if available  
    if command -v ether-wake &> /dev/null; then
        ether-wake "$MAC_ADDRESS" && log "✅ WoL sent using ether-wake" && return 0
    fi
    
    # Method 3: Manual magic packet construction
    MAC_NO_COLONS=$(echo "$MAC_ADDRESS" | sed 's/://g')
    
    # Create magic packet: 6 x FF + 16 x MAC address
    { 
        printf 'f%.0s' {1..6}
        for i in {1..16}; do
            printf "$MAC_NO_COLONS"
        done
    } | xxd -r -p | nc -u -b 192.168.0.255 9
    
    log "✅ WoL sent using manual method"
    return 0
}

wait_for_wake() {
    local timeout=120
    local elapsed=0
    
    log "⏳ Waiting for Jellyfin to wake (timeout: ${timeout}s)"
    
    while [ $elapsed -lt $timeout ]; do
        if check_jellyfin; then
            log "✅ Jellyfin is awake and responding!"
            return 0
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
        
        # Progress indicator every 10 seconds
        if [ $((elapsed % 10)) -eq 0 ]; then
            log "⏳ Still waiting... (${elapsed}/${timeout}s)"
        fi
    done
    
    log "❌ Timeout - Jellyfin did not wake in time"
    return 1
}

start_caffeinate() {
    log "☕ Starting caffeinate to keep Mac awake"
    
    # Run caffeinate in background and save PID
    caffeinate -i -w -d -s &
    CAFFEINATE_PID=$!
    echo $CAFFEINATE_PID > /tmp/jellyfin-caffeinate.pid
    log "☕ Caffeinate started (PID: $CAFFEINATE_PID)"
}

main() {
    log "🎬 Jellyfin WoL Manager started"
    
    if check_jellyfin; then
        log "✅ Jellyfin is already running - no wake needed"
        start_caffeinate
        exit 0
    fi
    
    log "😴 Jellyfin is asleep - initiating wake sequence"
    
    if send_wol; then
        if wait_for_wake; then
            start_caffeinate
            log "🎉 Jellyfin is ready for use!"
        else
            log "❌ Failed to wake Jellyfin"
            exit 1
        fi
    else
        log "❌ Failed to send WoL"
        exit 1
    fi
}

# Run main function
main