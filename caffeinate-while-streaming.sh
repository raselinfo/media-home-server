#!/bin/bash
# Keeps the MacBook awake (caffeinate) while anyone is streaming from Jellyfin.
# Stops caffeinate 30 minutes after the last stream ends, so the Mac can sleep.
# Fully automatic: API key is stored in .jf_api_key next to this script.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JF_URL="${JF_URL:-http://localhost:8096}"
JF_API_KEY="$(sed -n 's/^KEY=//p' "$SCRIPT_DIR/.jf_api_key")"
IDLE_MINUTES=30
POLL_SECONDS=60
CAFFEINATE_PID=""

while true; do
    playing=$(curl -sf -H "X-Emby-Token: $JF_API_KEY" \
        "$JF_URL/Sessions?activeWithinSeconds=120" \
        | /usr/bin/python3 -c '
import json,sys
try:
    sessions = json.load(sys.stdin)
except Exception:
    sys.exit(1)
for s in sessions:
    if s.get("NowPlayingItem") and s.get("PlayState", {}).get("IsPaused") is False:
        print("yes"); break
' 2>/dev/null)

    if [ "$playing" = "yes" ]; then
        LAST_PLAY_TIME=$(date +%s)
        if [ -z "$CAFFEINATE_PID" ]; then
            caffeinate -i -s &
            CAFFEINATE_PID=$!
            echo "$(date '+%Y-%m-%d %H:%M:%S') streaming detected -> caffeinate started (pid $CAFFEINATE_PID)"
        fi
    elif [ -n "$CAFFEINATE_PID" ]; then
        now=$(date +%s)
        idle=$(( (now - LAST_PLAY_TIME) / 60 ))
        if [ "$idle" -ge "$IDLE_MINUTES" ]; then
            kill "$CAFFEINATE_PID" 2>/dev/null
            CAFFEINATE_PID=""
            echo "$(date '+%Y-%m-%d %H:%M:%S') no streaming for ${idle} min -> caffeinate stopped"
        fi
    fi

    sleep "$POLL_SECONDS"
done
