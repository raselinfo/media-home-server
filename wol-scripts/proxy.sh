#!/bin/bash

# WoL HTTP Proxy
# A simple proxy that listens for Jellyfin requests and sends WoL if needed

MAC_ADDRESS="1a:29:89:7:5b:98"
TARGET_IP="192.168.0.113"
TARGET_PORT=8096
PROXY_PORT=8096
WAKE_TIMEOUT=120  # 2 minutes

check_target() {
    curl -s --connect-timeout 2 "http://$TARGET_IP:$TARGET_PORT/health" > /dev/null
    return $?
}

send_wol() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sending WoL to $MAC_ADDRESS"
    
    # Construct magic packet
    MAC_HEX=$(echo "$MAC_ADDRESS" | sed 's/://g')
    
    # Create magic packet: 6 bytes of FF followed by 16 repetitions of MAC address
    MAGIC_PACKET=""
    for i in {1..6}; do
        MAGIC_PACKET+="\xff"
    done
    for i in {1..16}; do
        MAGIC_PACKET+="\x${MAC_HEX:0:2}\x${MAC_HEX:2:2}\x${MAC_HEX:4:2}\x${MAC_HEX:6:2}\x${MAC_HEX:8:2}\x${MAC_HEX:10:2}"
    done
    
    # Send via broadcast
    echo -ne "$MAGIC_PACKET" | nc -u -b 192.168.0.255 9
}

proxy_request() {
    # Read the request
    read -r METHOD PATH VERSION
    
    # Check if target is awake
    if check_target; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Target is awake, proxying request"
        # Forward the request to target
        curl -s "$METHOD" "http://$TARGET_IP:$TARGET_PORT$PATH"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Target is asleep, sending WoL"
        send_wol
        
        # Wait for target to wake up
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for target to wake (timeout: ${WAKE_TIMEOUT}s)"
        
        for ((i=0; i<WAKE_TIMEOUT; i++)); do
            if check_target; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Target is awake! Proxying request"
                curl -s "$METHOD" "http://$TARGET_IP:$TARGET_PORT$PATH"
                return
            fi
            sleep 1
        done
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Target failed to wake in time"
        echo "HTTP/1.1 503 Service Unavailable"
        echo "Content-Type: text/plain"
        echo ""
        echo "Jellyfin server is waking up. Please try again in a moment."
    fi
}

# Start the proxy server
echo "[$(date '+%Y-%m-%d %H:%M:%S')] WoL Proxy starting on port $PROXY_PORT"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Target: $TARGET_IP:$TARGET_PORT ($MAC_ADDRESS)"

while true; do
    proxy_request
done