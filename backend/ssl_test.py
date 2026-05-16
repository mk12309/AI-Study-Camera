import socket
import ssl

hostname = 'ac-nisxfek-shard-00-00.ttnxxc7.mongodb.net'
port = 27017

context = ssl.create_default_context()
context.check_hostname = False
context.verify_mode = ssl.CERT_NONE

try:
    print(f"Connecting to {hostname}:{port}...")
    with socket.create_connection((hostname, port)) as sock:
        print("TCP Connection Successful. Attempting SSL Wrap...")
        with context.wrap_socket(sock, server_hostname=hostname) as ssock:
            print(f"SSL Handshake Successful! Version: {ssock.version()}")
except Exception as e:
    print(f"FAILED: {e}")
