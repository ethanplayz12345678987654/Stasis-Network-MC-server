#!/usr/bin/env bash
# deploy/get_public_ip.sh
# Prints the host public IP and helpful checks for exposing the Minecraft server to the internet.
# Usage: bash deploy/get_public_ip.sh
set -euo pipefail

echo "Checking Docker container and port mapping..."
if command -v docker >/dev/null 2>&1; then
  if docker ps --format '{{.Names}}' | grep -q '^mc_proxy$'; then
    echo "- Found mc_proxy container"
    echo "- Port mappings (docker ps | grep mc_proxy):"
    docker ps --filter "name=mc_proxy" --format '  {{.Names}}  {{.Ports}}'
  else
    echo "- mc_proxy container not found (docker ps didn't show it). Make sure you started the stack."
  fi
else
  echo "- docker not found in PATH. Can't inspect containers."
fi

# Get public IP
echo
PUBLIC_IP="$(curl -s https://ipinfo.io/ip || curl -s https://ifconfig.me || true)"
if [ -n "$PUBLIC_IP" ]; then
  echo "Public IP detected: $PUBLIC_IP"
  echo "Players can connect to: $PUBLIC_IP:25565"
else
  echo "Could not determine public IP (requests to external services failed)."
  echo "You can run 'curl https://ifconfig.me' or check your cloud provider dashboard."
fi

# Local LAN IP
echo
if command -v hostname >/dev/null 2>&1; then
  LAN_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  if [ -n "$LAN_IP" ]; then
    echo "Local LAN IP (for LAN players): $LAN_IP:25565"
  fi
fi

cat <<EOF

Checklist to allow other people to play (public/internet):

1) Ensure host port 25565 is open and forwarded to this machine.
   - If you're on a VPS/cloud provider: make sure the provider's security group / firewall allows inbound TCP on port 25565.
   - If you're behind a home router: set up port forwarding from router WAN port 25565 -> this machine's LAN IP:25565.

2) Open the host firewall (example using ufw):
   sudo ufw allow 25565/tcp
   sudo ufw reload

3) Confirm Docker is publishing the port on 0.0.0.0:25565
   - docker ps should show a PORTS column like 0.0.0.0:25565->25565/tcp for mc_proxy.

4) Optional: use a DNS name
   - Create an A record pointing your domain (e.g., play.example.com) to the public IP.
   - If you want players to join without a port (standard 25565), they can use play.example.com.
   - For convenience with a different port, you can create a SRV record for _minecraft._tcp to map a domain to host+port.

5) If you serve Eagler (browser) clients via wss, consider adding TLS termination (Caddy/nginx) and proxying websockets to the proxy.
   - I can help add a Caddy service to docker-compose for automatic Let's Encrypt TLS and WebSocket proxying.

6) Test connectivity from outside your network:
   - Ask a friend to try connecting to $PUBLIC_IP:25565
   - Or use an external port scanning site (e.g., https://www.yougetsignal.com/tools/open-ports/) to check if port 25565 is reachable.

If you'd like, I can automatically:
- Add a small Caddy/nginx service into docker-compose for TLS & WSS termination.
- Add a script to automatically open ufw rules on the host (requires sudo, optional).
- Add a simple dynamic DNS / README snippet for common providers.

EOF
