Expose the server to public players — guide

This repository includes the docker-compose stack for the Minecraft server and proxy. To allow other people on the internet to join your server, follow these steps and checks.

1) Ensure the server is running and docker exposes port 25565
- Start the stack (if not already):
  ./deploy/start.sh
- Confirm mc_proxy is running and the port mapping is present:
  docker ps | grep mc_proxy
  You should see a mapping like: 0.0.0.0:25565->25565/tcp

2) Check your public IP
- Run the helper:
  bash deploy/get_public_ip.sh
- It prints the public IP and suggested connection string (e.g., 203.0.113.45:25565).

3) Open firewall and port-forward
- On cloud/VPS providers (AWS, GCP, DigitalOcean, etc): open inbound TCP port 25565 in the provider firewall/security group.
- On a home router: set up port forwarding from WAN port 25565 to the host machine's LAN IP port 25565.
- On the host machine, allow the port (example with ufw):
  sudo ufw allow 25565/tcp
  sudo ufw reload

4) (Optional) Use an easy-to-remember domain
- Create an A record for your domain (e.g., play.phoenixsmp.example) that points to your public IP.
- Players can then connect using play.example.com:25565. If you wish to avoid requiring a port in the address, use the default 25565 port.
- To use a different port and still let players join via a domain without adding the port, you can create an SRV record for Minecraft. Example SRV for minecraft:
  Service: _minecraft
  Protocol: _tcp
  Name: play
  Target: play.example.com
  Port: 25565
  Priority: 0
  Weight: 5

5) TLS / WSS for Eagler (browser clients)
- If you serve Eaglercraft browser clients and want WebSocket Secure (wss://), add TLS termination (Caddy or nginx) to accept connections on 443 and proxy to your proxy server's websocket endpoint. I can add a Caddy service to docker-compose that will automatically obtain Let's Encrypt certs.

6) Security & operational tips
- Keep online-mode enabled in your backend (Paper) server if using Mojang auth (protects against username impersonation). If you rely on custom auth (EaglerAuth), tune accordingly.
- Use LuckPerms to manage admin permissions rather than granting OP to raw usernames.
- Back up world data frequently and test restores.
- Consider rate-limiting and monitoring (fail2ban, port knocking) if you become public-facing.

If you want me to implement any of the following automatically in the repo, say which:
- Add Caddy (Let's Encrypt) to docker-compose for TLS and WSS termination.
- Add an automated ufw/iptables helper (requires interactive sudo on the host).
- Create a small README with example DNS SRV entries for PhoenixSMP.
- Add a healthcheck & monitoring container (Prometheus or simple cron check).

