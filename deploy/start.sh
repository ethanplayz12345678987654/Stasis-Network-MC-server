#!/usr/bin/env bash
# Helper script to fetch Velocity and EaglerXServer jars (latest or tagged) and start the docker-compose stack.
# Behavior:
# - By default, fetches the latest release for PaperMC/Velocity and lax1dude/eaglerxserver via the GitHub releases API.
# - You can pin to a tag by setting VELOCITY_TAG and/or EAGLER_TAG environment variables.
# - You can bypass the API and provide direct URLs by setting VELOCITY_URL and/or EAGLER_URL environment variables.
# - If GITHUB_TOKEN is set in the environment, it will be used to increase GitHub API rate limits.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROXY_DIR="$ROOT_DIR/proxy"
PLUGINS_DIR="$PROXY_DIR/plugins"
mkdir -p "$PLUGINS_DIR"

# Default repos
VELOCITY_REPO="PaperMC/Velocity"
EAGLER_REPO="lax1dude/eaglerxserver"

# Optional: user can set these env vars before running to pin versions or provide direct URLs
# VELOCITY_TAG - a release tag (e.g., "proxy-1.1.0") to fetch instead of latest
# EAGLER_TAG - a release tag for eaglerxserver
# VELOCITY_URL - direct download URL for Velocity jar to use (skips API)
# EAGLER_URL - direct download URL for EaglerXServer jar to use (skips API)
# GITHUB_TOKEN - optional GitHub token to raise API rate limits

# Utility: call GitHub API, optionally using token
github_api_get() {
  local url="$1"
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -sS -H "Authorization: token $GITHUB_TOKEN" "$url"
  else
    curl -sS "$url"
  fi
}

# Utility: find asset download url for a repo release JSON using python for robust JSON parsing
find_asset_url_from_release_json() {
  local json="$1"
  local pattern="$2"
  python3 - <<PYTHON
import sys, json, re
js = json.loads(sys.stdin.read())
assets = js.get('assets', [])
pat = re.compile(r"%s" % sys.argv[1], re.IGNORECASE)
for a in assets:
    name = a.get('name','')
    url = a.get('browser_download_url','')
    if name and url and pat.search(name):
        print(url)
        sys.exit(0)
# fallback: try tag_name jar
if isinstance(js, list):
    # if multiple releases were returned for some reason, check each
    for rel in js:
        for a in rel.get('assets',[]):
            name = a.get('name','')
            url = a.get('browser_download_url','')
            if name and url and pat.search(name):
                print(url)
                sys.exit(0)
sys.exit(1)
PYTHON
}

# Get release JSON (latest or tagged)
get_release_json() {
  local repo="$1"
  local tag="$2" # can be empty to use latest
  if [ -n "$tag" ]; then
    github_api_get "https://api.github.com/repos/$repo/releases/tags/$tag"
  else
    github_api_get "https://api.github.com/repos/$repo/releases/latest"
  fi
}

# Resolve Velocity URL
if [ -n "${VELOCITY_URL:-}" ]; then
  RESOLVED_VELOCITY_URL="$VELOCITY_URL"
else
  echo "Resolving latest Velocity release for $VELOCITY_REPO..."
  rel_json=$(get_release_json "$VELOCITY_REPO" "${VELOCITY_TAG:-}")
  RESOLVED_VELOCITY_URL=$(printf "%s" "$rel_json" | find_asset_url_from_release_json ".*velocity.*\\.jar$") || true
  if [ -z "$RESOLVED_VELOCITY_URL" ]; then
    # Fallback: pick any .jar asset
    RESOLVED_VELOCITY_URL=$(printf "%s" "$rel_json" | find_asset_url_from_release_json ".*\\.jar$") || true
  fi
fi

# Resolve EaglerXServer URL
if [ -n "${EAGLER_URL:-}" ]; then
  RESOLVED_EAGLER_URL="$EAGLER_URL"
else
  echo "Resolving latest EaglerXServer release for $EAGLER_REPO..."
  rel_json=$(get_release_json "$EAGLER_REPO" "${EAGLER_TAG:-}")
  # Prefer an asset that looks like EaglerXServer or eagler
  RESOLVED_EAGLER_URL=$(printf "%s" "$rel_json" | find_asset_url_from_release_json ".*eagler.*\\.jar$") || true
  if [ -z "$RESOLVED_EAGLER_URL" ]; then
    RESOLVED_EAGLER_URL=$(printf "%s" "$rel_json" | find_asset_url_from_release_json ".*\\.jar$") || true
  fi
fi

# Guard: ensure we found URLs
if [ -z "${RESOLVED_VELOCITY_URL:-}" ]; then
  echo "ERROR: Could not resolve a Velocity release download URL."
  echo "You can set VELOCITY_URL or VELOCITY_TAG environment variables to override."
  exit 1
fi

if [ -z "${RESOLVED_EAGLER_URL:-}" ]; then
  echo "ERROR: Could not resolve an EaglerXServer release download URL."
  echo "You can set EAGLER_URL or EAGLER_TAG environment variables to override."
  exit 1
fi

echo "Velocity jar: $RESOLVED_VELOCITY_URL"
echo "EaglerXServer jar: $RESOLVED_EAGLER_URL"

# Download velocity server jar if not present or if URL changed
SERVER_JAR_PATH="$PROXY_DIR/server.jar"
if [ -f "$SERVER_JAR_PATH" ]; then
  echo "Existing $SERVER_JAR_PATH found. Verifying checksum against remote (best-effort)..."
  # We'll fetch remote headers to get content-length and compare size as a cheap check
  remote_size=$(curl -sI "$RESOLVED_VELOCITY_URL" | awk '/Content-Length/ {print $2}' | tr -d '\r') || true
  local_size=$(wc -c <"$SERVER_JAR_PATH" 2>/dev/null || true)
  if [ -n "$remote_size" ] && [ "$remote_size" = "$local_size" ]; then
    echo "Local Velocity jar matches remote size; skipping download."
  else
    echo "Downloading Velocity jar to $SERVER_JAR_PATH..."
    curl -L -o "$SERVER_JAR_PATH" "$RESOLVED_VELOCITY_URL"
  fi
else
  echo "Downloading Velocity jar to $SERVER_JAR_PATH..."
  curl -L -o "$SERVER_JAR_PATH" "$RESOLVED_VELOCITY_URL"
fi

# Download EaglerXServer plugin jar
EAGLER_JAR_PATH="$PLUGINS_DIR/EaglerXServer.jar"
if [ -f "$EAGLER_JAR_PATH" ]; then
  echo "Existing $EAGLER_JAR_PATH found. Verifying size..."
  remote_size=$(curl -sI "$RESOLVED_EAGLER_URL" | awk '/Content-Length/ {print $2}' | tr -d '\r') || true
  local_size=$(wc -c <"$EAGLER_JAR_PATH" 2>/dev/null || true)
  if [ -n "$remote_size" ] && [ "$remote_size" = "$local_size" ]; then
    echo "Local EaglerXServer plugin matches remote size; skipping download."
  else
    echo "Downloading EaglerXServer plugin to $EAGLER_JAR_PATH..."
    curl -L -o "$EAGLER_JAR_PATH" "$RESOLVED_EAGLER_URL"
  fi
else
  echo "Downloading EaglerXServer plugin to $EAGLER_JAR_PATH..."
  curl -L -o "$EAGLER_JAR_PATH" "$RESOLVED_EAGLER_URL"
fi

# Make sure docker compose file exists
if [ ! -f "$ROOT_DIR/docker-compose.yml" ] && [ ! -f "$ROOT_DIR/deploy/docker-compose.yml" ]; then
  echo "docker-compose.yml not found in repository. Expected at deploy/docker-compose.yml."
  exit 1
fi

# Start docker-compose
echo "Starting stack..."
# Use the deploy compose file
docker compose -f "$ROOT_DIR/deploy/docker-compose.yml" up -d

echo "Done. Proxy should be listening on host port 25565. Minecraft backend is on an internal network (container name: mc_backend)."
