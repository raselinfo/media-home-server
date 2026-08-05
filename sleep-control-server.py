#!/usr/bin/env python3
"""
Sleep Control Server
HTTP endpoints to enable/disable Mac sleep mode
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import json
from urllib.parse import urlparse, parse_qs

SERVER_PORT = 8099

def disable_sleep():
    """Disable Mac sleep mode"""
    try:
        # Prevent system sleep using caffeinate command instead
        # Check if caffeinate is already running
        result = subprocess.run(['pgrep', 'caffeinate'], capture_output=True)
        if result.returncode == 0:
            return {"success": True, "message": "Sleep mode already disabled - caffeinate is running"}
        
        # Start caffeinate in background
        subprocess.run(['caffeinate', '-i', '-d', '-s', '&'], shell=True, check=True)
        return {"success": True, "message": "Sleep mode disabled - Mac will stay awake using caffeinate"}
    except Exception as e:
        return {"success": False, "message": f"Failed to disable sleep: {str(e)}"}

def enable_sleep():
    """Enable Mac sleep mode"""
    try:
        # Kill caffeinate processes to allow normal sleep
        subprocess.run(['pkill', 'caffeinate'], check=False)
        return {"success": True, "message": "Sleep mode enabled - Mac can sleep normally"}
    except Exception as e:
        return {"success": False, "message": f"Failed to enable sleep: {str(e)}"}

def get_sleep_status():
    """Get current sleep status"""
    try:
        result = subprocess.run(['pgrep', 'caffeinate'], capture_output=True)
        caffeinate_running = result.returncode == 0
        return {
            "success": True, 
            "sleep_disabled": caffeinate_running,
            "status": "disabled" if caffeinate_running else "enabled",
            "message": f"Sleep is {'disabled (caffeinate active)' if caffeinate_running else 'enabled (Mac can sleep)'}",
            "method": "caffeinate"
        }
    except Exception as e:
        return {"success": False, "message": f"Failed to get status: {str(e)}"}

class SleepControlHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = urlparse(self.path).path
        
        response_data = {"success": False, "message": "Invalid endpoint"}
        status_code = 404
        
        if path == '/status':
            response_data = get_sleep_status()
            status_code = 200
            
        elif path == '/disable':
            response_data = disable_sleep()
            status_code = 200
            
        elif path == '/enable':
            response_data = enable_sleep()
            status_code = 200
            
        elif path == '/':
            response_data = {
                "success": True,
                "message": "Sleep Control Server",
                "endpoints": {
                    "/status": "Get current sleep status",
                    "/disable": "Disable sleep (keep Mac awake)",
                    "/enable": "Enable sleep (normal behavior)"
                }
            }
            status_code = 200
            
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        if isinstance(response_data, dict):
            response_data['timestamp'] = str(subprocess.run(['date', '+%Y-%m-%d %H:%M:%S'], capture_output=True, text=True).stdout.strip())
            self.wfile.write(json.dumps(response_data, indent=2).encode())
        else:
            self.wfile.write(str(response_data).encode())
    
    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {args[0]}")

def main():
    server = HTTPServer(('0.0.0.0', SERVER_PORT), SleepControlHandler)
    print(f"[{subprocess.run(['date'], capture_output=True, text=True).stdout.strip()}] Sleep Control Server starting on port {SERVER_PORT}")
    print(f"Available endpoints:")
    print(f"  http://localhost:{SERVER_PORT}/status - Check sleep status")
    print(f"  http://localhost:{SERVER_PORT}/disable - Disable sleep")
    print(f"  http://localhost:{SERVER_PORT}/enable - Enable sleep")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print(f"\n[{subprocess.run(['date'], capture_output=True, text=True).stdout.strip()}] Sleep Control Server stopped")

if __name__ == '__main__':
    main()