#!/bin/bash
# Pre-transcodes media into phone-friendly copies so mobile playback Direct Plays
# instead of live-transcoding on the Mac CPU.
#
# - Only processes video files whose bitrate exceeds MOBILE_BITRATE (skips the rest).
# - Writes "<name> - Mobile.mp4" next to the original; Jellyfin groups it as an
#   alternate version and clients with a quality cap pick it automatically.
# - Skips files that already have a Mobile version. Re-run anytime; it resumes.
#
# Usage:
#   ./pretranscode.sh                 # whole library
#   ./pretranscode.sh /media/movie    # one folder (path as seen inside container)
#   ./pretranscode.sh --analyze       # report only, no encoding

CONTAINER=jellyfin
FF="/usr/lib/jellyfin-ffmpeg/ffmpeg"
PROBE="/usr/lib/jellyfin-ffmpeg/ffprobe"
MOBILE_BITRATE="3500k"   # target bitrate of mobile copies; also the skip threshold
HOST_MEDIA=/Users/raselhossain/projects/jellyfin/media
MODE=encode
[ "$1" = "--analyze" ] && MODE=analyze

# Resolve search roots: script accepts container paths (/media/...) or host paths.
ROOTS=()
for arg in "$@"; do
    [ "$arg" = "--analyze" ] && continue
    arg="${arg/#$HOST_MEDIA//media}"
    ROOTS+=("$arg")
done
[ ${#ROOTS[@]} -eq 0 ] && ROOTS+=("/media")

FILES=()
while IFS= read -r line; do FILES+=("$line"); done < <(docker exec "$CONTAINER" find "${ROOTS[@]}" -type f \
    \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.ts' \) \
    ! -name '* - Mobile.mp4' ! -name '._*' | sort)

total=${#FILES[@]}
n=0; encoded=0; skipped=0
for f in "${FILES[@]}"; do
    n=$((n+1))
    dir=$(dirname "$f"); base=$(basename "$f"); stem="${base%.*}"
    out="$dir/${stem} - Mobile.mp4"

    [ -f "$HOST_MEDIA${f#/media}" ] && [ -f "$HOST_MEDIA${out#/media}" ] && { skipped=$((skipped+1)); continue; }

    kbps=$(docker exec "$CONTAINER" "$PROBE" -v error -select_streams v:0 \
        -show_entries format=bit_rate -of csv=p=0 "$f" 2>/dev/null | head -1)
    kbps=$(( kbps / 1000 ))

    if [ "$kbps" -gt 0 ] && [ "$kbps" -le 3500 ]; then
        [ "$MODE" = analyze ] || skipped=$((skipped+1))
        [ "$MODE" = analyze ] && echo "SKIP (already low ${kbps}kbps): $f"
        continue
    fi

    if [ "$MODE" = analyze ]; then
        echo "WOULD ENCODE (${kbps}kbps -> ${MOBILE_BITRATE}): $f"
        continue
    fi

    echo "[$n/$total] Encoding (${kbps}kbps): $f"
    docker exec "$CONTAINER" "$FF" -hide_banner -loglevel error -y \
        -i "$f" -map 0:v:0 -map 0:a:0? \
        -c:v libx264 -preset superfast -b:v "$MOBILE_BITRATE" -maxrate "$MOBILE_BITRATE" -bufsize 7000k \
        -vf "scale='min(1280,iw)':-2" -profile:v high -level 4.0 \
        -c:a aac -b:a 128k -ac 2 \
        -movflags +faststart -f mp4 "$out" \
        && encoded=$((encoded+1)) \
        || echo "FAILED: $f"
done

echo "Done. files=$total encoded=$encoded skipped=$skipped"
