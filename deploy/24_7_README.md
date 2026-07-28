# Running 24/7

This document explains how to run the Stasis Minecraft stack 24/7 on a Linux host. The repository includes helper artifacts to make the stack resilient and start on boot.

What I changed
- Added restart policies and log rotation to deploy/docker-compose.yml for both the backend and proxy services.
- Added deploy/install_service.sh which installs a systemd unit (stasis-mc.service) that brings the docker-compose stack up at boot and stops it on shutdown.

Prerequisites on the host
- Docker and Docker Compose (plugin) installed. On many systems docker compose is available at /usr/bin/docker compose. If you are using the legacy docker-compose binary, adjust the script and service to use /usr/bin/docker-compose instead.
- sudo/root access to install the systemd unit.
- (Optional) If you want automated image updates, enable Watchtower in the compose file (commented out) and review security implications.

Install the systemd service (recommended)
1. SSH into your host and cd to the repository directory.
2. Run (as root):
   sudo ./deploy/install_service.sh

This will create /etc/systemd/system/stasis-mc.service, enable it, and start the stack.

Verify
- Check service status:
  sudo systemctl status stasis-mc.service
- Check docker containers:
  docker ps
- Tail logs:
  docker logs mc_proxy -f
  docker logs mc_backend -f

Notes & tips
- Restart policy: 'unless-stopped' means containers will always restart unless explicitly stopped. Combined with the systemd unit the stack will come back after host reboots.
- Log rotation: json-file options limit log file growth (10MB per file, 5 files). Adjust to your needs.
- Backups: make periodic backups of deploy/backend/data (server world) — this is not automatic.
- Security: restrict host firewall to necessary ports (25565, optional admin ports) and protect Docker daemon access.

If you want, I can also:
- Add a cron or containerized backup job to snapshot world data regularly.
- Add an in-repo example Watchtower configuration to enable automatic image updates (not recommended for production without testing).
- Add monitoring (Prometheus + Grafana) or simple healthchecks and alerts.
