#!/bin/bash

# WoL wake script
# This script sends a Wake-on-LAN magic packet to your Mac

MAC_ADDRESS="1a:29:89:7:5b:98"
BROADCAST_IP="192.168.0.255"
LOG_FILE="/tmp/wol-wake.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "Attempting to wake Mac at $MAC_ADDRESS"

# Try different WoL methods
if command -v wakeonlan &> /dev/null; then
    wakeonlan "$MAC_ADDRESS" && log "WoL sent using wakeonlan"
elif command -v ether-wake &> /dev/null; then
    ether-wake "$MAC_ADDRESS" && log "WoL sent using ether-wake"  
else
    # Fallback to manual construction using nc
    # Convert MAC to magic packet format
    MAGIC_PACKET=$(printf 'f%.0s' {1..12} | sed 's/./\\x&/g' ; 
    for i in {1..16}; do
        printf "$(echo $MAC_ADDRESS | sed 's/://g' | sed 's/../\\x&/g')"
    done)
    
    echo -ne "$MAGIC_PACKET" | nc -u -b "$BROADCAST_IP" 9 && log "WoL sent manually"
fi

log "WoL command completed"