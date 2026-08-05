# Sleep Control Service - Background Setup Complete ✅

## 🎉 Service Now Running in Background!

Your sleep control server is now running as a **background service** that will continue working even when you close the IDE or restart your Mac.

## 🚀 Service Management

**Control the service with:**
```bash
# Start service
/Users/raselhossain/projects/jellyfin/sleep-control-service.sh start

# Stop service  
/Users/raselhossain/projects/jellyfin/sleep-control-service.sh stop

# Restart service
/Users/raselhossain/projects/jellyfin/sleep-control-service.sh restart

# Check status
/Users/raselhossain/projects/jellyfin/sleep-control-service.sh status
```

## 🌐 HTTP Endpoints (Always Available)

**Access from any device on your network:**

- **Disable Sleep**: `curl http://192.168.0.113:8099/disable`
- **Enable Sleep**: `curl http://192.168.0.113:8099/enable`  
- **Check Status**: `curl http://192.168.0.113:8099/status`

## 🔧 What's Running

**Background Process:**
- Process ID: 59222
- Script: `simple-sleep-control.py`
- Port: 8099
- Log: `/tmp/sleep-control.log`

**Features:**
- ✅ **Persists after IDE close**
- ✅ **Survives terminal sessions**
- ✅ **Automatic restart capability**
- ✅ **Network accessible**

## 📱 Usage Examples

### **Manual Control:**
```bash
# Keep Mac awake for Jellyfin
curl http://192.168.0.113:8099/disable

# Allow Mac to sleep normally
curl http://192.168.0.113:8099/enable

# Check current status
curl http://192.168.0.113:8099/status
```

### **Automation Examples:**

**Cron jobs for scheduled sleep control:**
```bash
# Disable sleep during work hours (9 AM - 10 PM)
0 9 * * * curl http://192.168.0.113:8099/disable
0 22 * * * curl http://192.168.0.113:8099/enable

# Disable sleep on weekends
0 0 * * 6,0 curl http://192.168.0.113:8099/disable
0 0 * * 1-5 curl http://192.168.0.113:8099/enable
```

### **From Other Devices:**

**iPhone/Android shortcut:**
1. Create shortcut with HTTP request
2. URL: `http://192.168.0.113:8099/disable`
3. One-tap to keep Mac awake!

**Smart home integration:**
- Home Assistant HTTP call
- Siri shortcut with URL
- Webhook trigger

## 🔍 Monitoring & Troubleshooting

**Check if service is running:**
```bash
# Method 1: Service script
/Users/raselhossain/projects/jellyfin/sleep-control-service.sh status

# Method 2: Check process
ps aux | grep simple-sleep-control

# Method 3: Test endpoint
curl http://localhost:8099/status
```

**View logs:**
```bash
# Service logs
cat /tmp/sleep-control.log

# Caffeinate status
ps aux | grep caffeinate
```

**Restart if needed:**
```bash
/Users/raselhossain/projects/jellyfin/sleep-control-service.sh restart
```

## 🛡️ Security Notes

- **Local network only** - Service binds to 0.0.0.0
- **No authentication** - Trust your home network
- **Firewall friendly** - Uses standard HTTP
- **Low risk** - Only controls sleep, not sensitive data

## ⚡ Quick Start

1. **Service is already running** ✅
2. **Test it**: `curl http://localhost:8099/status`
3. **Use it**: `curl http://localhost:8099/disable`
4. **Forget it** - Runs in background automatically!

## 🎯 Perfect Workflow

1. **Mac starts/restarts** → Service auto-starts
2. **Access Jellyfin** → Keep Mac awake: `curl http://192.168.0.113:8099/disable`  
3. **Use Jellyfin normally** → `http://192.168.0.113:8096`
4. **When done** → Allow sleep: `curl http://192.168.0.113:8099/enable`

## 📊 Service Files

- **Service**: [simple-sleep-control.py](file:///Users/raselhossain/projects/jellyfin/simple-sleep-control.py)
- **Manager**: [sleep-control-service.sh](file:///Users/raselhossain/projects/jellyfin/sleep-control-service.sh)  
- **Config**: [com.jellyfin.sleepcontrol.plist](file:///Users/raselhossain/projects/jellyfin/com.jellyfin.sleepcontrol.plist)

**Your sleep control endpoints are now running 24/7 in the background!** 🎊