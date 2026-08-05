#!/bin/bash

# Simple WoL Sender
# Run this from any device on your network to wake your Mac

MAC_ADDRESS="1a:29:89:7:5b:98"
BROADCAST_IP="192.168.0.255"
TARGET_IP="192.168.0.113"
TARGET_PORT=8096

echo "🎬 WoL Sender - Target: $MAC_ADDRESS"

# Function to send WoL packet
send_wol() {
    echo "🔔 Sending WoL packet to $MAC_ADDRESS"
    
    # Method 1: Use wakeonlan if available
    if command -v wakeonlan &> /dev/null; then
        wakeonlan "$MAC_ADDRESS" && echo "✅ WoL sent using wakeonlan" && return 0
    fi
    
    # Method 2: Use ether-wake if available  
    if command -v ether-wake &> /dev/null; then
        ether-wake "$MAC_ADDRESS" && echo "✅ WoL sent using ether-wake" && return 0
    fi
    
    # Method 3: Manual magic packet using netcat
    MAC_NO_COLONS=$(echo "$MAC_ADDRESS" | sed 's/://g')
    
    # Create magic packet
    MAGIC_PACKET=""
    for i in {1..6}; do
        MAGIC_PACKET+="\xff"
    done
    for i in {1..16}; do
        MAGIC_PACKET+="\x${MAC_NO_COLONS:0:2}\x${MAC_NO_COLONS:2:2}\x${MAC_NO_COLONS:4:2}\x${MAC_NO_COLONS:6:2}\x${MAC_NO_COLONS:8:2}\x${MAC_NO_COLONS:10:2}"
    done
    
    # Send via UDP broadcast
    echo -ne "$MAGIC_PACKET" | nc -u -b "$BROADCAST_IP" 9
    echo "✅ WoL sent using netcat"
    return 0
}

# Function to check if target is awake
check_target() {
    if command -v curl &> /dev/null; then
        curl -s --connect-timeout 2 "http://$TARGET_IP:$TARGET_PORT" > /dev/null 2>&1
        return $?
    elif command -v nc &> /dev/null; then
        nc -z -w 2 "$TARGET_IP" "$TARGET_PORT" 2>/dev/null
        return $?
    fi
    return 1
}

# Main execution
send_wol

echo "⏳ Waiting for Mac to wake up (timeout: 120 seconds)..."

for i in {1..120}; do
    if check_target; then
        echo "✅ Mac is awake! Jellyfin should be available at http://$TARGET_IP:$TARGET_PORT"
        exit 0
    fi
    
    if [ $((i % 10)) -eq 0 ]; then
        echo "⏳ Still waiting... ($i/120 seconds)"
    fi
    
    sleep 1
done

echo "⚠️  Timeout - Mac did not wake within 2 minutes"
echo "💡 Troubleshooting tips:"
echo "   - Check if WoL is enabled in Mac Energy Saver settings"
echo "   - Make sure Mac is plugged into power (required for WoL on laptops)"
echo "   - Verify Mac and WoL sender are on same network"
echo "   - Try Ethernet instead of WiFi for more reliable WoL"