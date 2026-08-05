#!/usr/bin/env python3
"""
Simple Sleep Control Server
Fixed version with direct command execution
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import json
import signal
import sys

SERVER_PORT = 8099

def disable_sleep():
    """Disable Mac sleep mode using caffeinate"""
    try:
        # Check if caffeinate is already running
        result = subprocess.run(['pgrep', '-x', 'caffeinate'], capture_output=True, text=True)
        if result.returncode == 0:
            return {"success": True, "message": "Sleep already disabled - caffeinate is running"}
        
        # Start caffeinate in background
        subprocess.Popen(['caffeinate', '-i', '-d', '-s'], 
                       stdout=subprocess.DEVNULL, 
                       stderr=subprocess.DEVNULL,
                       start_new_session=True)
        return {"success": True, "message": "Sleep disabled - caffeinate started"}
    except Exception as e:
        return {"success": False, "message": f"Failed to disable sleep: {str(e)}"}

def enable_sleep():
    """Enable Mac sleep mode by killing caffeinate"""
    try:
        subprocess.run(['pkill', '-x', 'caffeinate'], check=False)
        return {"success": True, "message": "Sleep enabled - caffeinate stopped"}
    except Exception as e:
        return {"success": False, "message": f"Failed to enable sleep: {str(e)}"}

def get_sleep_status():
    """Get current sleep status"""
    try:
        result = subprocess.run(['pgrep', '-x', 'caffeinate'], capture_output=True, text=True)
        caffeinate_running = result.returncode == 0
        return {
            "success": True, 
            "sleep_disabled": caffeinate_running,
            "status": "disabled" if caffeinate_running else "enabled",
            "message": f"Sleep is {'disabled (caffeinate active)' if caffeinate_running else 'enabled'}"
        }
    except Exception as e:
        return {"success": False, "message": f"Failed to get status: {str(e)}"}

class SleepControlHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path
        
        response_data = {"success": False, "message": "Invalid endpoint"}
        
        if path == '/status':
            response_data = get_sleep_status()
        elif path == '/disable':
            response_data = disable_sleep()
        elif path == '/enable':
            response_data = enable_sleep()
        elif path == '/':
            response_data = {
                "success": True,
                "message": "Sleep Control Server",
                "endpoints": {
                    "/status": "Check sleep status",
                    "/disable": "Disable sleep", 
                    "/enable": "Enable sleep"
                }
            }
        
        # Send response
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(response_data, indent=2).encode())
    
    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {args[0]}")

def signal_handler(sig, frame):
    print('\nServer stopped gracefully')
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, signal_handler)
    
    server = HTTPServer(('0.0.0.0', SERVER_PORT), SleepControlHandler)
    print(f"Sleep Control Server starting on port {SERVER_PORT}")
    print(f"Available endpoints:")
    print(f"  http://localhost:{SERVER_PORT}/status")
    print(f"  http://localhost:{SERVER_PORT}/disable") 
    print(f"  http://localhost:{SERVER_PORT}/enable")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nServer stopped')

if __name__ == '__main__':
    main()