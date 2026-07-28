# Eaglercraft + Minecraft 1.21 — Setup instructions

This repository provides a template to run an Eaglercraft-compatible proxy (Velocity) in front of a Paper 1.21 backend using docker-compose.

Step-by-step setup

1) Clone this repository (or you're already inside it):
   git clone https://github.com/ethanplayz12345678987654/Stasis-Network-MC-server.git
   cd Stasis-Network-MC-server

2) Edit deploy/start.sh and set the real download URLs for the Velocity server jar and the EaglerXServer jar. Example places to get these jars:
   - Velocity releases: https://github.com/PaperMC/Velocity/releases
   - EaglerXServer releases: https://github.com/lax1dude/eaglerxserver/releases

   Replace the placeholder values in start.sh:
   - VELOCITY_URL
   - EAGLER_URL

3) Make the helper script executable and run it (it will download jars and start the stack):
   chmod +x deploy/start.sh
   ./deploy/start.sh

   If you prefer to manually place jars instead of using start.sh, do:
   - Place Velocity jar at ./deploy/proxy/server.jar
   - Place EaglerXServer.jar at ./deploy/proxy/plugins/EaglerXServer.jar

4) Configuration notes:
   - Proxy config: ./deploy/proxy/velocity.toml — ensure the bind address and backend server entry match your network and desired ports.
   - EaglerX plugin config: ./deploy/proxy/plugins/eaglerx.yml — verify inject_address matches the proxy listener (0.0.0.0:25565 in the example) and default_server matches the name in velocity.toml.
   - Backend server files (Paper) will be stored in ./deploy/backend/data.

5) Connect via Eaglercraft browser client:
   - Point your Eaglercraft client to the host IP (or domain) and port 25565 by default. The proxy will accept WebSocket connections from Eaglercraft and forward translated Minecraft traffic to the Paper backend.

Troubleshooting & tips

- Check logs:
  - Proxy logs: docker logs mc_proxy -f
  - Backend logs: docker logs mc_backend -f

- If Velocity won't start because of an incompatible plugin, remove the plugin from ./deploy/proxy/plugins and restart the proxy.

- For production: pin Velocity and EaglerXServer to pinned release versions, enable backups for backend data, and consider running behind a reverse proxy or firewall.

Security

- Always keep server software up-to-date and run with minimal privileges.
- Use a firewall to restrict access to admin ports and the container host.

If you want, I can:
- Make the proxy service download the exact latest release automatically (I can attempt to fetch the latest release artifact URLs from GitHub and use them in start.sh).
- Switch the proxy template to BungeeCord if you'd rather use that instead of Velocity.
