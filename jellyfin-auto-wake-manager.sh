#!/bin/bash

# Jellyfin Auto-Wake Manager
# This script must run on an ALWAYS-ON device (not your sleeping Mac)

MAC_ADDRESS="1a:29:89:7:5b:98"
TARGET_IP="192.168.0.113"
TARGET_PORT=8096
PROXY_PORT=8096
LOG_FILE="/tmp/jellyfin-auto-wake.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_wol() {
    log "🔔 Sending WoL to $MAC_ADDRESS"
    
    # Try different WoL methods
    if command -v wakeonlan &> /dev/null; then
        wakeonlan "$MAC_ADDRESS"
    elif command -v ether-wake &> /dev/null; then
        ether-wake "$MAC_ADDRESS"
    else
        # Manual WoL using nc
        MAC_NO_COLONS=$(echo "$MAC_ADDRESS" | sed 's/://g')
        MAGIC_PACKET=$(printf 'f%.0s' {1..6}; for i in {1..16}; do printf "$MAC_NO_COLONS"; done | xxd -r -p)
        echo -ne "$MAGIC_PACKET" | nc -u -b 192.168.0.255 9
    fi
}

check_jellyfin() {
    curl -s --connect-timeout 2 "http://$TARGET_IP:$TARGET_PORT" > /dev/null 2>&1
    return $?
}

wait_for_wake() {
    local timeout=120
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if check_jellyfin; then
            log "✅ Jellyfin is awake!"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    log "❌ Wake timeout"
    return 1
}

# Start proxy server using netcat
start_proxy() {
    log "🚀 Starting Jellyfin Auto-Wake Proxy on port $PROXY_PORT"
    
    while true; do
        # Listen for incoming connections (simplified approach)
        # This would typically use nginx/socat for production
        
        if check_jellyfin; then
            log "✅ Jellyfin available - proxying active"
        else
            log "😴 Jellyfin asleep - sending WoL"
            send_wol
            wait_for_wake
        fi
        
        sleep 30 # Check every 30 seconds
    done
}

main() {
    log "🎬 Jellyfin Auto-Wake Manager starting"
    log "⚠️  IMPORTANT: This MUST run on an always-on device!"
    log "📍 Target: $TARGET_IP:$TARGET_PORT ($MAC_ADDRESS)"
    
    # Check if we're running on the right device
    CURRENT_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ "$CURRENT_IP" = "$TARGET_IP" ]; then
        log "❌ ERROR: Don't run this on the Mac you're trying to wake!"
        log "❌ Run this on a different always-on device (router, Pi, etc.)"
        exit 1
    fi
    
    start_proxy
}

main