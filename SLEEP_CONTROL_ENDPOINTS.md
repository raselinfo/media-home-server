# Sleep Control Endpoints Documentation

## ✅ Sleep Control Server Ready!

Your Mac now has **HTTP endpoints to control sleep mode** while it's always on.

## 🚀 Available Endpoints

### 1. **Disable Sleep (Keep Mac Awake)**
```bash
curl http://192.168.0.113:8099/disable
```

**Response:**
```json
{
  "success": true,
  "message": "Sleep disabled - Mac will stay awake"
}
```

### 2. **Enable Sleep (Allow Normal Sleep)**
```bash
curl http://192.168.0.113:8099/enable
```

**Response:**
```json
{
  "success": true,
  "message": "Sleep enabled - Mac can sleep normally"
}
```

### 3. **Check Sleep Status**
```bash
curl http://192.168.0.113:8099/status
```

**Response:**
```json
{
  "success": true,
  "sleep_disabled": true,
  "status": "disabled",
  "message": "Sleep disabled - caffeinate active"
}
```

## 🔧 How It Works

The sleep control server:
1. **Runs on port 8099** alongside Jellyfin (port 8096)
2. **Uses `caffeinate` command** to prevent sleep
3. **Manages background processes** to keep Mac awake
4. **Allows normal sleep** when you want to save energy

## 📱 Usage Examples

### **Manual Control:**
```bash
# Disable sleep (keep Mac awake for media server)
curl http://192.168.0.113:8099/disable

# Enable sleep (allow Mac to sleep normally)  
curl http://192.168.0.113:8099/enable

# Check current status
curl http://192.168.0.113:8099/status
```

### **Automation Examples:**

**Keep Mac awake during business hours:**
```bash
# 9 AM - Disable sleep
0 9 * * * curl http://192.168.0.113:8099/disable

# 10 PM - Enable sleep  
0 22 * * * curl http://192.168.0.113:8099/enable
```

**Keep Mac awake when streaming:**
```bash
# Disable sleep before movie night
curl http://192.168.0.113:8099/disable

# Enable sleep after movie
curl http://192.168.0.113:8099/enable
```

## 🎯 Integration with Jellyfin

**Perfect workflow:**
1. Keep Mac always awake: `curl http://192.168.0.113:8099/disable`
2. Access Jellyfin: `http://192.168.0.113:8096`
3. When done, allow sleep: `curl http://192.168.0.113:8099/enable`

## 🛡️ Safety Features

- **Non-destructive**: Uses `caffeinate` instead of system settings
- **Reversible**: Can re-enable sleep anytime  
- **Process tracking**: Monitors caffeinate PID
- **Status checking**: Verify current sleep state

## 📊 Monitoring

Check if sleep control is working:
```bash
# Check caffeinate process
ps aux | grep caffeinate

# Check sleep control logs
cat /tmp/sleep-control.log

# Check current status via HTTP
curl http://192.168.0.113:8099/status
```

## 🔧 Troubleshooting

**If endpoints don't respond:**
```bash
# Check if server is running
ps aux | grep sleep-control-server

# Restart server
pkill -f sleep-control-server
python3 /Users/raselhossain/projects/jellyfin/sleep-control-server.py &
```

**If sleep doesn't disable:**
```bash
# Manual caffeinate test
caffeinate -i -d -s &
```

## 🎉 Benefits

✅ **Energy efficient** - Enable sleep when not needed
✅ **Always available** - Jellyfin ready when sleep disabled  
✅ **Remote control** - Manage from any device
✅ **Simple API** - Easy HTTP endpoints
✅ **Safe operation** - Uses standard macOS commands

## 📝 Notes

- **Server port**: 8099
- **Method**: Uses `caffeinate` command
- **Persistence**: Survives server restarts
- **Platform**: macOS-specific

You now have full control over your Mac's sleep behavior via simple HTTP requests! 🎊