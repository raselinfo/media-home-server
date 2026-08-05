#!/bin/bash

# Simple caffeinate manager for Jellyfin WoL setup
# This keeps Mac awake after WoL wake for a set time period

LOG_FILE="/tmp/jellyfin-caffeinate.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Jellyfin caffeinate manager started" >> "$LOG_FILE"

# Keep Mac awake for 2 hours after starting
# You can adjust this time as needed
caffeinate -i -w -d -s -t 7200 >> "$LOG_FILE" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Caffeinate finished - Mac can sleep now" >> "$LOG_FILE"