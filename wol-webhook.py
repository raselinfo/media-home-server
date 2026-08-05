#!/usr/bin/env python3
"""
Simple WoL Webhook Server
Listens for HTTP requests and triggers Wake-on-LAN for Jellyfin
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import socket
import time
from urllib.parse import urlparse, parse_qs

MAC_ADDRESS = "1a:29:89:7:5b:98"
TARGET_IP = "192.168.0.113"
TARGET_PORT = 8096
SERVER_PORT = 8098

def send_wol():
    """Send Wake-on-LAN magic packet"""
    try:
        # Construct magic packet
        mac_bytes = bytes.fromhex(MAC_ADDRESS.replace(':', ''))
        magic_packet = b'\xff' * 6 + mac_bytes * 16
        
        # Send via UDP broadcast
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.sendto(magic_packet, ('192.168.0.255', 9))
        sock.close()
        
        print(f"[{time.ctime()}] WoL sent to {MAC_ADDRESS}")
        return True
    except Exception as e:
        print(f"[{time.ctime()}] WoL failed: {e}")
        return False

def check_jellyfin():
    """Check if Jellyfin is responding"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex((TARGET_IP, TARGET_PORT))
        sock.close()
        return result == 0
    except:
        return False

class WoLHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = urlparse(self.path).path
        
        if path == '/wake':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            
            if check_jellyfin():
                self.wfile.write(b'Jellyfin is already awake')
                print(f"[{time.ctime()}] Wake request - Jellyfin already awake")
            else:
                if send_wol():
                    self.wfile.write(b'WoL sent - waiting for wake...')
                    # Wait for wake
                    for i in range(60):
                        time.sleep(2)
                        if check_jellyfin():
                            print(f"[{time.ctime()}] Jellyfin is awake!")
                            break
                else:
                    self.wfile.write(b'WoL failed')
                    
        elif path == '/health':
            if check_jellyfin():
                self.send_response(200)
                self.wfile.write(b'OK')
            else:
                self.send_response(503)
                self.wfile.write(b'Service Unavailable')
        else:
            self.send_response(404)
            self.wfile.write(b'Not Found')
    
    def log_message(self, format, *args):
        print(f"[{time.ctime()}] {args[0]}")

def main():
    server = HTTPServer(('0.0.0.0', SERVER_PORT), WoLHandler)
    print(f"[{time.ctime()}] WoL Webhook Server starting on port {SERVER_PORT}")
    print(f"[{time.ctime()}] Target: {TARGET_IP}:{TARGET_PORT} ({MAC_ADDRESS})")
    print(f"[{time.ctime()}] Endpoints: http://localhost:{SERVER_PORT}/wake, /health")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print(f"\n[{time.ctime()}] Server stopped")

if __name__ == '__main__':
    main()