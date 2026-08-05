# Auto Wake-on-LAN Solution Requirements

## The Technical Reality

**You CANNOT access a sleeping device directly** because:
- Sleeping Mac = Network interface OFF
- No IP traffic can reach `192.168.0.113`
- Port 8096 cannot receive requests

## Working Solutions

### Solution 1: Router-Based WoL (Recommended)

**Requirements**: Router with WoL support

**Setup**:
1. Access router admin panel (192.168.0.1 or 192.168.1.1)
2. Find "Wake on LAN" or "Port Forwarding" settings
3. Configure:
   - External Port: 8096
   - Internal IP: 192.168.0.113
   - MAC Address: 1a:29:89:7:5b:98
   - Action: "Send WoL packet first, then forward"

**How it works**:
- Router receives request on port 8096
- Sends WoL to your Mac
- Forwards traffic once Mac wakes (2-3 minute delay)

### Solution 2: Always-On Proxy Device

**Requirements**: Device that never sleeps (Raspberry Pi, always-on PC)

**Setup**:
1. Install proxy on always-on device
2. Configure proxy to:
   - Listen on port 8096
   - Send WoL to `1a:29:89:7:5b:98` on first request
   - Wait 2-3 minutes for Mac wake
   - Forward subsequent requests to `192.168.0.113:8096`

### Solution 3: Manual Wake + Smart URL

**Setup smart DNS/URL that handles wake automatically**:

```
User types: http://jellyfin.home
├── DNS resolves to: always-on device (not sleeping Mac)
├── Device receives request
├── Sends WoL packet to Mac
└── Redirects to: http://192.168.0.113:8096 after wake
```

## Why Your Current Setup Won't Work

```
http://192.168.0.113:8096  ← Direct access to sleeping Mac
└── ❌ Cannot receive requests (network interface OFF)

http://proxy-device:8096    ← Access through always-on device  
├── ✅ Receives request (always awake)
├── ✅ Sends WoL to Mac
└── ✅ Forwards to Jellyfin after wake
```

## Alternative: Prevent Sleep Instead

**Keep your Mac awake 24/7**:

```bash
# Disable sleep when plugged in
sudo pmset -a disablesleep 1

# Or use caffeinate indefinitely
caffeinate -i &
```

## Bottom Line

**You absolutely need an always-on device** to:
1. Receive the initial HTTP request
2. Send WoL packet to your sleeping Mac  
3. Handle the 2-3 minute wake period
4. Forward requests to Jellyfin

**Options**:
- Router with WoL support (free if available)
- Raspberry Pi (~$50, low power)
- Always-on PC/server
- Smart home hub with WoL capability

There is **no software-only solution** that allows direct access to a sleeping device.