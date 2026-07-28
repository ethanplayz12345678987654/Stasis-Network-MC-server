#!/usr/bin/env bash
# Helper script to fetch jars (Velocity + EaglerX) and start the docker-compose stack.
# NOTE: Replace VELOCITY_URL and EAGLER_URL with exact download URLs for chosen releases.

set -euo pipefail

PROXY_DIR="$(pwd)/deploy/proxy"
mkdir -p "$PROXY_DIR/plugins"

# Example placeholders - replace these with actual release download URLs
VELOCITY_URL="https://github.com/PaperMC/Velocity/releases/download/your-version/velocity.jar"
EAGLER_URL="https://github.com/lax1dude/eaglerxserver/releases/download/your-version/EaglerXServer.jar"

if [ "$VELOCITY_URL" = "https://github.com/PaperMC/Velocity/releases/download/your-version/velocity.jar" ]; then
  echo "Please edit start.sh and set VELOCITY_URL and EAGLER_URL to real release download URLs before running. Exiting."
  exit 1
fi

# Download velocity server jar if not present
if [ ! -f "$PROXY_DIR/server.jar" ]; then
  echo "Downloading Velocity server jar..."
  curl -L -o "$PROXY_DIR/server.jar" "$VELOCITY_URL"
fi

# Download EaglerXServer plugin jar if not present
if [ ! -f "$PROXY_DIR/plugins/EaglerXServer.jar" ]; then
  echo "Downloading EaglerXServer plugin jar..."
  curl -L -o "$PROXY_DIR/plugins/EaglerXServer.jar" "$EAGLER_URL"
fi

# Start docker-compose
echo "Starting stack..."
docker compose -f deploy/docker-compose.yml up -d

echo "Done. Proxy should be listening on host port 25565. Minecraft backend is on an internal network (container name: mc_backend)."
