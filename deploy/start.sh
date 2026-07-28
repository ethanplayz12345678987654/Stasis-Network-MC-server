#!/usr/bin/env bash
# Helper script to fetch Velocity, EaglerXServer, and optional backend plugins
# (EssentialsX, Vault, LuckPerms, WorldEdit, WorldGuard) and start the docker-compose stack.
# Behavior:
# - By default, fetches the latest release for PaperMC/Velocity, lax1dude/eaglerxserver, EssentialsX/Essentials,
#   MilkBowl/Vault, lucko/LuckPerms, EngineHub/WorldEdit, EngineHub/WorldGuard via the GitHub releases API where available.
# - You can pin to a tag by setting VELOCITY_TAG, EAGLER_TAG, ESSENTIALS_TAG, VAULT_TAG, LUCKPERMS_TAG,
#   WORLDEDIT_TAG, and/or WORLDGUARD_TAG environment variables.
# - You can bypass the API and provide direct URLs by setting VELOCITY_URL, EAGLER_URL, ESSENTIALS_URL, VAULT_URL,
#   LUCKPERMS_URL, WORLDEDIT_URL, and/or WORLDGUARD_URL environment variables.
# - If GITHUB_TOKEN is set in the environment, it will be used to increase GitHub API rate limits.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROXY_DIR="$ROOT_DIR/proxy"
PROXY_PLUGINS_DIR="$PROXY_DIR/plugins"
BACKEND_DATA_DIR="$ROOT_DIR/deploy/backend/data"
BACKEND_PLUGINS_DIR="$BACKEND_DATA_DIR/plugins"
mkdir -p "$PROXY_PLUGINS_DIR"
mkdir -p "$BACKEND_PLUGINS_DIR"

# Default repos
VELOCITY_REPO="PaperMC/Velocity"
EAGLER_REPO="lax1dude/eaglerxserver"
ESSENTIALS_REPO="EssentialsX/Essentials"
VAULT_REPO="MilkBowl/Vault"
LUCK_REPO="lucko/LuckPerms"
WE_REPO="EngineHub/WorldEdit"
WG_REPO="EngineHub/WorldGuard"

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
  python3 - <<PYTHON
import sys, json, re
js = json.loads(sys.stdin.read())
pat = re.compile(sys.argv[1], re.IGNORECASE)

def check_rel(rel):
    for a in rel.get('assets', []):
        name = a.get('name','')
        url = a.get('browser_download_url','')
        if name and url and pat.search(name):
            print(url)
            return True
    return False

if isinstance(js, list):
    for rel in js:
        if check_rel(rel):
            sys.exit(0)
else:
    if check_rel(js):
        sys.exit(0)
sys.exit(1)
PYTHON
}

get_release_json() {
  local repo="$1"; local tag="$2"
  if [ -n "$tag" ]; then
    github_api_get "https://api.github.com/repos/$repo/releases/tags/$tag"
  else
    github_api_get "https://api.github.com/repos/$repo/releases/latest"
  fi
}

resolve_release_asset() {
  local repo="$1"; local tag="$2"; local prefer_pattern="$3"; local fallback_pattern="$4"; local envvar_name="$5"
  if [ -n "${!envvar_name:-}" ]; then
    printf "%s" "${!envvar_name}"
    return 0
  fi
  rel_json=$(get_release_json "$repo" "$tag")
  url=$(printf "%s" "$rel_json" | find_asset_url_from_release_json "$prefer_pattern") || true
  if [ -z "$url" ]; then
    url=$(printf "%s" "$rel_json" | find_asset_url_from_release_json "$fallback_pattern") || true
  fi
  printf "%s" "$url"
}

# Resolve URLs (Velocity and Eagler are required)
RESOLVED_VELOCITY_URL=$(resolve_release_asset "$VELOCITY_REPO" "${VELOCITY_TAG:-}" ".*velocity.*\\.jar$" ".*\\.jar$" VELOCITY_URL)
RESOLVED_EAGLER_URL=$(resolve_release_asset "$EAGLER_REPO" "${EAGLER_TAG:-}" ".*eagler.*\\.jar$" ".*\\.jar$" EAGLER_URL)
RESOLVED_ESSENTIALS_URL=$(resolve_release_asset "$ESSENTIALS_REPO" "${ESSENTIALS_TAG:-}" ".*Essentials.*\\.jar$" ".*\\.jar$" ESSENTIALS_URL) || true
RESOLVED_VAULT_URL=$(resolve_release_asset "$VAULT_REPO" "${VAULT_TAG:-}" ".*Vault.*\\.jar$" ".*\\.jar$" VAULT_URL) || true
RESOLVED_LUCK_URL=$(resolve_release_asset "$LUCK_REPO" "${LUCKPERMS_TAG:-}" ".*luckperms.*\\.jar$" ".*\\.jar$" LUCKPERMS_URL) || true
RESOLVED_WE_URL=$(resolve_release_asset "$WE_REPO" "${WORLDEDIT_TAG:-}" ".*worldedit.*\\.jar$" ".*\\.jar$" WORLDEDIT_URL) || true
RESOLVED_WG_URL=$(resolve_release_asset "$WG_REPO" "${WORLDGUARD_TAG:-}" ".*worldguard.*\\.jar$" ".*\\.jar$" WORLDGUARD_URL) || true

if [ -z "${RESOLVED_VELOCITY_URL:-}" ] || [ -z "${RESOLVED_EAGLER_URL:-}" ]; then
  echo "ERROR: Could not resolve Velocity or EaglerXServer release URL. Set VELOCITY_URL/EAGLER_URL or tags to override." >&2
  exit 1
fi

echo "Resolved URLs:" >&2
echo " - Velocity: $RESOLVED_VELOCITY_URL" >&2
echo " - EaglerXServer: $RESOLVED_EAGLER_URL" >&2
if [ -n "${RESOLVED_ESSENTIALS_URL:-}" ]; then echo " - EssentialsX: $RESOLVED_ESSENTIALS_URL" >&2; fi
if [ -n "${RESOLVED_VAULT_URL:-}" ]; then echo " - Vault: $RESOLVED_VAULT_URL" >&2; fi
if [ -n "${RESOLVED_LUCK_URL:-}" ]; then echo " - LuckPerms: $RESOLVED_LUCK_URL" >&2; fi
if [ -n "${RESOLVED_WE_URL:-}" ]; then echo " - WorldEdit: $RESOLVED_WE_URL" >&2; fi
if [ -n "${RESOLVED_WG_URL:-}" ]; then echo " - WorldGuard: $RESOLVED_WG_URL" >&2; fi

# Download helper
download_if_needed() {
  local url="$1"; local dest="$2"
  if [ -f "$dest" ]; then
    remote_size=$(curl -sI "$url" | awk '/Content-Length/ {print $2}' | tr -d '\r') || true
    local_size=$(wc -c <"$dest" 2>/dev/null || true)
    if [ -n "$remote_size" ] && [ "$remote_size" = "$local_size" ]; then
      echo "Skipping download, existing file matches size: $dest"
      return 0
    fi
  fi
  echo "Downloading $url -> $dest"
  curl -L -o "$dest" "$url"
}

# Download Velocity and Eagler
download_if_needed "$RESOLVED_VELOCITY_URL" "$PROXY_DIR/server.jar"
download_if_needed "$RESOLVED_EAGLER_URL" "$PROXY_PLUGINS_DIR/EaglerXServer.jar"

# Download optional backend plugins
if [ -n "${RESOLVED_ESSENTIALS_URL:-}" ]; then
  download_if_needed "$RESOLVED_ESSENTIALS_URL" "$BACKEND_PLUGINS_DIR/EssentialsX.jar"
fi
if [ -n "${RESOLVED_VAULT_URL:-}" ]; then
  download_if_needed "$RESOLVED_VAULT_URL" "$BACKEND_PLUGINS_DIR/Vault.jar"
fi
if [ -n "${RESOLVED_LUCK_URL:-}" ]; then
  download_if_needed "$RESOLVED_LUCK_URL" "$BACKEND_PLUGINS_DIR/LuckPerms.jar"
fi
if [ -n "${RESOLVED_WE_URL:-}" ]; then
  download_if_needed "$RESOLVED_WE_URL" "$BACKEND_PLUGINS_DIR/WorldEdit.jar"
fi
if [ -n "${RESOLVED_WG_URL:-}" ]; then
  download_if_needed "$RESOLVED_WG_URL" "$BACKEND_PLUGINS_DIR/WorldGuard.jar"
fi

# Start docker-compose
if [ ! -f "$ROOT_DIR/deploy/docker-compose.yml" ]; then
  echo "docker-compose file not found at $ROOT_DIR/deploy/docker-compose.yml" >&2
  exit 1
fi

echo "Starting docker-compose stack..."
docker compose -f "$ROOT_DIR/deploy/docker-compose.yml" up -d

echo "Stack started. Proxy listening on host port 25565. Backend container: mc_backend."
