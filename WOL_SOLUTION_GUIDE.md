# Wake-on-LAN Problem Solution Guide

## The Core Problem

When your MacBook sleeps, **all services stop**:
- Jellyfin (port 8096) - ❌ Stops
- Webhook server (port 8098) - ❌ Stops (can't send WoL!)

**Root Cause**: The WoL sender service is also on the sleeping Mac, creating a chicken-and-egg problem.

## Solutions (Choose One)

### Option 1: Manual WoL Script (Quick Fix)

**Use [simple-wol-sender.sh](file:///Users/raselhossain/projects/jellyfin/simple-wol-sender.sh)** from another device:

```bash
# From another Mac/Linux device on your network:
./simple-wol-sender.sh
```

**Requirements**: 
- Another device on your home network
- Device must have `wakeonlan` or `nc` (netcat) installed

### Option 2: Router-Based WoL (Best Solution)

**Configure your router to send WoL packets:**

1. Access router admin panel (usually `192.168.0.1` or `192.168.1.1`)
2. Look for "Wake on LAN" settings
3. Add your Mac's MAC address: `1a:29:89:7:5b:98`
4. Enable scheduled wake or manual wake

**Benefits**: Router is always on, reliable, and automatic

### Option 3: Raspberry Pi WoL Station (Robust Solution)

**Set up a dedicated WoL device:**

1. Get a Raspberry Pi (~$50)
2. Install minimal OS
3. Run the webhook server 24/7
4. Access: `http://raspberry-pi-ip:8098/wake`

**Benefits**: Always available, low power, custom automation

### Option 4: Smart Home Integration

**Use smart home devices:**

- **Home Assistant**: Add WoL integration
- **Smart plugs**: Trigger WoL when plug activated
- **Voice commands**: "Hey Google, wake my media server"

## Temporary Workaround

For now, use this **manual wake process**:

1. **Wake your Mac manually** (open lid, press key)
2. **Start services**:
   ```bash
   # Mac will auto-start Jellyfin (docker restart: unless-stopped)
   # Start webhook server:
   python3 /Users/raselhossain/projects/jellyfin/wol-webhook.py &
   ```
3. **Access Jellyfin**: `http://192.168.0.113:8096`

## Why Your Current Setup Won't Work

```
Sleeping Mac (192.168.0.113)
├── Jellyfin:8096 ❌ (sleeping)
└── Webhook:8098 ❌ (sleeping) ← Can't send WoL if it's asleep!
```

**You need an external WoL sender** that's awake when your Mac sleeps.

## Quick Test

Test WoL manually from another device:

```bash
# Install wakeonlan if needed
brew install wakeonlan  # macOS
# sudo apt install wakeonlan  # Linux

# Send WoL packet
wakeonlan 1a:29:89:7:5b:98
```

## Mac WoL Requirements Checklist

- [ ] **Power connected**: MacBooks must be plugged in for WoL
- [ ] **WoL enabled**: `sudo pmset -a wakeonlan 1` ✅ (already done)
- [ ] **Same network**: WoL sender and Mac on same WiFi/Ethernet
- [ ] **Not in deep sleep**: Energy Saver → "Wake for network access"

## Best Long-term Solution

**Invest in one of these:**
1. Router with WoL support (free if supported)
2. Raspberry Pi ($50)
3. Always-on PC/NUC

This ensures reliable wake-up without manual intervention.

## Files You Have

- ✅ [simple-wol-sender.sh](file:///Users/raselhossain/projects/jellyfin/simple-wol-sender.sh) - Manual wake script
- ✅ [wol-webhook.py](file:///Users/raselhossain/projects/jellyfin/wol-webhook.py) - Webhook server
- ✅ WoL enabled on Mac ✅

**Next step**: Choose a solution above and implement it!