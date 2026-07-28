#!/usr/bin/env bash
set -euo pipefail

# install_service.sh
# Installs a systemd unit that ensures the docker-compose stack is started on boot
# Usage: sudo ./deploy/install_service.sh

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/deploy/docker-compose.yml"
SERVICE_PATH="/etc/systemd/system/stasis-mc.service"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "docker-compose file not found at $COMPOSE_FILE"
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (sudo). Re-run with sudo."
  exit 1
fi

cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Stasis Minecraft Stack (docker-compose)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$ROOT_DIR/deploy
ExecStart=/usr/bin/docker compose -f $COMPOSE_FILE up -d
ExecStop=/usr/bin/docker compose -f $COMPOSE_FILE down
TimeoutStartSec=0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now stasis-mc.service

echo "stasis-mc.service installed and started. Use 'systemctl status stasis-mc.service' to check status."
